package Net::Gnats::Command::VFLD;
use parent 'Net::Gnats::Command';
use strictures;
BEGIN {
  $Net::Gnats::Command::VFLD::VERSION = '0.22';
}
use vars qw($VERSION);

use Net::Gnats::Constants qw(CODE_OK CODE_SEND_TEXT CODE_INVALID_FIELD_NAME);

=head1 NAME

Net::Gnats::Command::VFLD

=head1 DESCRIPTION

VFLD can be used to validate a given value for a field in the
database. The client issues the VFLD command with the name of the
field to validate as an argument. The server will either respond
with 212 (CODE_SEND_TEXT), or 410 (CODE_INVALID_FIELD_NAME) if the
specified field does not exist.

Once the 212 response is received from the server, the client should
then send the line(s) of text to be validated, using the normal
quoting mechanism described for PRs. The final line of text is
followed by a line containing a single period, again as when sending
PR text.

The server will then either respond with 210 (CODE_OK), indicating
that the text is acceptable, or one or more error codes describing
the problems with the field contents.

=head1 PROTOCOL

 VFLD <Field>
 <Field contents>

=head1 RESPONSES

CODE_SEND_TEXT
CODE_INVALID_FIELD_NAME

=cut

my $c = 'VFLD';

sub new {
  my ( $class, %options ) = @_;
  my $self = bless \%options, $class;
  return $self;
}

sub as_string {
  my ($self) = @_;
  return undef if not defined $self->{field};
  return $c . ' ' . $self->field->name;
}

sub is_ok {
  my ($self) = @_;
  return 0 if not defined $self->response;
  return 1 if $self->response->code == CODE_OK;
  return 0;
}

1;
