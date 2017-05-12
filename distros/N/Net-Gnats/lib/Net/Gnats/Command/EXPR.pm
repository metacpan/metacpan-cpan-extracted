package Net::Gnats::Command::EXPR;
use parent 'Net::Gnats::Command';
use strictures;
BEGIN {
  $Net::Gnats::Command::EXPR::VERSION = '0.22';
}
use vars qw($VERSION);

use Net::Gnats::Constants qw(CODE_OK CODE_INVALID_EXPR);

=head1 NAME

Net::Gnats::Command::EXPR

=head1 DESCRIPTION


Specifies a query expression used to limit which PRs are returned
from the QUER command. The expression uses the normal query
expression syntax, (see Query expressions).

Multiple EXPR commands may be issued; the expressions are boolean ANDed together.

Expressions are cleared by the RSET command.

=head1 PROTOCOL

 EXPR [query expression]

=head1 RESPONSES


Possible responses include:

415 (CODE_INVALID_EXPR) The specified expression is invalid, and could not be parsed.

210 (CODE_OK) The expression has been accepted and will be used to limit the results returned from QUER.

=cut


my $c = 'EXPR';

sub new {
  my ( $class, %options ) = @_;

  my $self = bless \%options, $class;
  return $self;
}

sub as_string {
  my ($self) = @_;
  return undef if not defined $self->{expressions};
  return undef if ref( $self->{expressions} ) ne 'ARRAY';
  return $c . ' ' . join( ' & ', @{$self->{expressions}} );
}

sub is_ok {
  my ($self) = @_;
  return 0 if not defined $self->response;
  return 0 if not defined $self->response->code;
  return 1 if $self->response->code == CODE_OK;
  return 0;
}

1;
