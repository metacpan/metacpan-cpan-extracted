## @file
# (Enter your file info here)
#
# @copy 2007 MailerMailer LLC
# $Id: Record.pm 498 2008-08-22 15:35:28Z kamelkev $

## @class RWDE::DB::Record
# (Enter RWDE::DB::Record info here)
package RWDE::DB::Record;

use strict;
use warnings;

use Crypt::CBC;
use Crypt::Rijndael;    # aka the AES
use Error qw(:try);
use MIME::Base64;
use Storable qw(nfreeze thaw);

use RWDE::Exceptions;
use RWDE::DB::DbRegistry;

use base qw(RWDE::RObject RWDE::DB::Items Exporter);

@RWDE::DB::Record::EXPORT = qw(transaction prepare_transaction);

use vars qw($VERSION);
$VERSION = sprintf "%d", q$Revision: 555 $ =~ /(\d+)/;

## @cmethod object new()
# (Enter new info here)
# @return (Enter explanation for return value here)
sub new() {
  my ($proto, $params) = @_;

  my $class = ref($proto) || $proto;

  my $self = { _data => {}, };

  bless($self, $class);

  no strict 'refs';
  $self->{_db}                    = ${ $class . "::db" };
  $self->{_table}                 = ${ $class . "::table" };
  $self->{_id}                    = ${ $class . "::id" };
  $self->{_index}                 = ${ $class . "::index" };
  $self->{_index_fields}          = \%{ $class . "::index_fields" };
  $self->{_modifiable_fields}     = \%{ $class . "::modifiable_fields" };
  $self->{_modifiable_fieldnames} = \@{ $class . "::modifiable_fieldnames" };
  $self->{_static_fields}         = \%{ $class . "::static_fields" };
  $self->{_static_fieldnames}     = \@{ $class . "::static_fieldnames" };
  $self->{_fieldnames}            = \@{ $class . "::fieldnames" };
  $self->{_fields}                = \%{ $class . "::fields" };
  $self->{_ccrcontext}            = ${ $class . "::ccrcontext" };
  $self->{_email}                 = ${ $class . "::email" };

  # Moving static initializers 
  # my %fields_temp = (%{$self->{_static_fields}}, %{$self->{_modifiable_fields}});
  # $self->{_fields} = \%fields_temp;
  # 
  # @static_fieldnames     = sort keys %static_fields;
  # @modifiable_fieldnames = sort keys %modifiable_fields;
  # @fieldnames            = sort keys %fields;
  #                                              

  $self->initialize($params);

  return $self;
}

sub Create {
  my ($self, $params) = @_;

  my $term = $self->new;

  #copy over all modifiable field names from params
  foreach my $f (@{ $term->{_modifiable_fieldnames} }) {
    if (defined($$params{$f})) {
      $term->$f($$params{$f});
    }
  }
  
  $term->create_record();

  return $term;
}

sub Force_create {
  my ($self, $params) = @_;

  my $term = $self->new;

  #copy over _all_ field names from params
  foreach my $field (@{ $term->{_fieldnames} }) {
    next unless defined($$params{$field});
    #this circumvents the accessor and hence the check 
    #whether the field should be allowed to be modified
    $term->{_data}->{$field} = $$params{$field};
  }  
  
  $term->insert_all();

  return $term;
}


## @method void initialize()
# (Enter initialize info here)
sub initialize {
  my ($self, $params) = @_;
  return ();
}

=pod

=head2 normalize

"Normalize" the data to the data type for the database.  Returns
value suitable for insertion into database, or undef on error.
field type 'crypt' stores data in DB encrypted but presents to object
as plain text.  Specify it as "crypt:KEY" where KEY is used for the
encryption key.

=cut

## @method object normalize()
# (Enter normalize info here)
# @return (Enter explanation for return value here)
sub normalize {
  my $self  = shift;
  my $fn    = shift;
  my $value = shift;

  my $dbh = $self->get_dbh();

  return
    unless exists($self->{_fields}->{$fn});

  my $type = $self->field_type($fn);

  # The value might be an object (i.e. exception),
  # double quotes call stringify on the object and do not change the value of a plain  scalar
  if (!(defined($value)) || ("$value" eq 'NULL')) {
    $value = 'NULL';    # exists but undef
  }
  elsif ($type eq 'char') {
    $value = $dbh->quote($value);
  }
  elsif ($type eq 'char_lc') {
    $value = $dbh->quote(lc($value));
  }
  elsif ($type eq 'int') {
    $value += 0;        # make sure something there!
  }
  elsif ($type eq 'IP') {
    $value = $dbh->quote($value);
  }
  elsif ($type eq 'email') {
    $value = $dbh->quote(lc($value));
  }
  elsif ($type eq 'float') {
    $value += 0.0;      # make sure something there!
  }
  elsif ($type eq 'array') {
    $value = $dbh->quote(join($;, @$value));
  }
  elsif ($type eq 'set') {
    my @setfields = grep { defined $value->{$_} && $value->{$_} == 1 } keys %$value;
    $value = $dbh->quote(join(',', @setfields));
  }
  elsif ($type eq 'timestamp') {

    if ($value =~ m/^[0-9]+$/) {
      throw RWDE::DatabaseErrorException({ info => 'Record->' . $fn . 'of type ' . $type . ' cannot accept epoch stamp: ' . $value . ' for ' . caller() });
    }
    if ($value =~ m/^([a-z]|[A_Z])+$/) {
      throw RWDE::DatabaseErrorException({ info => 'Record->' . $fn . 'of type ' . $type . ' cannot accept epoch stamp: ' . $value . ' for ' . caller() });
    }

    $value = $dbh->quote($value);
  }
  elsif ($type eq 'boolean') {
    if (($value eq 'true') || ($value eq 't') || ($value eq '1')) {
      $value = 'true';
    }
    elsif (($value eq 'false') || ($value eq 'f') || ($value eq '0')) {
      $value = 'false';
    }
  }
  elsif ($type =~ m/crypt:(\w+)/) {

    # store string encrypted in DB, but present decrypted to object.
    my $key = $1;
    my $c   = new Crypt::CBC(
      -cipher => 'Crypt::Rijndael',
      -key    => $key
    );
    $value = $dbh->quote($c->encrypt_hex($value));
  }
  elsif ($type eq 'frozen') {

    # store frozen hash data in DB
    $value = $dbh->quote(encode_base64(nfreeze($value)));
  }
  elsif ($type eq 'hash') {

    #convert the hash to a string
    $value = $self->dehashify({ hash => $value });
    $value = $dbh->quote($value);
  }
  elsif ($type eq 'base64') {

    #convert the data from  base64 encoded value
    $value = encode_base64($value);
    $value = $dbh->quote($value);
  }
  else {
    warn "Unknown field type for $fn";    # programmer error
    $value = undef;
  }

  return $value;
}

=pod

=head2 denormalize

"Denormalize" the data based on the data type for the database.
Returns value suitable for display, or undef on error.  Currently
only does stringified ARRAY to arrayref, SET to href of keys
indicating which fields are in the set, bitvectors, timestamps, and
encrypted fields.
Stringified ARRAYs can also be converted to postgres internal array
type which we call "list".

=cut

## @method object denormalize()
# (Enter denormalize info here)
# @return (Enter explanation for return value here)
sub denormalize {
  my $self  = shift;
  my $fn    = shift;
  my $value = shift;

  return
    unless exists($self->{_fields}->{$fn});

  my $type = $self->field_type($fn);

  if ((not defined $value) and ($type eq 'boolean')) {
    return 'NULL';
  }
  elsif (not defined $value) {
    return $value;
  }

  if ($type eq 'array') {
    $value = [ split /$;/, $value ];
  }
  elsif ($type eq 'set') {
    my $h = {};
    foreach my $k (split(/,/, $value)) {
      $h->{$k} = 1;
    }
    $value = $h;
  }
  elsif ($type eq 'hash') {
    $value = $self->hashify({ string => $value });
  }
  elsif ($type =~ m/crypt:(\w+)/) {
    my $key = $1;
    if (defined $value and not($value =~ m/^53616c7465645f5f/)) {    # encryption sentinel: "RandomIV"
      throw RWDE::DevelException({ info => "$value has incorrect sentinel: cannot be decrypted" });
    }
    my $c = new Crypt::CBC(-cipher => 'Crypt::Rijndael', -key => $key, -blocksize => 16);
    $value = $c->decrypt_hex($value);
  }
  elsif ($type eq 'frozen') {
    $value = thaw(decode_base64($value));
  }
  elsif ($type eq 'base64') {

    #convert the data from  base64 encoded value
    $value = decode_base64($value);
  }

  return $value;
}

=pod

=head2 create_record

Create a record with values specified in the data fields of this object.
Returns the ID created on success, or throws an exception on failure.  
Depending on the hash set up it may depend on the database to create a unique id.

Exceptions classes thrown are C<dberr> on database error or
C<data.duplicate> for a duplicate key specified.

=cut

## @method void create_record()
# (Enter create_record info here)
sub create_record {
  my ($self, $params) = @_;

  local ($") = ",";    #"

  my @fields;          # fields to insert
  my @values;          # corresponding values
  my $table = $self->{_table};    # the table for the object

  foreach my $fieldname (@{ $self->{_modifiable_fieldnames} }) {
    next unless exists($self->{_data}->{$fieldname});    # no value specified for update

    my $value = $self->normalize($fieldname, $self->{_data}->{$fieldname});
    next unless defined($value);

    push(@fields, $fieldname);
    push(@values, $value);
  }

  my $dbh = $self->get_dbh();

  my $sth;
  if ((@fields > 0) && (@values > 0)) {
    $sth = $dbh->prepare("INSERT INTO $table (@fields) VALUES (@values)");
  }
  elsif ($self->{_id} && $self->{_index}) {
    $sth = $dbh->prepare("INSERT INTO $table (" . $self->{_id} . ") VALUES (DEFAULT)");
  }
  else {
    throw RWDE::DevelException({ info => 'Attempt to create a record without any values (default or otherwise)' });
  }

  if ($sth && $sth->execute) {
    if ($self->{_index}) {

      # we are using sequences, pull the sequence value we just assigned
      my $sth_local = $dbh->prepare("SELECT currval(?)");
      $sth_local->execute($self->{_index});
      my $newid = scalar $sth_local->fetchrow_array;    # we expect single column, single row here

      # load to populate the fields with default values in the db
      my $created = $self->fetch_by_id({ $self->{_id} => $newid });

      $self->copy_record($created);
    }
  }
  else {
    my $error = $dbh->errstr();

    # some error...
    if ($error =~ m/duplicate/i) {

      # duplicate ID
      throw RWDE::DataDuplicateException({ info => 'Duplicate information requested for create' });
    }
    else {
      throw RWDE::DevelException({ info => $error });
    }
  }

  return $self->get_id();
}

## @method void refresh()
# Re-fetch the element from the db, trigger might have updated the record
sub refresh {
  my ($self, $params) = @_;

  my $fresh = $self->fetch_by_id({ $self->get_id_name() => $self->get_id() });

  $self->copy_record($fresh);

  return ();
}

## @method protected object _fetch_by_id()
# Private routine to fetch a record by class_id
# @return the populated object
sub _fetch_by_id {
  my ($self, $params) = @_;

  my $id = $$params{ $self->{_id} };

  throw RWDE::DataNotFoundException({ info => $self . ' No id was specified to lookup' })
    unless defined $id;

  return $self->fetch_one(
    {
      query        => $self->{_id} . " = ?",
      query_params => [ $id ],
    }
  );
}

sub fetch_one_by {
  my ($self, $params) = @_;

  throw RWDE::DevelException({ info => ' No params specified for lookup' })
    unless defined $params;
    
  my @query;
  my @query_params;

  foreach my $key (keys %$params) {
    push(@query,        "$key  =?");
    push(@query_params, $$params{$key});
  }

  return $self->fetch_one({ query => join(' AND ', @query), query_params => \@query_params, });
}

## @method object fetch_random($query, $query_params)
# (Enter fetch_random info here)
# @param query_params  (Enter explanation for param here)
# @param query  (Enter explanation for param here)
# @return (Enter explanation for return value here)
sub fetch_random {
  my ($self, $params) = @_;

  #inject ordered by into the query
  my $query = $$params{query} . ' ORDER BY random() ';

  return $self->fetch_one({ query => $query, query_params => $$params{query_params} });
}

## @method object fetch_one()
# (Enter fetch_one info here)
# @return (Enter explanation for return value here)
sub fetch_one {
  my ($self, $params) = @_;

  my $items_ref = $self->fetch($params);

  my $item = $$items_ref[0]
    or throw RWDE::DataNotFoundException({ info => "No record found for the specified criteria: $self" });

  if (@$items_ref > 1) {

    #TODO weed out calls the need one element, but ask for more
    my ($package, $filename, $line, $subroutine, $hasargs, $wantarray, $evaltext, $is_require, $hints, $bitmask) = caller(1);
    warn "From $package on $line asked  for more than one element from fetch one";

    #    throw RWDE::DevelException({ info => "Fetch_one returned more than one item (" . scalar @$items_ref . ") -- check the criteria for search." });
  }

  return $item;
}

sub Update_record {
  my ($self, $params) = @_;

  #pull up the current object
  my $term = $self->fetch_by_id({ $self->get_id_name() => $$params{ $self->get_id_name } });

  #copy over all modifiable field names from params
  foreach my $f (@{ $term->{_modifiable_fieldnames} }) {
    if (defined($$params{$f})) {
      $term->$f($$params{$f});
    }
  }

  #if we got this far we are good to update the record in the db
  $term->update_record();

  return $term->get_id();
}

## @method void update_record()
# Update the record specified by the C<id> field with values
# specified in the data fields of this object.  Only updates the fields
# specified -- other fields are left alone.  Returns 1 on on success, or
# throws an exception on failure.
#
# Exceptions classes thrown are C<dberr> on database error or
# C<data.missing> for a missing ID.

sub update_record {
  my ($self, $params) = @_;

  my $id = $self->{_data}->{ $self->{_id} };

  throw RWDE::DevelException({ info => $self . 'Invalid ID specified for update' })
    unless (defined $id && $id > 0);

  my @fields = ();    # list of updates to perform

  foreach my $field (@{ $self->{_modifiable_fieldnames} }) {
    next unless exists($self->{_data}->{$field});    # no value specified for update

    my $value = $self->normalize($field, $self->{_data}->{$field});

    next unless defined($value);
    push @fields, "$field=$value";
  }

  my $dbh = $self->get_dbh();

  local ($") = ',';                                  #"

  my $row_count = $dbh->do("UPDATE " . $self->{_table} . " SET @fields WHERE " . $self->{_id} . " =?", undef, $id);

  # 0E0 means 0 rows affected, an error in single update instance
  if ($row_count eq '0E0') { $row_count = 0; }

  unless ($row_count) {
    if ((defined($dbh->errstr)) && ($dbh->errstr =~ m/duplicate/i)) {

      # duplicated a unique field
      throw RWDE::DataDuplicateException({ info => 'Non-unique value detected in field: ' . $dbh->errstr });
    }
    else {
      throw RWDE::DevelException({ info => $dbh->errstr });
    }
  }

  return ();
}

## @method void update_all()
# (Enter update_all info here)
sub update_all {
  my ($self, $params) = @_;

  my $id = $self->{_data}->{ $self->{_id} };

  throw RWDE::DevelException({ info => $self . 'Invalid ID specified for update' })
    unless (defined $id and $id > 0);

  RWDE::DB::DbRegistry->db_check_transaction({ db => $self->{_db} });

  my @fields = ();    # list of updates to perform

  foreach my $field (@{ $self->{_fieldnames} }) {
    next unless exists($self->{_data}->{$field});    # no value specified for update

    my $value = $self->normalize($field, $self->{_data}->{$field});

    next unless defined($value);
    push @fields, "$field=$value";
  }

  my $dbh = $self->get_dbh();

  local ($") = ',';                                  #"

  unless ($dbh->do("UPDATE " . $self->{_table} . " SET @fields WHERE " . $self->{_id} . " =?", undef, $id)) {
    if ($dbh->errstr =~ m/duplicate/i) {

      # duplicated a unique field
      throw RWDE::DataDuplicateException({ info => 'Non-unique value detected in field: ' . $dbh->errstr });
    }
    else {
      throw RWDE::DevelException({ info => $dbh->errstr });
    }
  }

  $self->delete_cache();

  return ();
}



sub insert_all {
  my ($self, $params) = @_;

  my @fields = ();    # list of fields to insert
  my @values;          # corresponding values
  my $table = $self->{_table};    # the table for the object

  #RWDE::DB::DbRegistry->db_check_transaction({ db => $self->{_db} });

  local ($") = ",";    #"

  foreach my $field (@{ $self->{_fieldnames} }) {
    next unless exists($self->{_data}->{$field});

    my $value = $self->normalize($field, $self->{_data}->{$field});

    next unless defined($value);

    push(@fields, $field);
    push(@values, $value);
  }

  my $dbh = $self->get_dbh();

  my $sth;
  if ((@fields > 0) && (@values > 0)) {
    $sth = $dbh->prepare("INSERT INTO $table (@fields) VALUES (@values)");
  }
  elsif ($self->{_id} && $self->{_index}) {
    $sth = $dbh->prepare("INSERT INTO $table (" . $self->{_id} . ") VALUES (DEFAULT)");
  }
  else {
    throw RWDE::DevelException({ info => 'Attempt to create a record without any values (default or otherwise)' });
  }

  # Check if the id is present in the object, if not we'll get it from the autoincrement 
  my $id = $self->{_data}->{ $self->{_id} };

  if ($sth and $sth->execute) {
    if ($self->{_index} and not defined $id) {

      # we are using sequences, pull the sequence value we just assigned
      my $sth_local = $dbh->prepare("SELECT currval(?)");
      $sth_local->execute($self->{_index});
      my $newid = scalar $sth_local->fetchrow_array;    # we expect single column, single row here

      # load to populate the fields with default values in the db
      my $created = $self->fetch_by_id({ $self->{_id} => $newid });

      $self->copy_record($created);
    }
    elsif (defined $id){
      my $created = $self->fetch_by_id({ $self->{_id} => $id });

      $self->copy_record($created);
    }
    else{
      throw RWDE::DevelException({ info => 'Id not defined or composite id not defined properly. Unable to fetch the newly inserted row from the db.' });
    }
  }
  else {
    my $error = $dbh->errstr();

    # some error...
    if ($error =~ m/duplicate/i) {

      # duplicate ID
      throw RWDE::DataDuplicateException({ info => 'Duplicate information requested for create' });
    }
    else {
      throw RWDE::DevelException({ info => $error });
    }
  }

  return $self->get_id();
}

## @method object get_data()
# (Enter get_data info here)
# @return (Enter explanation for return value here)
sub get_data {
  my ($self, $params) = @_;

  my $term_data = ();

  foreach my $fieldname (keys %{ $self->{_fields} }) {
    $$term_data{$fieldname} = $self->{_data}->{$fieldname};
  }

  return $term_data;
}

## @method object fill_new($row)
# (Enter fill_new info here)
# @param row  (Enter explanation for param here)
# @return (Enter explanation for return value here)
sub fill_new {
  my ($self, $params) = @_;

  RWDE::RObject->check_params({ required => ['row'], supplied => $params });

  my $term = $self->new();

  #map the values in the row to fieldnames
  my %values;
  foreach my $field (@{ $term->{_fieldnames} }) {
    $values{$field} = shift @{ $$params{row} };
  }

  $term->fill(\%values);

  return $term;
}

## @method object hashify($string)
# This function converts a string representing a hash into a hash reference and returns it
#TODO This should probably be turned into some fancy fast regex
# @param string  (Enter explanation for param here)
# @return (Enter explanation for return value here)
sub hashify {
  my ($self, $params) = @_;

  my $string = $$params{string};

  #drop out curly brackets if they are present
  $string =~ s/{//g;
  $string =~ s/}//g;

  my $hashref = {};

  my @elements = split /,/, $string;

  foreach my $element (@elements) {

    #eliminate quotes
    $element =~ s/"//g;

    if ($element ne '') {
      my @parts = split / => /, $element;
      $$hashref{ $parts[0] } = $parts[1];
    }
  }

  return $hashref;
}

## @method object dehashify($hash)
# Convert a hash with elements strictly as values into a string
# so that it can be readable in the db by people
# @param hash  (Enter explanation for param here)
# @return (Enter explanation for return value here)
sub dehashify {
  my ($self, $params) = @_;

  my $hash = $$params{hash};

  #add curly brackets

  my $string = '{';

  foreach my $key (keys %{$hash}) {
    $string = $string . $key . ' => ' . $hash->{$key} . ',';
  }

  $string = $string . '}';

  return $string;
}

## @method object get_status()
# (Enter get_status info here)
# @return (Enter explanation for return value here)
sub get_status {
  my ($self, $params) = @_;

  return throw RWDE::DevelException({ info => "get_status is an abstract function in Record - the inherting class should implement it" });
}

## @method object get_password()
# (Enter get_password info here)
# @return (Enter explanation for return value here)
sub get_password {
  my ($self, $params) = @_;

  return throw RWDE::DevelException({ info => "get_password is an abstract function in Record - the inherting class should implement it" });
}

## @method void is_missing()
# (Enter is_missing info here)
sub is_missing {
  my ($self, $params) = @_;

  my $missing = $self->get_missing();

  if (scalar keys %{$missing}) {
    throw RWDE::DataMissingException({ info => $self->dehashify({ hash => $missing }) });
  }

  return ();
}

## @method object get_missing()
# (Enter get_missing info here)
# @return (Enter explanation for return value here)
sub get_missing {
  my ($self, $params) = @_;

  if (!$self->{Missing}) {
    $self->{Missing} = {};
  }

  return $self->{Missing};
}

## @method void add_missing($key, $value)
# (Enter add_missing info here)
# @param value  (Enter explanation for param here)
# @param key  (Enter explanation for param here)
sub add_missing {
  my ($self, $params) = @_;

  my $missing = $self->get_missing();

  my $key = $$params{key};

  $key =~ s/ //g;

  if (defined $$params{value}) {
    $$missing{$key} = $$params{value};
  }
  else {
    $$missing{$key} = $self->field_desc($key);
  }

  return ();
}

## @method object get_ceil()
# (Enter get_ceil info here)
# @return (Enter explanation for return value here)
sub get_ceil {
  my ($self, $number) = @_;

  if ((not defined $number) or ($number == 0) or (int($number) == $number)) {
    return $number;
  }
  else {
    return int($number + 1);
  }
}

## @method object get_db()
# (Enter get_db info here)
# @return (Enter explanation for return value here)
sub get_db {
  my ($self, $params) = @_;

  return defined $self->get_static({ value => '_db' }) ? $self->get_static({ value => '_db' }) : 'default';
}

## @method object get_dbh()
# (Enter get_dbh info here)
# @return (Enter explanation for return value here)
sub get_dbh {
  my ($self, $params) = @_;

  return RWDE::DB::DbRegistry->get_dbh({ db => $self->get_db() });
}

#Transaction handling
#------------------------------
## @method void transaction()
# This closure provides support for a group of database operations to be executed immediately at runtime as a singular transaction.
# The intent is to provide support for a group of database operations to be executed in an atomic fashion. In order to accomplish
# this for a code block utilize the transaction closure as follows:
# -
#transaction {
#   database_operation_1();
#   database_operation_2();
# };
# -
# Before executing the enclosed code block the RWDE::DB::DbRegistry will signal the database backend to start a transaction
# on the first connection utilized within the code. The underlying logic only affords a transaction to operate across one
# connection - so in the event that the code block requires more than one connection an exception will be thrown.
# -
# Note that transaction closures may be nested within each-other however any nested transactions are essentially no-ops.
# This enables you to guarantee that any particular method will be within a transaction if you require.
# -
# In the event that you require transactions across multiple connections you should see "prepare_transaction"
# &param code  the requested code to be executed within a transaction
sub transaction(&) {
  my $code = shift;

  if (!RWDE::DB::DbRegistry->transaction_signalled) {
    try {
      RWDE::DB::DbRegistry->signal_transaction();
      &$code();
      RWDE::DB::DbRegistry->commit_transaction();
    }
    catch Error with {
      my $ex = shift;

      #RWDE::Logger->syslog_msg('info', "In transaction: " . $ex);

      RWDE::DB::DbRegistry->abort_transaction();
      $ex->throw();
    };
  }
  else {
    RWDE::Logger->syslog_msg('info', "Already in transaction, executing code");
    &$code();
  }

  return ();
}

## @method object prepare_transaction()
# This closure provides support for grouping database operations that need to be performed atomically.
# The intent is to provide a means of guaranteeing that transactions across different database connections can
# all be committed atomically. The closure operates in a similar way to transaction() except that prepared transactions
# may not be nested within each-other (they may utilize nested transaction() closures however)
# -
# Typically utilization of this method would include a pair of calls like follows:
# -
# my $named = prepare_transaction {
#   database_operation();
# };
# -
# Before executing the enclosed code, RWDE::DB::DbRegistry will signal the database backend to start a transaction on the first connection
# that is utilized within the code. A transaction can only operate on one connection at a time - otherwise an exception is thrown.
# In the event that you want to submit or abort the prepared transaction see "commit_transaction" & "abort_transaction"
# @param code  the requested code to be executed within a transaction
# @return string representing the database handle of the prepared transaction
sub prepare_transaction(&) {
  my $code = shift;

  if (RWDE::DB::DbRegistry->transaction_signalled) {
    throw RWDE::DevelException({ info => "Attempt to nest a named transaction within a previously established transaction." });
  }

  my $transaction_name = undef;

  try {
    RWDE::DB::DbRegistry->signal_transaction();
    &$code();
    $transaction_name = RWDE::DB::DbRegistry->prepare_transaction();
  }
  catch Error with {
    my $ex = shift;

    RWDE::Logger->syslog_msg('info', 'In prepare: ' . $ex);

    RWDE::DB::DbRegistry->abort_transaction();

    $ex->throw();
  };

  return $transaction_name;
}

## @method object create_record_temp($login_id)
# (Enter create_record_temp info here)
# @param login_id  (Enter explanation for param here)
# @return (Enter explanation for return value here)
sub create_record_temp {
  my ($self, $params) = @_;

  my $term;

  my $transaction_name = prepare_transaction {
    $term = $self->create($params);
  };

  $term->{_data}->{transaction_name} = $transaction_name;

  return $term;
}

## @method void commit_record_temp()
# This method commits the prepared transaction referenced by the transaction_name parameter.
sub commit_record_temp {
  my ($self, $params) = @_;

  my $transaction_name = defined $$params{transaction_name} ? $$params{transaction_name} : $self->{_data}->{transaction_name};

  if (not defined($transaction_name)) {
    throw RWDE::DevelException({ info => $self . 'This record is not involved in a temporary transaction.' });
  }

  RWDE::DB::DbRegistry->commit_prepared_transaction({ transaction_name => $transaction_name, db => $self->get_db()  });

  delete $self->{_data}->{transaction_name} if ref $self;

  return 1;
}

## @method void abort_record_temp()
# This method aborts the prepared transaction represented by the transaction_name parameter.
sub abort_record_temp {
  my ($self, $params) = @_;

  my $transaction_name = defined $$params{transaction_name} ? $$params{transaction_name} : $self->{_data}->{transaction_name};

  if (not defined($transaction_name)) {
    throw RWDE::DevelException({ info => $self . 'This record is not involved in a temporary transaction.' });
  }

  RWDE::DB::DbRegistry->abort_prepared_transaction({ transaction_name => $transaction_name });

  delete $self->{_data}->{transaction_name} if ref $self;

  return ();
}

1;

