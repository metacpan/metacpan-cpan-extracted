package POE::Component::LaDBI::Response;

use v5.6.0;
use strict;
use warnings;

our $VERSION = '1.0';

our @CODES = qw(OK FAILED INVALID_HANDLE_ID);

our @DATATYPES = qw(ERROR EXCEPTION RC RV TABLE NAMED_TABLE ROW NAMED_ROW
		    COLUMN SQL);


sub new {
  my $o = shift;
  my $class = ref($o) || $o;
  my $self = bless {}, $class;

  # force args into hash
  my (%a) = @_;

  # force all keys lowercase
  my (%args) = map { lc($_), $a{$_} } keys %a;

  # force 'code' value uppercase; ignore if it doesn't exist
  $args{code} = uc($args{code}) if exists $args{code};

  # force 'datatype' value uppercase; ignore if it doesn't exist
  $args{datatype} = uc($args{datatype}) if exists $args{datatype};

  return $self->_init(%args);
} #end: new()


sub _init {
  my $self = shift;
  my (%args) = @_;

  return unless $self->_validate_code(%args);
  return unless $self->_validate_handle_id(%args);
  return unless $self->_validate_id(%args);
  return unless $self->_validate_data(%args);
  return unless $self->_validate_datatype(%args);

  $self->{code    } = delete $args{code    };
  $self->{handleid} = delete $args{handleid};
  $self->{id      } = delete $args{id      };
  $self->{data    } = delete $args{data    };
  $self->{datatype} = delete $args{datatype};


  if (keys %args) {
    warn __PACKAGE__ . "->new() unknown argument(s): ".join(',', keys %args);
  }

  return $self;
} #end: _init()


sub _validate_code {
  my $self = shift;
  my (%args) = @_;

  unless (defined $args{code}) {
    warn __PACKAGE__ . "->new() 'Code' argument required.";
    return;
  }

  unless (grep {$args{code} eq $_} @CODES) {
    warn __PACKAGE__ . "->new() value of 'Code' argument ($args{code}) not implemented.";
    return;
  }

  return $self;
} #end: _validate_code()


sub _validate_handle_id {
  my $self = shift;
  my (%args) = @_;

  return $self;
} #end: _validate_id()


sub _validate_id {
  my $self = shift;
  my (%args) = @_;

  unless (defined $args{id}) {
    warn __PACKAGE__ . "->new() 'Id' argument required.";
    return;
  }

  return $self;
} #end: _validate_id()


sub _validate_data {
  my $self = shift;
  my (%args) = @_;

  if (defined $args{data} and !defined $args{datatype}) {
    warn __PACKAGE__ . "->new() 'Data' argument must also be acompanied by a 'DataType' argument.";
    return;
  }

  return $self;
} #end: _validate_data()


sub _validate_datatype {
  my $self = shift;
  my (%args) = @_;

  if (defined $args{datatype} and !defined $args{data}) {
    warn __PACKAGE__ . "->new() 'DataType' argument must also be acompanied by a 'Data' argument.";
    return;
  }

  if (defined $args{datatype} and !grep {$args{datatype} eq $_} @DATATYPES) {
    warn __PACKAGE__ . "->new() value of 'DataType' argument ($args{datatype}) not implemented.";
    return;
  }

  return $self;
} #end: _validate_datatype()


sub code      {my $k='code'    ; @_==2 and $_[0]->{$k} = $_[1]; $_[0]->{$k}; }
sub handle_id {my $k='handleid'; @_==2 and $_[0]->{$k} = $_[1]; $_[0]->{$k}; }
sub datatype  {my $k='datatype'; @_==2 and $_[0]->{$k} = $_[1]; $_[0]->{$k}; }
sub data      {my $k='data'    ; @_==2 and $_[0]->{$k} = $_[1]; $_[0]->{$k}; }

sub id { $_[0]->{id}; }


1;
__END__

=head1 NAME

POE::Component::LaDBI::Response - Class encapsulating responses from
POE::Component::LaDBI::Engine.

=head1 SYNOPSIS

  use POE::Component::LaDBI::Response;

  $resp = POE::Component::LaDBI::Response->new
           (Code     => 'OK',
	    HandleId => $sth_id,
	    Id       => $request_id,
	    DataType => 'TABLE',
	    Data     => $fetchall_arrayref_ret);

  $resp->code;
  $resp->handle_id;
  $resp->id;
  $resp->datatype;
  $resp->data;

  $resp->id;

=head1 DESCRIPTION

=over 4

=item C<$resp-E<gt>new()>

Args:

For the keys, capitalization does not matter. Internally the keys are
lowercased.

=over 4

=item C<Code>

String identifier representing the error result of the request.

Valid C<Code> values are:

=over 4

=item C<OK>

The C<POE::Component::LaDBI::Request> succeeded as far as
C<POE::Component::LaDBI::Engine> is concerned.

=item C<FAILED>

The C<POE::Component::LaDBI::Request> failed. C<DataType> will be set to
either C<ERROR> or C<EXCEPTION>.

=item C<INVALID_HANDLE_ID>

The C<POE::Component::LaDBI::Engine> instance does not have a record of the
C<$request->handle_id>.

=back

=item C<Id>

This is the unique cookie from the C<POE::Component::LaDBI::Request>
(C<$req->id>) this C<POE::Component::LaDBI::Response> object corresponds to.
There is a one for one relationship between requests and responses.

=item C<DataType>

The type of data returned in C<Data>. If you are constucting a
C<POE::Component::LaDBI::Response> object you B<must> supply this field.
However, if you are just useing the C<POE::Component::LaDBI::Response> object
returned from C<POE::Component::LaDBI::Engine::request()> you can usually
ignore this field. This is because all requests have a fixed and known
response data type.

=over 4

=item C<TABLE>

Data is an array ref of array refs to scalars.

  Data = [ [row0col0, row0col1, ...],
           [row1col0, row1col1, ...],
           ...
         ]

=item C<NAMED_TABLE>

This one is odd. See the description of C<selectall_hashref()> in L<DBI>.
For *_hashref() calls in C<DBI> you have to provide the database table field
which will be the hash key into this hash table. The values corresponding
to each key is a hash of the rows returned from the select or fetch. I did
not invent this and do not quite understand why.

  Data = {
          row0colX_val => {col0_name => row0_val, col1_name => row0_val, ...},
	  row1colX_val => {col0_name => row1_val, col1_name => row1_val, ...},
           ...
         }

=item C<ROW>

Data is an array ref of scalars.

  Data = [ elt0, elt1, ... ]

=item C<NAMED_ROW>

Data is an hash ref containing name-value pairs of each data item
in the row; the name is the column name, the value is the column value.

  Data = { col0_name => elt0, col1_name => elt1, ... }

=item C<COLUMN>

  Data = [ elt0, elt1, ... ]

=item C<RC>

Return code is a scalar valude returned from the DBI call.

  Data = $rc

=item C<RV>

Return Value is a scalar value returned from the DBI call.

  Data = $rv

=item C<SQL>

This is the data type for the return value from DBI::quote() call.

  Data = $sql_string

=item C<ERROR>

There was an error for the DBI call. This indicates the DBI call returned
undef. The data value is a hash ref with two keys 'err' and 'errstr'. These
keys corresponed to the DBI calls of the same name: C<$h-E<gt>err> and
C<$h-E<gt>errstr>.

  Data = { err => $handle->err, errstr => $handle->errstr }

=item C<EXCEPTION>

There was an exception thrown from the DBI call. This indicates the DBI
call called a die(). All L<DBI> calles executed by
C<POE::Component::LaDBI::Engine> are wrapped in a C<eval {}> to catch any
exceptions, like when C<RaiseError> is set.

  Data = $@

=back

=item C<Data>

The value of this field is described above. It can be a scalar, hashref,
arrayref, or undef.

=back

=head3 Accessor Functions

=item C<$resp-E<gt>code()>

=item C<$resp-E<gt>id()>

=item C<$resp-E<gt>datatype()>

=item C<$resp-E<gt>data()>

Get/Set accessor funtions to the same data described in the C<new()>
constructor.

=back


=head2 EXPORT

None by default.

=head1 AUTHOR

Sean Egan, E<lt>seanegan:bigfoot_comE<gt>

=head1 SEE ALSO

L<perl>.

=cut
