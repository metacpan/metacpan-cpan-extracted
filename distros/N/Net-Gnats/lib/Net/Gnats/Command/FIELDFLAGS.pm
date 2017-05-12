package Net::Gnats::Command::FIELDFLAGS;
use parent 'Net::Gnats::Command';
use strictures;
BEGIN {
  $Net::Gnats::Command::FIELDFLAGS::VERSION = '0.22';
}
use vars qw($VERSION);

use Net::Gnats::Constants qw(CODE_INFORMATION CODE_INVALID_FIELD_NAME);

=head1 NAME

Net::Gnats::Command::FIELDFLAGS

=head1 DESCRIPTION

Returns a set of flags describing the specified field(s).

Like the FDSC and FTYP commands, multiple field names may be listed
with the command, and a response line will be returned for each one
in the order that the fields appear on the command line.

The flags include:

textsearch

The field will be searched when a text field search is requested.

allowAnyValue

For fields that contain enumerated values, any legal value may be
used in the field, not just ones that appear in the enumerated list.

requireChangeReason

If the field is edited, a reason for the change must be supplied in
the new PR text describing the reason for the change. The reason
must be supplied as a multitext PR field in the new PR whose name is
field-Changed-Why (where field is the name of the field being
edited).

readonly

The field is read-only, and cannot be edited.

=head1 PROTOCOL

 FIELDFLAGS [fields...]

=head1 RESPONSES

410 (CODE_INVALID_FIELD_NAME)

meaning that the specified field is invalid or nonexistent, or

350 (CODE_INFORMATION)

which contains the set of flags for the field. The flags may be
blank, which indicate that no special flags have been set for this
field.

=cut

my $c = 'FIELDFLAGS';

sub new {
  my ( $class, %options ) = @_;
  my $self = bless \%options, $class;
  $self->{requests_multi} = 0;
  return $self if not defined $self->{fields};

  if (ref $self->{fields} eq 'ARRAY') {
    $self->{requests_multi} = 1 if scalar @{ $self->{fields} } > 1;
  }
  else {
    $self->{fields} = [ $self->{fields} ];
  }
  return $self;
}

sub as_string {
  my ($self) = @_;
  return undef if not defined $self->{fields};
  return undef if ref $self->{fields} ne 'ARRAY';
  return undef if scalar @{ $self->{fields} } == 0;
  return $c . ' ' . join ( ' ', @{$self->{fields}} );
}

# this command can take multiple fields, each getting their own response.
# so, we check that 'everything' is okay by looking at the parent response.
sub is_ok {
  my $self = shift;
  return 0 if not defined $self->response;

  if ( $self->{requests_multi} == 0 and
       $self->response->code == CODE_INFORMATION) {
    return 1;
  }
  return 1 if $self->response->code == CODE_INFORMATION;
  return 0;
}

1;
