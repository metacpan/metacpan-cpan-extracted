package Net::Whois::Object;
use strict;
use warnings;

use Carp;
use IPC::Open2 qw/open2/;
use List::Util qw/max/;
use Data::Dumper;

our $LWP;

BEGIN {
    $LWP = do {
        eval { require LWP::UserAgent; };
        ($@) ? 0 : 1;
    };
}

=head1 NAME

Net::Whois::Object - Object encapsulating RPSL data returned by Whois queries

=head1 SYNOPSIS

    use Net::Whois::RIPE;
    use Net::Whois::Object;

    my @objects = Net::Whois::Object->query('AS30781');


    # Or you can use the previous way

    my $whois = Net::Whois::RIPE->new( %options );
    $iterator = $whois->query('AS30781');

    push @objects, Net::Whois::Object->new($iterator);

    for my $object (@objects) {
        # process Net::Whois::Object::xxx objects... 
        # Type of object is available via class() method
    }

=head1 USAGE

=head2 Get the data

    # Get the Class we want to modify
    my $whois = Net::Whois::RIPE->new( %options );
    $iterator = $whois->query('POLK-RIPE');

=head2 Filter objects

Before you had to filter objects using the class() method.

    # Then to only get the Person object (and ignore Information objects)
    my ($person) = grep {$_->class() eq 'Person'} Net::Whois::Object->new($iterator);

But now the query() method allows you to filter more easily

    my ($person) = Net::Whois::Object->query('POLK-RIPE', { type => 'person' });

You can even use the query() filtering capabilities a little further

    my @emails = Net::Whois::Object->query('POLK-RIPE', { type => 'person', attribute => 'e_mail' });

Please note, that as soon as you use the attribute filter, the values returned
are strings and no more Net::Whois::Objects.

=head2 Modify the data

    # Add a phone number
    $person->phone(' +33 4 88 00 65 15');

Some attributes can have multiple values (remarks, mnt-by...) first implementation allowed only to
add one value

    # Add one maintener
    $person->mnt_by('CPNY-MNT');
    
New implementation (post 2.00020) allow to do:

    $person->mnt_by({mode => 'append', value => 'CPNY-MNT'});

Which is a verbose way to do exactly as the default mode above, but also

    # Append multiple values at once
    $person->mnt_by({mode => 'append', value => ['CPNY-MNT2','CPNY-MNT3']});

Or even

    # Replace CPNY-MNT2 by REPL-MNT
    $person->mnt_by({mode => 'replace', value => {old => 'CPNY-MNT2', new => 'REPL-MNT'}});

From release 2.002 you can also use the 'delete' mode to remove a specific attribute value

    $person->mnt_by({mode => 'delete', value => {old => 'REPL-MNT'}});
    
    # Or if you want to remove all remarks (the regex '.' meaning any char, will match all remarks values)
    $person->remarks({mode => 'delete', value => {old => '.'}});


=head2 Dump the current state of the data

The dump() method, enable to print the object under the classic
text form, made of 'attribute:  value' lines.

    # Dump the modified data
    my $to_be_mailed = $person->dump();

dump() handle the 'align' parameter passed though a hash ref.

    my $to_be_mailed = $person->dump( { align => 15 });

=head2 Update the RIPE database

The RIPE database update is currently under heavy development.

B<*The update code is still to be considered as experimental.*>

We plan to offer several ways to update the RIPE database

=head3 Update through the web interface

RIPE provides several web interfaces

=head4 SyncUpdates (*Experimental*)

Although not the latest one, this simple interface is the first to be wrapped
by this module.

B<CAUTION: SyncUpdates features require LWP::UserAgent to be installed.>

=head4 Create

Once the object has been modified, locally, you can create it in the database
calling the syncupdates_create() method.

The parameters are passed through a hash ref, and can be the maintener
authentication credentials ('password' or 'pgpkey') and the 'align' parameter

    $object->person('John Doe');
    ...
    my $primary_key = $object->syncupdates_create( { password => $password } );
    # or
    my $primary_key = $object->syncupdates_create( { pgpkey   => $keyID, align => 8 } );

The pgp key must be an eight digit hexadecimal key ID known to the local
C<gpg> executable.

If the C<pgpkey> key is present in the hash reference passed to
syncupdates_create, you can also pass in the C<pgpexec> key to chose a program
to execute for signing (C<gpg> by default), and C<pgpopts>, which must be an
array reference of additional options to pass to the signing binary.

The primary key of the object created is returned.
The attribute used as primary key can be obtained through 
C<$object->attribute('primary')>

=head4 Update

An object existing in the RIPE database, can be retrieved, modified locally
and then updated through the syncupdates_update() method.

Parameters are passed through a hash ref, and can be the maintener
authentication credentials ('password' or 'pgpkey') and the 'align' parameter
See L</Create> for more information on the authentication methods.

    $object->person('John Doe');
    ...
    $object->syncupdates_update( { password => $password } );

=head4 Delete

An object existing in the RIPE database, can be retrieved, and deleted in
the databased through the syncupdates_delete() method.
Parameters are passed through a hash ref, and can be the maintener
authentication credentials ('password' or 'pgpkey') and the 'reason' parameter
See L</Create> for more information on the authentication methods.

    $object->syncupdates_delete( { pgpkey => $keyID } );

An additional parameter can be used as a reason for the deletion.

    $object->syncupdates_delete( { pgpkey => $keyID, reason =>  'Obsoleted by XXX' } );

If no reason is provided, a default one ('Not needed anymore') is used.
    
=head3 Update through email.

Not implemented yet.

=head1 SUBROUTINES/METHODS

=head2 B<new( @lines|$iterator )>

The constructor is a factory returning the appropriate Net::Whois::Objects
based on the first attribute of the block.
You can pass an array of lines or an iterator returned by Net::Whois::RIPE
as argument.

The two following ways of using the constructor are possible

    my $whois = Net::Whois::RIPE->new( %options );
    $iterator = $whois->query('AS30781');

    # Using the iterator way
    push @objects, Net::Whois::Object->new($iterator);

or

    # Using the previous (more circonvoluted) @lines way

    while ( ! $iterator->is_exhausted() ) {
        my @lines = map { "$_\n"} split '\n',  $iterator->value();
        push @objects, Net::Whois::Object->new(@lines,"\n");
    }

=cut

sub new {
    my ( $class, @lines ) = @_;

    # If an iterator is passed as argument convert it to lines.
    if ( ref $lines[0] eq 'Iterator' ) {
        my $iterator = shift @lines;
        while ( !$iterator->is_exhausted() ) {
            push @lines, map {"$_\n"} split '\n', $iterator->value();
            push @lines, $/;
        }
    }

    my ( $attribute, $block, $object, @results, $value );

    for my $line (@lines) {

        if ( $line =~ /^%(\S+)/ ) {

            $block = 'response' unless $block;

            # Response line
            $attribute = 'response';
            $value     = $1;

        } elsif ( $line =~ /^(\S+):\s+(.*)/ ) {

            # Attribute line
            $attribute = $1;
            $value     = $2;

        } elsif ( $line =~ /^%\s+(.*)/ ) {

            $block = 'comment' unless $block;

            # Comment line
            $attribute = 'comment';
            $value     = $1;

        } elsif ( $line =~ /^[^%]\s*(.+)/ ) {

            # Continuation line
            $value = $1;

        } elsif ( $line =~ /^$/ ) {

            # Blank line
            if ($object) {
                $object = _object_factory( $object->{block}, $object->{value}, $object );
                push @results, $object;
                $attribute = undef;
                $block     = undef;
                $object    = undef;
            }
            next;

        }

        # Normalize attribute to Perl's sub name standards
        $attribute =~ s/-/_/g if $attribute;

        # First attribute determine the block
        $block = $attribute unless $block;

        if ( !$object ) {
            $object = { block => $block, value => $value, attributes => [] };

            # $object = _object_factory( $block, $value ) unless $object;
            # } elsif ( $object->can($attribute) ) {
            # $object->$attribute($value);
            if ( $block eq 'comment' ) {

                # push @{$object->{attributes}},[ 'comment', $value ];
                next;
            }
        }

        # } else {
        push @{ $object->{attributes} }, [ $attribute, $value ];

        # } else {
        # warn "Objects of type " . ref($object) . " do not support attribute '$attribute', but it was supplied with value '$value'\n";
        # }

    }

    # TODO: fix the trailing undef
    return grep {defined} @results;
}

=head2 B<clone( [\%options] )>

Return a clone from a Net::Whois::RIPE object

Current allowed option is remove => [attribute1, ..., attributen] where the specified
attribute AREN'T copied to the clone object (for example to ignore the 'changed' values)

=cut

sub clone {
    my ( $self, $rh_options ) = @_;

    my $clone;
    my %filtered;

    for my $option ( keys %$rh_options ) {
        if ( $option =~ /remove/i ) {
            for my $att ( @{ $rh_options->{$option} } ) {
                $filtered{ lc $att } = 1;
            }
        } else {
            croak "Unknown option $option used while cloning a ", ref $self;
        }
    }

    my @lines;
    my @tofilter = split /\n/, $self->dump;

    for my $line (@tofilter) {
        if ( $line =~ /^(.+?):/ and $filtered{ lc $1 } ) {
            next;
        }
        push @lines, $line;

    }

    eval { ($clone) = Net::Whois::Object->new( @lines, $/ ); };
    croak $@ if $@;

    return $clone;
}

=head2 B<attributes( [$type [, \@attributes]] )>

Accessor to the attributes of the object. 
C<$type> can be 

    'primary'   Primary/Lookup key
    'mandatory' Required for update creation
    'optional' Optionnal for update/creation
    'multiple'  Can have multiple values
    'single'    Have only one value
    'all'       You can't specify attributes for this special type
                which provides all the attributes which have a type

If no C<$type> is specified, 'all' is assumed.
Returns a list of attributes of the required type.

=cut

sub attributes {
    my ( $self, $type, $ra_attributes ) = @_;
    if ( not defined $type or $type =~ /all/i ) {
        return ( $self->attributes('mandatory'), $self->attributes('optional') );
    }
    croak "Invalid attribute's type ($type)" unless $type =~ m/(all|primary|mandatory|optional|single|multiple)/i;
    if ($ra_attributes) {
        for my $a ( @{$ra_attributes} ) {
            $self->_TYPE()->{$type}{$a} = 1;
        }
    }
    if ( $type eq 'single' || $type eq 'multiple' ) {
        my $symbol_table = do {
            no strict 'refs';
            \%{ $self . '::' };
        };

        for my $a ( @{$ra_attributes} ) {
            unless ( exists $symbol_table->{$a} ) {
                my $accessor = $type eq 'single' ? sub { _single_attribute_setget( $_[0], $a, $_[1] ) } : sub { _multiple_attribute_setget( $_[0], $a, $_[1] ) };
                no strict 'refs';
                *{"${self}::$a"} = $accessor;
            }
        }
    }
    return sort keys %{ $self->_TYPE()->{$type} };
}

=head2 B<class ( )>

This method return the RIPE class associated to the current object.

=cut

sub class {
    my ( $self, $value ) = @_;

    return $self->_single_attribute_setget( 'class', $value );
}

=head2 B<attribute_is ( $attribute, $type )>

This method return true if C<$attribute> is of type C<$type>

=cut

sub attribute_is {
    my ( $self, $attribute, $type ) = @_;

    return defined $self->_TYPE()->{$type}{$attribute} ? 1 : 0;
}

=head2 B<hidden_attributes( $attribute )>

Accessor to the filtered_attributes attribute (attributes to be hidden)
Accepts an optional attribute to be added to the filtered_attributes array,
always return the current filtered_attributes array.

=cut

sub filtered_attributes {
    my ( $self, $filtered_attributes ) = @_;
    push @{ $self->{filtered_attributes} }, $filtered_attributes if defined $filtered_attributes;
    return @{ $self->{filtered_attributes} };
}

=head2 B<displayed_attributes( $attribute )>

Accessor to the displayed_attributes attribute which should be displayed.
Accepts an optional attribute to be added to the displayed_attributes array,
always return the current displayed_attributes array.

=cut

sub displayed_attributes {
    my ( $self, $displayed_attributes ) = @_;
    push @{ $self->{displayed_attributes} }, $displayed_attributes if defined $displayed_attributes;
    return @{ $self->{displayed_attributes} };
}

=head2 B<dump( [\%options] )>

Simple naive way to display a text form of the class.
Try to be as close as possible as the submited text.

Currently the only option available is 'align' which accept a C<$column> number as
parameter so that all C<< $self->dump >> produces values that are aligned
vertically on column C<$column>.

=cut

sub dump {
    my ( $self, $options ) = @_;

    my %current_index;
    my $result;
    my $align_to;

    for my $opt ( keys %$options ) {
        if ( $opt =~ /^align$/i ) {
            $align_to = $options->{$opt};

        } else {

            croak "Unknown option $opt for dump()";
        }
    }

    $align_to ||= 5 + max map length, $self->attributes('all');

    for my $line ( @{ $self->{order} } ) {
        my $attribute = $line;
        $attribute =~ s/_/-/g;

        my $val = $self->$line();

        if ( ref $val eq 'ARRAY' ) {

            # If multi value get the lines in order
            $val = $val->[ $current_index{$line}++ ];
        }

        $val = '' unless $val;

        my $alignment = ' ' x ( $align_to - length($attribute) - 1 );
        my $output = "$attribute:$alignment$val\n";

        # Process the comment
        $output =~ s/comment:\s*/\% /;

        $result .= $output;
    }

    return $result;
}

=head2 B<syncupdates_update([\%options] )>

Update the RIPE database through the web syncupdates interface.
Use the password passed as parameter to authenticate.

=cut

sub syncupdates_update {
    my ( $self, $options ) = @_;

    my $dump_options;

    for my $opt ( keys %$options ) {
        if ( $opt =~ /^align$/i ) {
            $dump_options = { align => $options->{$opt} };
        }
    }

    my ($key) = $self->attributes('primary');
    my $value = $self->_single_attribute_setget($key);

    my $html = $self->_syncupdates_submit( $self->dump($dump_options), $options );

    if ( $html =~ /Modify SUCCEEDED:.*$value/m ) {
        return $value;
    } else {
        croak "Update not confirmed ($html)";
    }
}

=head2 B<syncupdates_delete( \%options )>

Delete the object in the RIPE database through the web syncupdates interface.
Use the password passed as parameter to authenticate.
The optional parmeter reason is used to explain why the object is deleted.

=cut

sub syncupdates_delete {
    my ( $self, $options ) = @_;

    my ($key) = $self->attributes('primary');
    my $value = $self->_single_attribute_setget($key);

    my $text = $self->dump();
    $options->{reason} = 'Not needed anymore' unless $options->{reason};
    $text .= "delete: " . $options->{reason} . "\n";

    my $html = $self->_syncupdates_submit( $text, $options );

    if ( $html =~ /Delete SUCCEEDED:.*$value/m ) {
        return $value;
    } else {
        croak "Deletion not confirmed ($html)";
    }
}

=head2 B<syncupdates_create( \%options )>

Create an object in the the RIPE database through the web syncupdates interface.
See L</Create> for more information on the authentication methods.

The available options are 'pgpkey', 'password' and 'align'

Return the primary key of the object created.

=cut

sub syncupdates_create {
    my ( $self, $options ) = @_;

    my $dump_options;

    for my $opt ( keys %$options ) {
        if ( $opt =~ /^align$/i ) {
            $dump_options = { align => $options->{$opt} };
        }
    }

    my $res = $self->_syncupdates_submit( $self->dump($dump_options), $options );

    if (    $res =~ /^Number of objects processed with errors:\s+(\d+)/m
         && $1 == 0
         && (    $res =~ /\*\*\*Info:\s+Authorisation for\s+\[[^\]]+]\s+(.+)\s*$/m
              || $res =~ /(?:Create SUCCEEDED|No operation): \[[^\]]+\]\s+(\S+)/m )
        )
    {
        my $value = $1;
        my ($key) = $self->attributes('primary');

        # some primary keys can contain spaces, in which case $value
        # is not correct. So only use it for objects where the primary
        # key can be generated by the RIPE DB, and where it never contains
        # spaces. According to
        # http://www.ripe.net/ripe/mail/archives/db-help/2013-January/000411.html
        # this is the case for person, organization, role and key-cert
        my %obj_types_with_autogen_key = ( KeyCert      => 1,
                                           Organisation => 1,
                                           Person       => 1,
                                           Role         => 1,
        );
        if ( $self->class && $obj_types_with_autogen_key{ $self->class } ) {
            $self->_single_attribute_setget( $key, $value );
            return $value;
        } else {
            return $self->$key();
        }
    } else {
        croak "Error while creating object through syncupdates API: $res";
    }
}

=head2 B<query( $query, [\%options] )>

This method is deprecated since release 2.005 of Net::Whois::RIPE

Please use Net::Whois::Generic->query() instead.

=cut

sub query {

    croak "This method is deprecated since release 2.005 of Net::Whois::RIPE\nPlease use Net::Whois::Generic->query() instead\n";

}

=begin UNDOCUMENTED

=head2 B<_object_factory( $type => $value, $attributes_hashref )>

Private method. Shouldn't be used from other modules.

Simple factory, creating Net::Whois::Objet::XXXX from
the type passed as parameter.

=cut

sub _object_factory {
    my $type   = shift;
    my $value  = shift;
    my $object = shift;
    my $rir;

    my $object_returned;

    my %class = ( as_block     => 'AsBlock',
                  as_set       => 'AsSet',
                  aut_num      => 'AutNum',
                  comment      => 'Information',
                  domain       => 'Domain',
                  filter_set   => 'FilterSet',
                  inet6num     => 'Inet6Num',
                  inetnum      => 'InetNum',
                  inet_rtr     => 'InetRtr',
                  irt          => 'Irt',
                  key_cert     => 'KeyCert',
                  limerick     => 'Limerick',
                  mntner       => 'Mntner',
                  organisation => 'Organisation',
                  peering_set  => 'PeeringSet',
                  person       => 'Person',
                  poem         => 'Poem',
                  poetic_form  => 'PoeticForm',
                  response     => 'Response',
                  role         => 'Role',
                  route6       => 'Route6',
                  route        => 'Route',
                  route_set    => 'RouteSet',
                  rtr_set      => 'RtrSet',
    );

    die "Unrecognized Object (first attribute: $type = $value)\n" . Dumper($object) unless defined $type and $class{$type};

    my $class = "Net::Whois::Object::" . $class{$type};

    for my $a ( @{ $object->{attributes} } ) {
        if ( $a->[0] =~ /source/ ) {
            $rir = $a->[1];
            $rir =~ s/^(\S+)\s*#.*/$1/;
            $rir = uc $rir;
            $rir = undef if $rir =~ /^(RIPE|TEST)$/;    # For historical/compatibility reason RIPE objects aren't derived
        }
    }

    $class .= "::$rir" if $rir;

    eval "require $class" or die "Can't require $class ($!)";

    # my $object = $class->new( $type => $value );
    $object_returned = $class->new( class => $class{$type} );

    # First attribute is always single valued, except for comments
    if ( $type eq 'comment' ) {
        $object_returned->_multiple_attribute_setget( $type => $value );
    } else {
        $object_returned->_single_attribute_setget( $type => $value );
    }

    if ( $object->{attributes} ) {
        for my $a ( @{ $object->{attributes} } ) {
            my $method = $a->[0];
            $object_returned->$method( $a->[1] );
        }
    }

    # return $class->new( $type => $value );
    return $object_returned;

}

=head2 B<_single_attribute_setget( $attribute )>

Generic setter/getter for singlevalue attribute.

=cut

sub _single_attribute_setget {
    my ( $self, $attribute, $value ) = @_;
    my $mode = 'replace';

    if ( ref $value eq 'HASH' ) {
        my %options = %$value;

        if ( $options{mode} ) {
            $mode = $options{mode};
        }

        if ( $options{value} ) {
            $value = $options{value};
        } else {
            croak "Unable to determine attribute $attribute value";
        }

    }

    if ( defined $value ) {

        if ( $mode eq 'replace' ) {

            # Store attribute order for dump, unless this attribute as already been set
            push @{ $self->{order} }, $attribute unless $self->{$attribute} or $attribute eq 'class';

            $self->{$attribute} = $value;
        } elsif ( $mode eq 'delete' ) {
            if ( ref $value ne 'HASH' or !$value->{old} ) {
                croak " {old=>...} expected as value for $attribute update in delete mode";
            } else {
                $self->_delete_attribute( $attribute, $value->{old} );
            }
        }
    }
    return $self->{$attribute};
}

=head2 B<_multiple_attribute_setget( $attribute )>

Generic setter/getter for multivalue attribute.

=cut

sub _multiple_attribute_setget {
    my ( $self, $attribute, $value ) = @_;
    my $mode = 'append';

    if ( ref $value eq 'HASH' ) {
        my %options = %$value;

        if ( $options{mode} ) {
            $mode = $options{mode};
        }

        if ( $options{value} ) {
            $value = $options{value};
        } else {
            croak "Unable to determine attribute $attribute value";
        }

    }

    if ( defined $value ) {

        if ( $mode eq 'append' ) {
            if ( ref $value eq 'ARRAY' ) {
                push @{ $self->{$attribute} }, @$value;
                push @{ $self->{order} }, map {$attribute} @$value;
            } elsif ( !ref $value ) {
                push @{ $self->{$attribute} }, $value;
                push @{ $self->{order} }, $attribute;
            } else {
                croak "Trying to append weird data to $attribute: ", $value;
            }
        } elsif ( $mode eq 'replace' ) {
            if ( ref $value ne 'HASH' or !$value->{old} or !$value->{new} ) {
                croak " {old=>..., new=>} expected as value for $attribute update in replace mode";
            } else {
                my $old = $value->{old};
                for ( @{ $self->{$attribute} } ) {
                    $_ = $value->{new} if $_ =~ /$old/;
                }
            }
        } elsif ( $mode eq 'delete' ) {
            if ( ref $value ne 'HASH' or !$value->{old} ) {
                croak " {old=>...} expected as value for $attribute update in delete mode";
            } else {

                # $self->{$attribute} = [grep {!/$old/} @{$self->{$attribute}}];
                $self->_delete_attribute( $attribute, $value->{old} );
            }
        } else {
            croak "Unknown mode $mode for attribute $attribute";
        }
    }

    croak "$attribute $self" unless ref $self;
    return $self->{$attribute};
}

=head2 B<_delete_attribute( $attribute, $pattern )>

Delete an attribute if its value match the pattern value 

=cut

sub _delete_attribute {
    my ( $self, $attribute, $pattern ) = @_;

    my @lines;

    for my $a ( @{ $self->{order} } ) {
        my $val = ref $self->{$a} ? shift @{ $self->{$a} } : $self->{$a};
        push @lines, [ $a, $val ];
    }

    @lines = grep { $attribute ne $_->[0] or $_->[1] !~ /$pattern/ } @lines;
    delete $self->{$attribute} if $self->attribute_is( $attribute, 'single' ) and $self->{$attribute} =~ /$pattern/;

    $self->{order} = [];
    for my $l (@lines) {
        $self->{ $l->[0] } = [] if ref( $self->{ $l->[0] } );
    }

    for my $i ( 0 .. $#lines ) {
        push @{ $self->{order} }, $lines[$i]->[0];
        if ( $self->attribute_is( $lines[$i]->[0], 'multiple' ) ) {
            push @{ $self->{ $lines[$i]->[0] } }, $lines[$i]->[1];
        } else {
            $self->{ $lines[$i]->[0] } = $lines[$i]->[1];

        }

    }

}

=head2 B<_init( @options )>

Initialize self with C<@options>

=cut

sub _init {
    my ( $self, @options ) = @_;

    while ( my ( $key, $val ) = splice( @options, 0, 2 ) ) {
        $self->$key($val);
    }
}

=head2 B<_syncupdates_submit( $text, \%options )>

Interact with the RIPE database through the web syncupdates interface.
Submit the text passed as parameter.
Use the password passed as parameter to authenticate.
The database used is chosen based on the 'source' attribute.

Return the HTML code of the returned page.
(This will change in a near future)

=cut

sub _syncupdates_submit {
    my ( $self, $text, $options ) = @_;

    if ( exists $options->{pgpkey} ) {
        $text = $self->_pgp_sign( $text, $options );
    } elsif ( exists $options->{password} ) {
        my $password = $options->{password};
        chomp $password;
        croak("Passwords containing newlines are not supported")
            if $password =~ /\n/;
        $text .= "password: $password\n";
    }

    croak "LWP::UserAgent required for updates" unless $LWP;

    my $url = $self->source eq 'RIPE' ? 'http://syncupdates.db.ripe.net/' : 'http://syncupdates-test.db.ripe.net';

    my $ua = LWP::UserAgent->new;

    my $response = $ua->post( $url, { DATA => $text } );
    my $response_text = $response->decoded_content;

    unless ( $response->is_success ) {
        croak "Can't sync object with RIPE database: $response_text";
    }

    return $response_text;
}

=head2 B<_pgp_sign( $text, $auth )>

Sign the C<$text> with the C<gpg> command and gpg information in C<$auth>
Returns the signed text.

=cut

sub _pgp_sign {
    my ( $self, $text, $auth ) = @_;

    my $binary = $auth->{pgpexec} || 'gpg';
    my $key_id = $auth->{pgpkey};
    my @opts   = @{ $auth->{pgpopts} || [] };

    $key_id =~ s/^0x//;
    my $pid = open2( my $child_out, my $child_in, $binary, "--local-user=$key_id", '--clearsign', @opts );
    print {$child_in} $text;
    close $child_in;

    $text = do { local $/; <$child_out> };
    close $child_out;

    waitpid( $pid, 0 );
    my $child_exit_status = $? >> 8;
    if ( $child_exit_status != 0 ) {
        croak "Error while launching $binary for signing the message: child process exited with status $child_exit_status";
    }

    return $text;
}

=head2 B<_TYPE>

Returns a hash ref that contains the attribute data for the class
of the object that the method was called on.

=end UNDOCUMENTED

=cut

my %TYPES;

sub _TYPE {
    $TYPES{ ref $_[0] || $_[0] } ||= {};
}

=head1 SEE ALSO

Please take a look at L<Net::Whois::Generic> the more generic whois client built on top of Net::Whois::RIPE.

=head1 TODO

The update part (in RIPE database) still needs a lot of work.

Enhance testing without network

Enhance test coverage

=head1 AUTHOR

Arnaud "Arhuman" Assad, C<< <arhuman at gmail.com> >>

=head1 ACKNOWLEDGEMENTS

Thanks to Jaguar Network for allowing me to work on this during some of my office
hours.

Thanks to Luis Motta Campos for his trust when allowing me to publish this
release.

Thanks to Moritz Lenz for all his contributions
(Thanks also to 'Noris Network AG', his employer, for allowing him to contribute in the office hours)

=cut

1;
