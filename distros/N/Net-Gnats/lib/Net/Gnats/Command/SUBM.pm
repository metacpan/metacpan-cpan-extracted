package Net::Gnats::Command::SUBM;
use parent 'Net::Gnats::Command';
use strictures;
BEGIN {
  $Net::Gnats::Command::SUBM::VERSION = '0.22';
}
use vars qw($VERSION);

use Net::Gnats::Constants qw(CODE_GNATS_LOCKED CODE_SEND_PR CODE_INFORMATION_FILLER CODE_INFORMATION);

=head1 NAME

Net::Gnats::Command::SUBM

=head1 DESCRIPTION

Submits a new PR into the database. The supplied text is verified for
correctness, and if no problems are found a new PR is created.

=head1 PROTOCOL

 SUBM
 <PR CONTENTS>

=head1 RESPONSES

The possible responses are:

431 (CODE_GNATS_LOCKED) The database has been locked, and no PRs may
be submitted until the lock is cleared.

211 (CODE_SEND_PR) The client should now transmit the new PR text
using the normal quoting mechanism. After the PR has been sent, the
server will respond with either

351 (CODE_INFORMATION_FILLER) and
350 (CODE_INFORMATION) responses indicating that the new PR has been
created and supplying the number assigned to it, or one or more
error codes listing problems with the new PR text.

=cut

my $c = 'SUBM';

sub new {
  my ( $class, %options ) = @_;

  my $self = bless \%options, $class;
  return $self;
}

sub as_string {
  my ($self) = @_;
  return undef if not defined $self->{pr};
  return $c;
}

sub is_ok {
  my ($self) = @_;
  # command not run yet
  return 0 if not defined $self->response;
  # malformed response
  return 0 if not defined $self->response->code;
  return 1 if $self->response->code == CODE_INFORMATION;
  return 0;
}

1;
