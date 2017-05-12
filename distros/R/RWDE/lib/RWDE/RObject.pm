package RWDE::RObject;

use strict;
use warnings;

use Data::Validate::Domain qw(is_domain);
use Mail::RFC822::Address qw(valid);

use RWDE::Exceptions;

use base qw(RWDE::Logging);

use vars qw($AUTOLOAD);
use vars qw($VERSION);
$VERSION = sprintf "%d", q$Revision: 528 $ =~ /(\d+)/;

our (%_validators);

=pod

=head1 RWDE::RObject

Base class for various records
All derived classes must be hashes and correspond to a standard derived class format

=cut

BEGIN {

  #all of the default data validators that we use
  %_validators = (

    # Field => [Type, Callback, Descr]
    IP      => [ 'IP',      'validate_ip',      'validate an ip address' ],
    email   => [ 'email',   'validate_email',   'validate an email address' ],
    boolean => [ 'boolean', 'validate_boolean', 'validate a boolean string' ],
  );
}

=head2 new()

=cut

sub new() {
  my ($proto, $params) = @_;

  my $class = ref($proto) || $proto;

  my $self = { _data => {}, };

  bless($self, $class);

  no strict 'refs';
  $self->{_modifiable_fields}     = \%{ $class . "::modifiable_fields" };
  $self->{_modifiable_fieldnames} = \@{ $class . "::modifiable_fieldnames" };
  $self->{_static_fields}         = \%{ $class . "::static_fields" };
  $self->{_static_fieldnames}     = \@{ $class . "::static_fieldnames" };
  $self->{_fieldnames}            = \@{ $class . "::fieldnames" };
  $self->{_fields}                = \%{ $class . "::fields" };
  $self->{_id}                    = ${ $class . "::id" };

  $self->initialize($params);

  return $self;
}

=head2 is_instance()

Determine if this reference instance of a class

=cut

sub is_instance {
  my ($self, $params) = @_;

  return ref($self) ? 1 : 0;
}

=head2 check_object()

Verify that this reference is an object.

DevelException is thrown if this is not an object instantiation.

=cut

sub check_object {
  my ($self, $params) = @_;

  my $info = $$params{info} || "$self is not an instance.";

  if (not $self->is_instance()) {
    my ($package, $filename, $line, $subroutine, $hasargs, $wantarray, $evaltext, $is_require, $hints, $bitmask) = caller(1);
    throw RWDE::DevelException({ info => $info . "Called from $subroutine at $package, line: $line" });
  }

  return ();
}

=head2 field_desc($fn)

Get the field description stored within the object for the param $fn.

=cut

sub field_desc {
  my $self = shift;
  my $fn   = shift;

  return (exists $self->{_fields}->{$fn} ? $self->{_fields}->{$fn}[1] : $fn);
}

=head2 field_type($fn)

Get the field type stored within the object for the param $fn.

=cut

sub field_type {
  my $self = shift;
  my $fn   = shift;

  return $self->{_fields}->{$fn}[0];
}

=head2 FIELDNAME

All field names of the record are accessible via the field name.  If a
second parameter is provided, that value is stored as the data,
otherwise the existing value if any is returned.  Throws an 'undef'
exception on error.  It is intended to be called by an F<AUTOLOAD()>
method from the subclass.

Example:

  $rec->owner_email('new\@add.ress');
  $rec->user_addr2(undef);
  print $rec->user_fname();

  Would be converted by F<AUTOLOAD()> in the subclass to calls like

  $rec->FIELDNAME('owner_email','new@add.ress');

 and so forth.

=cut

sub FIELDNAME {
  my $self           = shift;
  my $fn             = shift;
  my $supplied_value = $_[0];

  $self->check_object({ info => "No method by name: $fn could be located. FIELDNAME tried to find the attribute  by $fn - but the call was on $self, not an instance." });

  $fn =~ s/.*://;    # strip fully-qualified portion

  unless (exists $self->{_fields}->{$fn}) {
    my ($package, $filename, $line, $subroutine, $hasargs, $wantarray, $evaltext, $is_require, $hints, $bitmask) = caller(1);
    throw RWDE::DevelException({ info => "Unknown field name '$fn' in class $self, for $package on line: $line." });
  }

  my $type = $self->field_type($fn);    #note the type

  if (not defined $type) {
    throw RWDE::DevelException({ info => "Type for $self -> $fn not defined" });
  }

  if ( defined $supplied_value
    && defined $self->{_data}->{$fn}
    && $type           eq 'timestamp'
    && $supplied_value eq 'date') {
    return substr($self->{_data}->{$fn}, 0, 10);
  }

  #if you are trying to set data, have a name and the data...
  if (defined($supplied_value)) {

    #check to see if the field is modifiable
    if (!(exists $self->{_modifiable_fields}->{$fn})) {
      throw RWDE::DevelException({ info => "Field name '$fn' in class $self is not allowed to be modified." });
    }

    #check to make sure the data is valid to be entered
    if (exists $_validators{$type}) {
      my $callback = $_validators{$type}[1];
      $self->$callback($supplied_value);
    }

    #set the data
    $self->{_data}->{$fn} = $supplied_value;
  }

  return $self->{_data}->{$fn};
}

=head2 validate_email()

Check the syntactical format of an email address to reduce risk of
bogus addresses. 

RWDE::DevelException thrown if invalid format detected, otherwise
just returns

Ensures that the address is in somewhat reasonable domain style, does
not contain blanks, commas, brackets, colons, semicolons, or end in a
period.

=cut

sub validate_email {
  my ($self, $addr) = @_;

  if (length($addr) > 100) {
    throw RWDE::DataBadException({ info => 'Email address is too long.  We only allow 100 characters.' });
  }

  my ($email, $domain) = split /@/, $addr, 2;

  throw RWDE::DataBadException(
    {
      info =>
        'Unfortunately, we are having problems recording your entries and setting up your account. Please check that the email address you entered is in the standard format of "me@example.com" and that it doesn\'t contain any spaces, commas, parentheses, brackets, colons, double quotes, or semicolons and try again.'
    }
  ) unless is_domain($domain);

  throw RWDE::DataBadException(
    {
      info =>
        'Unfortunately, we are having problems recording your entries and setting up your account. Please check that the email address you entered is in the standard format of "me@example.com" and that it doesn\'t contain any spaces, commas, parentheses, brackets, colons, double quotes, or semicolons and try again.'
    }
  ) unless valid($addr);

  return ();
}

=head2 validate_ip()

Check the syntactical format of an ip address to reduce risk of
storing a bogus or faked ip. 

RWDE::DevelException thrown if invalid format detected, otherwise
just returns

Ensures that the address is the standard aaa.bbb.ccc.ddd ip address format

=cut

sub validate_ip {
  my ($self, $ip) = @_;

  my @values = split /\./, $ip;

  my $validity = 0;
  foreach my $value (@values) {
    if (($value > 0) && ($value < 256)) {
      $validity++;
    }
  }

  if ($validity != 4) {
    throw RWDE::DevelException({ info => 'Invalid format for IP address (aaa.bbb.ccc.ddd)' });
  }

  return;
}

=head2 validate_boolean()

Check to make sure that any of the accepted variations on a boolean is present.

RWDE::DevelException thrown if invalid boolean detected, otherwise
just returns

=cut

sub validate_boolean {
  my ($self, $boolean) = @_;

  if ( ($boolean ne 'true')
    && ($boolean ne 't')
    && ($boolean ne '1')
    && ($boolean ne 'false')
    && ($boolean ne 'f')
    && ($boolean ne '0')
    && ($boolean ne 'NULL')) {
    throw RWDE::DevelException({ info => 'Invalid boolean expression: ' . $boolean });
  }

  return;
}

=head2 DESTROY()

Do nothing. Here just to shut up TT when AUTOLOAD is present

=cut

sub DESTROY {

}

=head2 display()

=cut

sub display {
  my ($self, $params) = @_;

  my $data = $self->get_data;

  foreach my $key (sort keys(%{$data})) {
    print "$key\t";
    print defined $data->{$key} ? ":" . $data->{$key} . ":" : 'Not defined (NULL)';
    print "\n";
  }

  return ();
}

=head2 AUTOLOAD()

All field names of the record are accessible via the field name.  If a
parameter is provided, that value is stored as the data, otherwise the
existing value if any is returned.  Throws an 'undef' exception on
error.

Example:

  $rec->password('blahblah');
  print $rec->password();
  @return (Enter explanation for return value here)

=cut

sub AUTOLOAD {
  my ($self, @args) = @_;

  if (not ref $self) {
    my ($package, $filename, $line) = caller();
    throw RWDE::DevelException(
      { info => "Record::AUTOLOAD invoked with the fieldname: $AUTOLOAD; probably static access to an undefined field/method from $filename Line: $line " . join(':', @args) . "\n" });
  }

  return $self->FIELDNAME($AUTOLOAD, @args);
}

=head2 copy_record()

Copy a source record over top of this object.

In doing so we need to verify that this is an object instance, that this object is different
than the source record.

If both of those are true then we simply copy the data present within $source into this object instance.

=cut

sub copy_record {
  my ($self, $source) = @_;

  $self->check_object();

  if ((ref $self) ne (ref $source)) {
    throw RWDE::DevelException({ info => "Cannot copy $source to $self, they have to be of the same type" });
  }

  #copy over all the fields
  foreach my $fieldname (@{ $self->{_fieldnames} }) {

    #populate all the fields
    $self->{_data}->{$fieldname} = $source->$fieldname;
  }

  return;
}

=head2 fill()

Fill an object with data specified in the params hash. If the params hash does not have
every piece of data, an exception is thrown.

=cut

sub fill {
  my ($self, $params) = @_;

  $self->check_object();

  #check to make sure we have all the necessary fields
  foreach my $fieldname (@{ $self->{_fieldnames} }) {
    throw RWDE::DevelException({ info => "Value for the required field $fieldname not found in params hash." })
      unless exists($$params{$fieldname});

    #populate the field
    $self->{_data}->{$fieldname} = $self->denormalize($fieldname, $$params{$fieldname});
  }

  return;
}

=head2 fill_required()

This function takes the required array of elements, populates the current object and notifies if there are any missing elements

=cut

sub fill_required {
  my ($self, $params) = @_;

  my @required = @{ $$params{required} };

  foreach my $f (@required) {
    if (not defined($$params{$f})) {
      $self->add_missing({ key => $f });
    }
    else {
      $self->$f($$params{$f});
    }
  }

  # verify data looks ok...
  $self->is_missing();

  return ();
}

=head2 fill_optional()

This function takes the required array of elements, populates the current object and notifies if there are any missing elements

=cut

sub fill_optional {
  my ($self, $params) = @_;

  my @optional = @{ $$params{optional} };

  foreach my $f (@optional) {
    if (defined($$params{$f})) {
      $self->$f($$params{$f});
    }
  }

  return ();
}

=head2 get_id()

Get the id value present in this classes id_name

=cut

sub get_id {
  my ($self, $params) = @_;

  my $id_name = $self->get_id_name();

  return $self->$id_name;
}

=head2 get_id_name()

Get the id_name stored within the class

=cut

sub get_id_name {
  my ($self, $params) = @_;

  return $self->get_static({ value => '_id' });
}

=head2 fetch_by_id()

=cut

sub fetch_by_id {
  my ($self, $params) = @_;

  #this element is used to lookup static variables for the given type
  my $term = $self->new();

  throw RWDE::DevelException({ info => 'Called with no initialization parameter (has to be ' . $term->get_id_name() . ')' })
    unless (defined $$params{ $term->get_id_name() });

  return $term->_fetch_by_id({ $term->get_id_name() => $$params{ $term->get_id_name() } });
}

=head2 _fetch_by_id()

=cut

sub _fetch_by_id {
  my ($self, $params) = @_;

  return $self->__fetch_by_id($params);
}

=head2 get_static()

=cut

sub get_static {
  my ($self, $params) = @_;

  my $value;

  my $key = $$params{value};

  if (ref $self) {
    $value = $self->{$key};
  }
  else {
    my $term = $self->new();
    $value = $term->{$key};
  }

  return $value;
}

=head2 check_params()

Verify that all fields specified in the required array are present within the params

Note that other fields may be present within the params, but that the required elements
must be present at a minimum.

RWDE::DevelException is thrown if the required fields are not present within the params, 
along with a string that includes the names of all missing fields. This information
maybe be useful to pass back to the user in an alternate form.

=cut

sub check_params {
  my ($self, $params) = @_;
  
  if (!(defined $params)) {
    throw RWDE::DevelException({ info => "Record::check_params: params hash not supplied" });
  }

  my @required = @{ $$params{required} };
  my $supplied = $$params{supplied};
  
  my ($package, $filename, $line) = caller(1);
  
  #ensure that we received a params hash, and not a scalar or array
  if (ref $supplied ne 'HASH') {
    throw RWDE::DevelException({ info => "Record::check_params: ($package) from $filename Line: $line attempted to pass invalid params hash"});
  }

  my @missing;
  
  foreach my $f (@required) {
    if ( not defined($$supplied{$f})
      or ($$supplied{$f} =~ m/^\s*$/)
      or ($$supplied{$f} eq '--')) {
      push @missing, $f;
    }
  }

  # verify data looks ok...
  if (@missing) {
    throw RWDE::DevelException({ info => "Record::check_params: ($package) from $filename Line: $line is missing parameters: " . join(', ', @missing) });
  }

  return ();
}

1;
