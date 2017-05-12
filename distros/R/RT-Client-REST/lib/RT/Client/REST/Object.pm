package RT::Client::REST::Object;

=head1 NAME

RT::Client::REST::Object -- base class for RT objects.

=head1 SYNOPSIS

  # Create a new type
  package RT::Client::REST::MyType;

  use base qw(RT::Client::REST::Object);

  sub _attributes {{
    myattribute => {
      validation => {
        type => SCALAR,
      },
    },
  }}

  sub rt_type { "mytype" }

  1;

=head1 DESCRIPTION

The RT::Client::REST::Object module is a superclass providing a whole
bunch of class and object methods in order to streamline the development
of RT's REST client interface.

=head1 ATTRIBUTES

Attributes are defined by method C<_attributes> that should be defined
in your class.  This method returns a reference to a hash whose keys are
the attributes.  The values of the hash are attribute settings, which are
as follows:

=over 2

=item list

If set to true, this is a list attribute.  See
L</LIST ATTRIBUTE PROPERTIES> below.

=item validation

A hash reference.  This is passed to validation routines when associated
mutator is called.  See L<Params::Validate> for reference.

=item rest_name

This specifies this attribute's REST name.  For example, attribute
"final_priority" corresponds to RT REST's "FinalPriority".  This option
may be omitted if the two only differ in first letter capitalization.

=item form2value

Convert form value (one that comes from the server) into attribute-digestible
format.

=item value2form

Convert value into REST form format.

=back

Example:

  sub _attributes {{
    id  => {
        validation  => {
            type    => SCALAR,
            regex   => qr/^\d+$/,
        },
        form2value  => sub {
            shift =~ m~^ticket/(\d+)$~i;
            return $1;
        },
        value2form  => sub {
            return 'ticket/' . shift;
        },
    },
    admin_cc        => {
        validation  => {
            type    => ARRAYREF,
        },
        list        => 1,
        rest_name   => 'AdminCc',
    },
  }}

=head1 LIST ATTRIBUTE PROPERTIES

List attributes have the following properties:

=over 2

=item *

When called as accessors, return a list of items

=item *

When called as mutators, only accept an array reference

=item *

Convenience methods "add_attr" and "delete_attr" are available.  For
example:

  # Get the list
  my @requestors = $ticket->requestors;

  # Replace with a new list
  $ticket->requestors( [qw(dude@localhost)] );

  # Add some random guys to the current list
  $ticket->add_requestors('randomguy@localhost', 'evil@local');

=back

=head1 SPECIAL ATTRIBUTES

B<id> and B<parent_id> are special attributes.  They are used by
various DB-related methods and are especially relied upon by
B<autostore>, B<autosync>, and B<autoget> features.

=head1 METHODS

=over 2

=cut

use strict;
use warnings;

use vars qw($VERSION);
$VERSION = '0.09';

use Error qw(:try);
use Params::Validate;
use RT::Client::REST::Object::Exception 0.04;
use RT::Client::REST::SearchResult 0.02;
use DateTime;
use DateTime::Format::DateParse;

=item new

Constructor

=cut

sub new {
    my $class = shift;

    if (@_ & 1) {
        RT::Client::REST::Object::OddNumberOfArgumentsException->throw;
    }

    my $self = bless {}, ref($class) || $class;
    my %opts = @_;

    my $id = delete($opts{id});
    if (defined($id)) {{
        $self->id($id);
        if ($self->can('parent_id')) {
            # If object can parent_id, we assume that it's needed for
            # retrieval.
            my $parent_id = delete($opts{parent_id});
            if (defined($parent_id)) {
                $self->parent_id($parent_id);
            } else {
                last;
            }
        }
        if ($self->autoget) {
            $self->retrieve;
        }
    }}

    while (my ($k, $v) = each(%opts)) {
        $self->$k($v);
    }

    return $self;
}

=item _generate_methods

This class method generates accessors and mutators based on
B<_attributes> method which your class should provide.  For items
that are lists, 'add_' and 'delete_' methods are created.  For instance,
the following two attributes specified in B<_attributes> will generate
methods 'creator', 'cc', 'add_cc', and 'delete_cc':

  creator => {
    validation => { type => SCALAR },
  },
  cc => {
    list => 1,
    validation => { type => ARRAYREF },
  },

=cut

sub _generate_methods {
    my $class = shift;
    my $attributes = $class->_attributes;

    while (my ($method, $settings) = each(%$attributes)) {
        no strict 'refs';

        *{$class . '::' . $method} = sub {
            my $self = shift;

            if (@_) {
                my $caller = defined((caller(1))[3]) ? (caller(1))[3] : '';

                if ($settings->{validation} &&
                    # Don't validate values from the server
                    $caller ne __PACKAGE__  . '::from_form')
                {
                    my @v = @_;
                    Params::Validate::validation_options(
                        on_fail => sub {
                            no warnings 'uninitialized';
                            RT::Client::REST::Object::InvalidValueException
                            ->throw(
                            "'@v' is not a valid value for attribute '$method'"
                            );
                        },
                    );
                    validate_pos(@_, $settings->{validation});
                }

                $self->{'_' . $method} = shift;
                $self->_mark_dirty($method);

                # Let's try to autosync, shall we?  Logic is a bit hairy
                # in order to make it efficient.
                if ($self->autosync && $self->can('store') &&
                    # OK, so id is special.  This is so that 'new' would
                    # work.
                    'id' ne $method &&
                    'parent_id' ne $method &&

                    # Plus we don't want to store right after retrieving
                    # (that's where from_form is called from).
                    $caller ne __PACKAGE__  . '::from_form')
                {
                    $self->store;
                }
            }

            if ($settings->{list}) {
                my $retval = $self->{'_' . $method} || [];
                return @$retval;
            } else {
                return $self->{'_' . $method};
            }
        };

        if ($settings->{is_datetime}) {
            *{$class. '::' . $method . "_datetime"} = sub {
                # All dates are in UTC
                # http://requesttracker.wikia.com/wiki/REST#Data_format

                my ($self) = shift;
                my $real_method = $class.'::'.$method;
                if (@_) {
                    unless ($_[0]->isa('DateTime')) {
                            RT::Client::REST::Object::InvalidValueException
                                ->throw(
                                "'$_[0]' is not a valid value for attribute '${method}_datetime'"
                            );

                    }
                    my $z = $_[0]->clone;
                    $z->set_time_zone("UTC");
                    $self->$method($_[0]->strftime("%a %b %d %T %Y"));
                    return $z;
                }

                return DateTime::Format::DateParse->parse_datetime($self->$method, 'UTC');

            };
        }

        if ($settings->{list}) {
            # Generate convenience methods for list manipulation.
            my $add_method = $class . '::add_' . $method;
            my $delete_method = $class . '::delete_' . $method;

            *$add_method = sub {
                my $self = shift;

                unless (@_) {
                    RT::Client::REST::Object::NoValuesProvidedException
                        ->throw;
                }

                my @values = $self->$method;
                my %values = map { $_, 1 } @values;

                # Now add new values
                for (@_) {
                    $values{$_} = 1;
                }

                $self->$method([keys %values]);
            };

            *$delete_method = sub {
                my $self = shift;

                unless (@_) {
                    RT::Client::REST::Object::NoValuesProvidedException
                        ->throw;
                }

                my @values = $self->$method;
                my %values = map { $_, 1 } @values;

                # Now delete values
                for (@_) {
                    delete $values{$_};
                }

                $self->$method([keys %values]);
            };
        }
    }
}

=item _mark_dirty($attrname)

Mark an attribute as dirty.

=cut

sub _mark_dirty {
    my ($self, $attr) = @_;
    $self->{__dirty}{$attr} = 1;
}

=item _dirty

Return the list of dirty attributes.

=cut

sub _dirty {
    my $self = shift;

    if (exists($self->{__dirty})) {
        return keys %{$self->{__dirty}};
    }

    return;
}

=item _mark_dirty_cf($attrname)

Mark an custom flag as dirty.

=cut

sub _mark_dirty_cf {
    my ($self, $cf) = @_;
    $self->{__dirty_cf}{$cf} = 1;
}

=item _dirty_cf

Return the list of dirty custom flags.

=cut

sub _dirty_cf {
    my $self = shift;

    if (exists($self->{__dirty_cf})) {
        return keys %{$self->{__dirty_cf}};
    }

    return;
}

=item to_form($all)

Convert the object to 'form' (used by REST protocol). This is done based on
B<_attributes> method. If C<$all> is true, create a form from all of the
object's attributes and custom flags, otherwise use only dirty (see B<_dirty>
method) attributes and custom flags. Defaults to the latter.

=cut

sub to_form {
    my ($self, $all) = @_;
    my $attributes = $self->_attributes;

    my @attrs = ($all ? keys(%$attributes) : $self->_dirty);

    my %hash;

    for my $attr (@attrs) {
        my $rest_name = (exists($attributes->{$attr}{rest_name}) ?
                         $attributes->{$attr}{rest_name} : ucfirst($attr));

        my $value;
        if (exists($attributes->{$attr}{value2form})) {
            $value = $attributes->{$attr}{value2form}($self->$attr);
        } elsif ($attributes->{$attr}{list}) {
            $value = join(',', $self->$attr);
        } else {
            $value = (defined($self->$attr) ? $self->$attr : 'Not set');
        }

        $hash{$rest_name} = $value;
    }
    my @cfs = ($all ? $self->cf : $self->_dirty_cf);
    for my $cf (@cfs) {
        $hash{'CF-' . $cf} = $self->cf($cf);
    }

    return \%hash;
}

=item from_form

Set object's attributes from form received from RT server.

=cut

sub from_form {
    my $self = shift;
    
    unless (@_) {
        RT::Client::REST::Object::NoValuesProvidedException->throw;
    }

    my $hash = shift;

    unless ('HASH' eq ref($hash)) {
        RT::Client::REST::Object::InvalidValueException->throw(
            "Expecting a hash reference as argument to 'from_form'",
        );
    }

    # lowercase hash keys
    my $i = 0;
    $hash = { map { ($i++ & 1) ? $_ : lc } %$hash };

    my $attributes = $self->_attributes;
    my %rest2attr;  # Mapping of REST names to our attributes;
    while (my ($attr, $value) = each(%$attributes)) {
        my $rest_name = (exists($attributes->{$attr}{rest_name}) ?
                         lc($attributes->{$attr}{rest_name}) : $attr);
        $rest2attr{$rest_name} = $attr;
    }

    # Now set attributes:
    while (my ($key, $value) = each(%$hash)) {
        # Handle custom fields, ideally /(?(1)})/ would be appened to RE
	if( $key =~ m%^(?:cf|customfield)(?:-|\.\{)([#\s\w_:()?/-]+)% ){
	    $key = $1;

            # XXX very sketchy. Will fail on long form data e.g; wiki CF
            if ($value =~ /,/) {
                $value = [ split(/\s*,\s*/, $value) ];
            }

            $self->cf($key, $value);
            next;
        }

        unless (exists($rest2attr{$key})) {
            warn "Unknown key: $key\n";
            next;
        }

        if ($value =~ m/not set/i) {
            $value = undef;
        }

        my $method = $rest2attr{$key};
        if (exists($attributes->{$method}{form2value})) {
            $value = $attributes->{$method}{form2value}($value);
        } elsif ($attributes->{$method}{list}) {
            $value = [split(/\s*,\s*/, $value)],
        }
        $self->$method($value);
    }

    return;
}

sub retrieve {
    my $self = shift;

    $self->_assert_rt_and_id;

    my $rt = $self->rt;

    my ($hash) = $rt->show(type => $self->rt_type, id => $self->id);
    $self->from_form($hash);

    $self->{__dirty} = {};
    $self->{__dirty_cf} = {};

    return $self;
}

sub store {
    my $self = shift;

    $self->_assert_rt;

    my $rt = $self->rt;

    if (defined($self->id)) {
        $rt->edit(
            type    => $self->rt_type,
            id      => $self->id,
            set     => $self->to_form,
        );
    } else {
        my $id = $rt->create(
            type    => $self->rt_type,
            set     => $self->to_form,
            @_,
        );
        $self->id($id);
    }

    $self->{__dirty} = {};

    return $self;
}

sub search {
    my $self = shift;

    if (@_ & 1) {
        RT::Client::REST::Object::OddNumberOfArgumentsException->throw;
    }

    $self->_assert_rt;

    my %opts = @_;

    my $limits = delete($opts{limits}) || [];
    my $query = '';

    for my $limit (@$limits) {
        my $kw;
        try {
            $kw = $self->_attr2keyword($limit->{attribute});
        } catch RT::Clite::REST::Object::InvalidAttributeException with {
            RT::Client::REST::Object::InvalidSearchParametersException
                ->throw(shift->message);
        };
        my $op = $limit->{operator};
        my $val = $limit->{value};
        my $agg = $limit->{aggregator} || 'and';

        if (length($query)) {
            $query = "($query) $agg $kw $op '$val'";
        } else {
            $query = "$kw $op '$val'";
        }
    }

    my $orderby;
    try {
        # Defaults to 'id' at the moment.  Do not rely on this --
        # implementation may change!
        $orderby = (delete($opts{reverseorder}) ? '-' : '+') .
            ($self->_attr2keyword(delete($opts{orderby}) || 'id'));
    } catch RT::Clite::REST::Object::InvalidAttributeException with {
        RT::Client::REST::Object::InvalidSearchParametersException->throw(
            shift->message,
        );
    };

    my $rt = $self->rt;
    my @results;
    try {
        @results = $rt->search(
            type => $self->rt_type,
            query => $query,
            orderby => $orderby,
        );
    } catch RT::Client::REST::InvalidQueryException with {
        RT::Client::REST::Object::InvalidSearchParametersException->throw;
    };

    return RT::Client::REST::SearchResult->new(
        ids => \@results,
        object => sub { $self->new(id => shift, rt => $rt) },
    );
}

sub count {
    my $self = shift;
    $self->_assert_rt;
    return $self->search(@_)->count;
}

sub _attr2keyword {
    my ($self, $attr) = @_;
    my $attributes = $self->_attributes;

    unless (exists($attributes->{$attr})) {
        no warnings 'uninitialized';
        RT::Clite::REST::Object::InvalidAttributeException->throw(
            "Attribute '$attr' does not exist in object type '" .
                ref($self) . "'"
        );
    }

    return (exists($attributes->{$attr}{rest_name}) ?
            $attributes->{$attr}{rest_name} :
            ucfirst($attr));
}

sub _assert_rt_and_id {
    my $self = shift;
    my $method = shift || (caller(1))[3];

    unless (defined($self->rt)) {
        RT::Client::REST::Object::RequiredAttributeUnsetException
            ->throw("Cannot '$method': 'rt' attribute of the object ".
                    "is not set");
    }

    unless (defined($self->id)) {
        RT::Client::REST::Object::RequiredAttributeUnsetException
            ->throw("Cannot '$method': 'id' attribute of the object ".
                    "is not set");
    }
}

sub _assert_rt {
    my $self = shift;
    my $method = shift || (caller(1))[3];

    unless (defined($self->rt)) {
        RT::Client::REST::Object::RequiredAttributeUnsetException
            ->throw("Cannot '$method': 'rt' attribute of the object ".
                    "is not set");
    }
}

=item param($name, $value)

Set an arbitrary parameter.

=cut

sub param {
    my $self = shift;

    unless (@_) {
        RT::Client::REST::Object::NoValuesProvidedException->throw;
    }

    my $name = shift;

    if (@_) {
        $self->{__param}{$name} = shift;
    }

    return $self->{__param}{$name};
}

=item cf([$name, [$value]])

Given no arguments, returns the list of custom field names.  With
one argument, returns the value of custom field C<$name>.  With two
arguments, sets custom field C<$name> to C<$value>.  Given a reference
to a hash, uses it as a list of custom fields and their values, returning
the new list of all custom field names.

=cut

sub cf {
    my $self = shift;

    unless (@_) {
        # Return a list of CFs.
        return keys %{$self->{__cf}};
    }

    my $name = shift;
    if ('HASH' eq ref($name)) {
        while (my ($k, $v) = each(%$name)) {
            $self->{__cf}{lc($k)} = $v;
            $self->_mark_dirty_cf($k);
        }
        return keys %{$self->{__cf}};
    } else {
        $name = lc $name;
        if (@_) {
            $self->{__cf}{$name} = shift;
            $self->_mark_dirty_cf($name);
        }
        return $self->{__cf}{$name};
    }
}

=item rt

Get or set the 'rt' object, which should be of type L<RT::Client::REST>.

=cut

sub rt {
    my $self = shift;

    if (@_) {
        my $rt = shift;
        unless (UNIVERSAL::isa($rt, 'RT::Client::REST')) {
            RT::Client::REST::Object::InvalidValueException->throw;
        }
        $self->{__rt} = $rt;
    }

    return $self->{__rt};
}

=back

=head1 DB METHODS

The following are methods that have to do with reading, creating, updating,
and searching objects.

=over 2

=item count

Takes the same arguments as C<search()> but returns the actual count of
the found items.  Throws the same exceptions.

=item retrieve

Retrieve object's attributes.  Note that 'id' attribute must be set for this
to work.

=item search (%opts)

This method is used for searching objects.  It returns an object of type
L<RT::Client::REST::SearchResult>, which can then be used to process
results.  C<%opts> is a list of key-value pairs, which are as follows:

=over 2

=item limits

This is a reference to array containing hash references with limits to
apply to the search (think SQL limits).

=item orderby

Specifies attribute to sort the result by (in ascending order).

=item reverseorder

If set to a true value, sorts by attribute specified by B<orderby> in
descending order.

=back

If the client cannot construct the query from the specified arguments,
or if the server cannot make it out,
C<RT::Client::REST::Object::InvalidSearchParametersException> is thrown.

=item store

Store the object.  If 'id' is set, this is an update; otherwise, a new
object is created and the 'id' attribute is set.  Note that only changed
(dirty) attributes are sent to the server.

=back

=head1 CLASS METHODS

=over 2

=item use_single_rt

This method takes a single argument -- L<RT::Client::REST> object
and makes this class use it for all instantiations.  For example:

  my $rt = RT::Client::REST->new(%args);

  # Make all tickets use this RT:
  RT::Client::REST::Ticket->use_single_rt($rt);

  # Now make all objects use it:
  RT::Client::REST::Object->use_single_rt($rt);

=cut

sub use_single_rt {
    my ($class, $rt) = @_;

    unless (UNIVERSAL::isa($rt, 'RT::Client::REST')) {
        RT::Client::REST::Object::InvalidValueException->throw;
    }

    no strict 'refs';
    no warnings 'redefine';
    *{(ref($class) || $class) . '::rt'} = sub { $rt };
}

=item use_autostore

Turn autostoring on and off.  Autostoring means that you do not have
to explicitly call C<store()> on an object - it will be called when
the object goes out of scope.

  # Autostore tickets:
  RT::Client::REST::Ticket->use_autostore(1);
  my $ticket = RT::Client::REST::Ticket->new(%opts)->retrieve;
  $ticket->priority(10);
  # Don't have to call store().

=cut

sub autostore {}

sub use_autostore {
    my ($class, $autostore) = @_;
    
    no strict 'refs';
    no warnings 'redefine';
    *{(ref($class) || $class) . '::autostore'} = sub { $autostore };
}

sub DESTROY {
    my $self = shift;

    $self->autostore && $self->can('store') && $self->store;
}

=item use_autoget

Turn autoget feature on or off (off by default).  When set to on,
C<retrieve()> will be automatically called from the constructor if
it is called with that object's special attributes (see
L</SPECIAL ATTRIBUTES> above).

  RT::Client::Ticket->use_autoget(1);
  my $ticket = RT::Client::Ticket->new(id => 1);
  # Now all attributes are available:
  my $subject = $ticket->subject;

=cut

sub autoget {}

sub use_autoget {
    my ($class, $autoget) = @_;
    
    no strict 'refs';
    no warnings 'redefine';
    *{(ref($class) || $class) . '::autoget'} = sub { $autoget };
}

=item use_autosync

Turn autosync feature on or off (off by default).  When set, every time
an attribute is changed, C<store()> method is invoked.  This may be pretty
expensive.

=cut

sub autosync {}

sub use_autosync {
    my ($class, $autosync) = @_;

    no strict 'refs';
    no warnings 'redefine';
    *{(ref($class) || $class) . '::autosync'} = sub { $autosync };
}

=item be_transparent

This turns on B<autosync> and B<autoget>.  Transparency is a neat idea,
but it may be expensive and slow.  Depending on your circumstances, you
may want a finer control of your objects.  Transparency makes
C<retrieve()> and C<store()> calls invisible:

  RT::Client::REST::Ticket->be_transparent($rt);

  my $ticket = RT::Client::REST::Ticket->new(id => $id); # retrieved
  $ticket->add_cc('you@localhost.localdomain'); # stored
  $ticket->status('stalled'); # stored
  
  # etc.

Do not forget to pass RT::Client::REST object to this method.

=cut

sub be_transparent {
    my ($class, $rt) = @_;
    $class->use_autosync(1);
    $class->use_autoget(1);
    $class->use_single_rt($rt);
}

=back

=head1 SEE ALSO

L<RT::Client::REST::Ticket>,
L<RT::Client::REST::SearchResult>.

=head1 AUTHOR

Dmitri Tikhonov <dtikhonov@yahoo.com>

=cut

1;
