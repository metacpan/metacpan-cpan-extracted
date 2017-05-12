package Net::Gnats::Command::FTYP;
use parent 'Net::Gnats::Command';
use strictures;
BEGIN {
  $Net::Gnats::Command::FTYP::VERSION = '0.22';
}
use vars qw($VERSION);

use Net::Gnats::Constants qw(CODE_INFORMATION CODE_INVALID_FIELD_NAME);

=head1 NAME

Net::Gnats::Command::FTYP

=head1 DESCRIPTION

Describes the type of data held in the field(s) specified with the
command.

If multiple field names were given, multiple response lines will be
sent, one for each field, using the standard continuation protocol;
each response except the last will have a dash - immedately after
the response code.

The currently defined data types are:

Text

A plain text field, containing exactly one line.

MultiText

A text field possibly containing multiple lines of text.

Enum

An enumerated data field; the value is restricted to one entry out
of a list of values associated with the field.

MultiEnum

The field contains one or more enumerated values. Values are
separated with spaces or colons :.

Integer

The field contains an integer value, possibly signed.

Date

The field contains a date.

TextWithRegex

The value in the field must match one or more regular expressions
associated with the field.

=head1 PROTOCOL

 FTYP [fields...]

=head1 RESPONSES

The possible responses are:

350 (CODE_INFORMATION)

The normal response; the supplied text is the data type.

410 (CODE_INVALID_FIELD_NAME)

The specified field does not exist.

=cut


my $c = 'FTYP';

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
  return $c . ' ' . join ( ' ', @{$self->{fields}} );
}

# this command can take multiple fields, each getting their own response.
# so, we check that 'everything' is okay by looking at the parent response.
sub is_ok {
  my $self = shift;
  return 0 if not defined $self->response;
  return 0 if not defined $self->response->code;

  if ( $self->{requests_multi} == 0 and
       $self->response->code == CODE_INFORMATION) {
    return 1;
  }
  return 1 if $self->response->code == CODE_INFORMATION;
  return 0;
}


1;
