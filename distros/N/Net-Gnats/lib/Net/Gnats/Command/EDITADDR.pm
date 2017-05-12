package Net::Gnats::Command::EDITADDR;
use parent 'Net::Gnats::Command';
use strictures;
BEGIN {
  $Net::Gnats::Command::EDITADDR::VERSION = '0.22';
}
use vars qw($VERSION);

use Net::Gnats::Constants qw(CODE_OK CODE_CMD_ERROR);

=head1 NAME

Net::Gnats::Command::EDITADDR

=head1 DESCRIPTION

Sets the e-mail address of the person communicating with gnatsd. The
command requires at least the edit access level.

=head1 PROTOCOL

 EDITADDR [address]

=head1 RESPONSES

The possible responses are:

200 (CODE_OK)
The address was successfully set.

440 (CODE_CMD_ERROR)
Invalid number of arguments were supplied.

=cut


my $c = 'EDITADDR';

sub new {
  my ( $class, %options ) = @_;

  my $self = bless \%options, $class;
  return $self;
}

sub as_string {
  my ($self) = @_;
  return undef if not defined $self->{address};
  return $c . ' ' . $self->{address};
}

sub is_ok {
  my ($self) = @_;
  # command not issued
  return 0 if not defined $self->response;
  # malformed command
  return 0 if not defined $self->response->code;
  return 1 if $self->response->code == CODE_OK;
  return 0;
}

1;
