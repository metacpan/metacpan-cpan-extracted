package Net::Gnats::Command::QFMT;
use parent 'Net::Gnats::Command';
use strictures;
BEGIN {
  $Net::Gnats::Command::QFMT::VERSION = '0.22';
}
use vars qw($VERSION);

use Net::Gnats::Constants qw(CODE_OK CODE_CMD_ERROR CODE_INVALID_QUERY_FORMAT);

=head1 NAME

Net::Gnats::Command::QFMT

=head1 DESCRIPTION

Use the specified query format to format the output of the QUER
command. The query format may be either the name of a query format
known to the server (see Named query definitions), or an actual
query format (see Formatting query-pr output).

=head1 PROTOCOL

 QFMT <query format>

=head1 RESPONSES

The possible
responses are:

210 (CODE_OK) The normal response, which indicates that the query
    format is acceptable.

440 (CODE_CMD_ERROR) No query format was supplied.

418 (CODE_INVALID_QUERY_FORMAT) The specified query format does not
    exist, or could not be parsed.

=cut

my $c = 'QFMT';

sub new {
  my ( $class, %options ) = @_;

  my $self = bless \%options, $class;
  return $self;
}

sub as_string {
  my $self = shift;
  return undef if not defined $self->{format};
  return $c . ' ' . $self->{format};
}

sub is_ok {
  my $self = shift;
  return 0 if not defined $self->response;
  return 1 if $self->response->code == CODE_OK;
  return 0;
}

1;
