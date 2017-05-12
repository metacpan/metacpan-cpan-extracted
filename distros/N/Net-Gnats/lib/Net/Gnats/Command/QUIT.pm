package Net::Gnats::Command::QUIT;
use parent 'Net::Gnats::Command';
use strictures;
BEGIN {
  $Net::Gnats::Command::QUIT::VERSION = '0.22';
}
use vars qw($VERSION);

use Net::Gnats::Constants qw(CODE_CLOSING);

=head1 NAME

QUIT

=head1 DESCRIPTION

Requests that the connection be closed.

The QUIT command has the dubious distinction of being the only
command that cannot fail.

=head1 PROTOCOL

 QUIT

=head1 RESPONSES

Possible responses:
201 (CODE_CLOSING) Normal exit.

=cut

my $c = 'QUIT';

sub new {
  my ( $class, %options ) = @_;
  my $self = bless {}, $class;
  return $self;
}

sub as_string {
  my ($self) = @_;
  return $c;
}

sub is_ok {
  my ($self) = @_;
  return 0 if not defined $self->response;
  return 0 if not defined $self->response->code;
  return 1 if $self->response->code == CODE_CLOSING;
  return 0;
}

1;
