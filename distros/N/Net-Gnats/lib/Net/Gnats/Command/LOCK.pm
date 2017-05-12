package Net::Gnats::Command::LOCK;
use parent 'Net::Gnats::Command';
use strictures;
BEGIN {
  $Net::Gnats::Command::LOCK::VERSION = '0.22';
}
use vars qw($VERSION);

use Net::Gnats::Constants qw(CODE_CMD_ERROR CODE_PR_READY CODE_NONEXISTENT_PR CODE_LOCKED_PR);

=head1 NAME

Net::Gnats::Command::LOCK

=head1 DESCRIPTION

Locks the specified PR, marking the lock with the user name and the
optional pid. (No checking is done that the user or pid arguments
are valid or meaningful; they are simply treated as strings.)

The EDIT command requires that the PR be locked before it may be
successfully executed. However, it does not require that the lock is
owned by the editing session, so the usefulness of the lock is
simply as an advisory measure.

The APPN and REPL commands lock the PR as part of the editing
process, and they do not require that the PR be locked before they
are invoked.

=head1 PROTOCOL

 LOCK <pr> <user> [pid]

=head1 RESPONSES

The possible responses are:

440 (CODE_CMD_ERROR)

Insufficient or too many arguments were specified to the command.

300 (CODE_PR_READY)

The lock was successfully obtained; the text of the PR (using the
standard quoting mechanism for PRs) follows.

400 (CODE_NONEXISTENT_PR)

The PR specified does not exist.

430 (CODE_LOCKED_PR)

The PR is already locked by another session.

6xx (internal error)

The PR lock could not be created, usually because of permissions or
other filesystem-related issues.

=cut

my $c = 'LOCK';

sub new {
  my ( $class, %options ) = @_;
  my $self = bless \%options, $class;
  return $self;
}

sub as_string {
  my $self = shift;
  return undef if not defined $self->{pr_number};
  return undef if not defined $self->{user};
  my $command = $c . ' ' . $self->{pr_number} . ' ' . $self->{user};
  if (defined $self->{pid}) {
    $command .= ' ' . $self->{pid};
  }
  return $command;
}

sub is_ok {
  my $self = shift;
  return 0 if not defined $self->response;
  return 1 if $self->response->code == CODE_PR_READY;
  return 0;
}

1;
