package Net::Gnats::Command::USER;
use parent 'Net::Gnats::Command';
use strictures;
BEGIN {
  $Net::Gnats::Command::USER::VERSION = '0.22';
}
use vars qw($VERSION);

use Net::Gnats::Constants qw(CODE_INFORMATION CODE_NO_ACCESS CODE_OK);

=head1 NAME

Net::Gnats::Command::USER

=head1 DESCRIPTION

Specifies the userid and password for database access. Either both a
username and password must be specified, or they both may be
omitted; in the latter case, the current access level is returned.

=head1 PROTOCOL

 USER <User ID> <Password>

=head1 RESPONSES

The possible server responses are:

350 (CODE_INFORMATION) The current access level is specified.

422 (CODE_NO_ACCESS) A matching username and password could not be
found.

210 (CODE_OK) A matching username and password was found, and the
login was successful.

=cut

my $c = 'USER';

sub new {
  my ( $class, %options ) = @_;

  my $self = bless \%options, $class;
  return $self;
}

sub as_string {
  my ( $self ) = @_;
  return $c if not defined $self->{username};
  return undef if not defined $self->{password};
  return $c . ' ' . $self->{username} . ' ' . $self->{password};
}

sub level {
  my ($self) = @_;
  # get response.  if username is specified, we will get a database
  # for the first content string.  if not specified, we simply get the
  # level from the second result.

  # Examples:
  # USER madmin madmin
  # 210-Now accessing GNATS database 'default'
  # 210 User access level set to 'admin'

  # user
  # 351-The current user access level is:
  # 350 admin

  if ( defined $self->{username} ) {
    $self->{db}    = @{$self->response->as_list}[0] =~ /Now accessing GNATS database '(.*)'/;
    $self->{level} = @{$self->response->as_list}[1] =~ /User access level set to '(.*)'/;
  }
  else {
    $self->{level} = @{$self->response->as_list}[1];
  }
  return $self->{level};
}

sub is_ok {
  my ($self) = @_;
  return 0 if not defined $self->response;
  return 0 if not defined $self->response->code;
  return 0 if $self->response->code == CODE_NO_ACCESS;
  return 1;
}

1;
