package Net::Gnats::Command::RSET;
use parent 'Net::Gnats::Command';
use strictures;
BEGIN {
  $Net::Gnats::Command::RSET::VERSION = '0.22';
}
use vars qw($VERSION);

use Net::Gnats::Constants qw(CODE_OK CODE_CMD_ERROR);

=head1 NAME

Net::Gnats::Command::RSET

=head1 DESCRIPTION

Used to reset the internal server state. The current query expression
is cleared, and the index of PRs may be reread if it has been updated
since the start of the session.

=head1 PROTOCOL

 RSET

=head1 RESPONSES

The possible responses are:

210 (CODE_OK)

The state has been reset.

440 (CODE_CMD_ERROR)

One or more arguments were supplied to the command.

6xx (internal error)

There were problems resetting the state (usually because the index
could not be reread). The session will be immediately terminated.

=cut

my $c = 'RSET';

sub new {
  my ( $class, %options ) = @_;

  my $self = bless {}, $class;
  return $self;
}

sub as_string {
  my $self = shift;
  return $c;
}

sub is_ok {
  my $self = shift;
  return 0 if not defined $self->response;
  return 0 if not defined $self->response->code;
  return 1 if $self->response->code == CODE_OK;
  return 0;
}

1;
