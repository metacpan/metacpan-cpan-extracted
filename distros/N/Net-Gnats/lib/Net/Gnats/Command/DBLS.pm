package Net::Gnats::Command::DBLS;
use parent 'Net::Gnats::Command';
use strictures;
BEGIN {
  $Net::Gnats::Command::DBLS::VERSION = '0.22';
}
use vars qw($VERSION);

use Net::Gnats::Constants qw(CODE_TEXT_READY);

=head1 NAME

Net::Gnats::Command::DBLS

=head1 DESCRIPTION

Lists the known set of databases.

The gnatsd access level listdb denies access until the user has
authenticated with the USER command. The only other command
available at this access level is DBLS. This access level provides a
way for a site to secure its gnats databases while still providing a
way for client tools to obtain a list of the databases for use on
login screens etc.

The list of databases follows, one per line, using the standard
quoting mechanism. Only the database names are sent.

=head1 PROTOCOL

 DBLS

=head1 RESPONSES

The possible responses are:

6xx (internal error) An internal error was encountered while trying
to obtain the list of available databases, usually due to lack of
permissions or other filesystem-related problems, or the list of
databases is empty.

301 (CODE_TEXT_READY)

=cut

my $c = 'DBLS';

sub new {
  my ( $class ) = @_;
  my %options = shift if $_;
  my $self = bless \%options, $class;
  return $self;
}

sub as_string {
  return $c;
}

sub is_ok {
  my ($self) = @_;
  return 1 if $self->response->code == CODE_TEXT_READY;
  return 0;
}

1;
