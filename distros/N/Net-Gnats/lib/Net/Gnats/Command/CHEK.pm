package Net::Gnats::Command::CHEK;
use parent 'Net::Gnats::Command';
use strictures;
BEGIN {
  $Net::Gnats::Command::CHEK::VERSION = '0.22';
}
use vars qw($VERSION);

use Net::Gnats::Constants qw(CODE_SEND_PR CODE_OK CODE_CMD_ERROR);

=head1 NAME

Net::Gnats::Command::CHEK

=head1 DESCRIPTION

Used to check the text of an entire PR for errors. Unlike the VFLD
command, it accepts an entire PR at once instead of the contents of an
individual field.

The initial argument indicates that the PR text to be checked is for a
PR that will be newly created, rather than an edit or replacement of
an existing PR.

=heads EXAMPLES

 # Check an initial PR
 Net::Gnats::Command::CHEK(pr => $pr, type = 'initial');

 # Check a modified PR
 Net::Gnats::Command::CHEK(pr => $pr);

 # Issue to Gnats
 $session->issue(Net::Gnats::Command::CHEK(pr => $pr))->is_ok;

 # If running from Net::Gnats object
 $g->session->issue(Net::Gnats::Command::CHEK(pr => $pr))->is_ok;

=head1 PROTOCOL

 CHEK [initial]

=head1 RESPONSES

After the CHEK command is issued, the server will respond with either
a 440 (CODE_CMD_ERROR) response indicating that the command arguments
were incorrect, or a 211 (CODE_SEND_PR) response code will be sent.

Once the 211 response is received from the server, the client should
send the PR using the normal PR quoting mechanism; the final line of
the PR is then followed by a line containing a single period, as
usual.

The server will then respond with either a 200 (CODE_OK) response,
indicating there were no problems with the supplied text, or one or
more error codes listing the problems with the PR.

=cut

my $c = 'CHEK';

sub new {
  my ( $class, %options ) = @_;
  my $self = bless \%options, $class;
  return $self;
}

sub as_string {
  my $self = shift;
  return $c . ' ' . $self->{type} if defined $self->{type};
  return $c;
}

sub is_ok {
  my $self = shift;
  return 1 if $self->response->code == CODE_OK;
  return 0;
}

1;
