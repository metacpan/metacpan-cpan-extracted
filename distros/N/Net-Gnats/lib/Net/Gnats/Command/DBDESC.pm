package Net::Gnats::Command::DBDESC;
use parent 'Net::Gnats::Command';
use strictures;
BEGIN {
  $Net::Gnats::Command::DBDESC::VERSION = '0.22';
}
use vars qw($VERSION);

use Net::Gnats::Constants qw(CODE_INFORMATION CODE_INVALID_DATABASE CODE_CMD_ERROR);

=head1 NAME

Net::Gnats::Command::DEDESC

=head1 DESCRIPTION

Returns a human-readable description of the specified database.

=head1 PROTOCOL

 DBDESC [database]

=head1 RESPONSES

Responses include:

6xx (internal error) An internal error was encountered while trying
to read the list of available databases, usually due to lack of
permissions or other filesystem-related problems, or the list of
databases is empty.

350 (CODE_INFORMATION) The normal response; the supplied text is the
database description.

417 (CODE_INVALID_DATABASE) The specified database name does not
have an entry.

440 (CODE_CMD_ERROR) Required parameter not passed.

=cut

my $c = 'DBDESC';

sub new {
  my ( $class, %options ) = @_;

  my $self = bless \%options, $class;
  $self->{name} = $self->{name} || '';
  return $self;
}

sub to_string {
  my ($self) = @_;
  return $c . ' ' . $self->{name};
}

sub is_ok {
  my $self = shift;
  return 1 if $self->response->code == CODE_INFORMATION;
  return 0;
}

1;
