package Net::Gnats::Command::APPN;
use parent 'Net::Gnats::Command';
use strictures;
BEGIN {
  $Net::Gnats::Command::APPN::VERSION = '0.22';
}
use vars qw($VERSION);

use Net::Gnats::Constants qw(CODE_SEND_TEXT CODE_OK CODE_NONEXISTENT_PR CODE_INVALID_FIELD_NAME
                             CODE_UNREADABLE_PR CODE_GNATS_LOCKED CODE_LOCKED_PR
                             CODE_INVALID_FIELD_CONTENTS);

=head1 NAME

Net::Gnats::Command::APPN

=head1 DESCRIPTION

The APPN command appends to the contents of field in PR with the supplied
text.

When first issued, it returns a 212 (CODE_SEND_TEXT).  The client
should then transmit the new field contents using the standard PR
quoting mechanism. After the server has read the new contents, it then
attempts to make the requested change to the PR.

The command returns a 210 (CODE_OK) when it does not require a Change Reason.

When the command returns a 213 () it expects a Change Reason.  The
Change Reason is a multiText value.  After successful submit of the
Change Reason, it returns a 210 (CODE_OK).

=head1 PROTOCOL

When making a change that does not require a change reason:

  APPN <pr> <field>
  <-- 212
  <change>
  <-- 210

When making a change that requires a change reason:

  APPN <pr> <field>
  <-- 212
  <change>
  <-- 213
  <change reason>
  <-- 210

=head1 RESPONSES

The possible responses are:

210 (CODE_OK) The PR field was successfully changed.

400 (CODE_NONEXISTENT_PR) The PR specified does not exist.

410 (CODE_INVALID_FIELD_NAME) The specified field does not exist.

402 (CODE_UNREADABLE_PR) The PR could not be read.

431 (CODE_GNATS_LOCKED) The database has been locked, and no PRs may
be updated until the lock is cleared.

430 (CODE_LOCKED_PR) The PR is locked, and may not be altered until
    the lock is cleared.

413 (CODE_INVALID_FIELD_CONTENTS) The supplied (or resulting) field
    contents are not valid for the field.

6xx (internal error) An internal error occurred, usually because of
permission or other filesystem-related problems. The PR may or may
not have been altered.

=cut

my $c = 'APPN';

sub new {
  my ( $class, %options ) = @_;

  my $self = bless \%options, $class;
  return $self;
}

# Actually two commands, send this first and then the contents of the
# field.
sub as_string {
  my ($self) = @_;
  return undef if not defined $self->{pr_number};
  return undef if not defined $self->{field};
  return $c . ' ' . $self->{pr_number} . ' ' . $self->{field}->name;
}

sub is_ok {
  my ($self) = @_;
  return 0 if not defined $self->response;
  return 1 if $self->response->code == CODE_OK;
  return 0;
}

1;
