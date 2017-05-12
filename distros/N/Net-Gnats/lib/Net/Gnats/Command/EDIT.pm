package Net::Gnats::Command::EDIT;
use parent 'Net::Gnats::Command';
use strictures;
BEGIN {
  $Net::Gnats::Command::EDIT::VERSION = '0.22';
}
use vars qw($VERSION);

use Net::Gnats::Constants qw(CODE_SEND_PR CODE_OK CODE_GNATS_LOCKED CODE_NONEXISTENT_PR CODE_SEND_PR);

=head1 NAME

Net::Gnats::Command::EDIT

=head1 DESCRIPTION

Verifies the replacement text for PR. If the command is successful,
the contents of PR are completely replaced with the supplied text. The
PR must previously have been locked with the LOCK command.

=head1 PROTOCOL

 EDIT [PR NUMBER]
 [PR CONTENTS]

=head1 RESPONSES

The possible responses are:

431 (CODE_GNATS_LOCKED)

The database has been locked, and no PRs may be updated until the lock
is cleared.

433 (CODE_PR_NOT_LOCKED)

The PR was not previously locked with the LOCK command.

400 (CODE_NONEXISTENT_PR)

The specified PR does not currently exist. The SUBM command should be
used to create new PRs.

211 (CODE_SEND_PR)

The client should now transmit the replacement PR text using the
normal PR quoting mechanism. After the PR has been sent, the server
will respond with either 200 (CODE_OK) indicating that the edit was
successful, or one or more error codes listing problems either with
the replacement PR text or errors encountered while updating the PR
file or index.

=cut

my $c = 'EDIT';

sub new {
  my ( $class, %options ) = @_;

  my $self = bless \%options, $class;
  $self->{pr_number} = '-1' if not defined $self->{pr_number};
  return $self;
}

sub as_string {
  my ($self) = @_;
  return undef if not defined $self->{pr_number};
  return undef if not defined $self->{pr};
  return $c . ' ' . $self->{pr_number};
}

sub is_ok {
  my ($self) = @_;
  # returned undef because command could not be run
  return 0 if not defined $self->response;

  return 1 if $self->response->code == CODE_OK;
  return 0;
}


1;
