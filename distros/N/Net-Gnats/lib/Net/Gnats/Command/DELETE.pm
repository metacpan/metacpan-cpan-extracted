package Net::Gnats::Command::DELETE;
use parent 'Net::Gnats::Command';
use strictures;
BEGIN {
  $Net::Gnats::Command::DELETE::VERSION = '0.22';
}
use vars qw($VERSION);

use Net::Gnats::Constants qw(CODE_OK CODE_NO_ACCESS CODE_LOCKED_PR CODE_GNATS_LOCKED);

=head1 NAME

Net::Gnats::Command::DELETE

=head1 DESCRIPTION

Deletes the specified PR. The user making the request must have
admin privileges (see Controlling access to databases). If
successful, the PR is removed from the filesystem and the index
file; a gap will be left in the numbering sequence for PRs. No
checks are made that the PR is closed.

=head1 PROTOCOL

 DELETE [PR NUMBER]

=head1 RESPONSES

The possible responses are:

210 (CODE_OK)

The PR was successfully deleted.

422 (CODE_NO_ACCESS)

The user requesting the delete does not have admin privileges.

430 (CODE_LOCKED_PR)

The PR is locked by another session.

431 (CODE_GNATS_LOCKED)

The database has been locked, and no PRs may be updated until the
lock is cleared.

6xx (internal error)

The PR could not be successfully deleted, usually because of
permission or other filesystem-related problems.

=cut

my $c = 'DELETE';

sub new {
  my ( $class, %options ) = @_;

  my $self = bless \%options, $class;
  return $self;
}

sub as_string {
  my $self = shift;
  return $c . ' ' . $self->{pr_number};
}

sub is_ok {
  my $self = shift;
  return 1 if $self->response->code == CODE_OK;
  return 0;
}

1;
