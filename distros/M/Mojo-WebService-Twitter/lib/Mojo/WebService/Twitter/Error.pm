package Mojo::WebService::Twitter::Error;
use Mojo::Base -base;

use Exporter 'import';

use overload bool => sub {1}, '""' => sub { shift->to_string }, fallback => 1;

our $VERSION = '0.002';
our @EXPORT_OK = qw(twitter_tx_error);

has 'api_errors' => sub { [] };
has ['connection_error','http_status','http_message'];

sub twitter_tx_error ($) { __PACKAGE__->new->from_tx(shift) }

sub from_tx {
	my ($self, $tx) = @_;
	my $res = $tx->res;
	delete $self->{connection_error};
	delete $self->{api_errors};
	$self->http_status($res->code);
	$self->http_message($res->message);
	return $self unless my $err = $res->error;
	$self->connection_error($err->{message}) unless defined $err->{code};
	return $self->api_errors(($res->json // {})->{errors} // []);
}

sub to_string {
	my $self = shift;
	if (defined(my $err = $self->connection_error)) {
		return "Connection error: $err";
	} elsif (my @errs = @{$self->api_errors}) {
		return "API error $errs[0]{code}: $errs[0]{message}";
	} else {
		return 'HTTP status ' . $self->http_status . ': ' . $self->http_message;
	}
}

1;

=head1 NAME

Mojo::WebService::Twitter::Error - Container for API errors

=head1 SYNOPSIS

 my $error = Mojo::WebService::Twitter::Error->new->from_tx($tx);
 warn "$_->{code}: $_->{message}\n" for @{$error->api_errors};
 die $error->to_string;

=head1 DESCRIPTION

L<Mojo::WebService::Twitter::Error> is a container for
L<API errors|https://dev.twitter.com/overview/api/response-codes> received from
the Twitter API via L<Mojo::WebService::Twitter>.

=head1 FUNCTIONS

L<Mojo::WebService::Twitter::Error> exports the following functions on demand.

=head2 twitter_tx_error

 my $error = twitter_tx_error($tx);

Creates a new L<Mojo::WebService::Twitter::Error> and populates it using
L</"from_tx">.

=head1 ATTRIBUTES

L<Mojo::WebService::Twitter::Error> implements the following attributes.

=head2 api_errors

 my $errors = $error->api_errors;
 $error     = $error->api_errors([{code => 215, message => 'Bad Authentication data.'}]);

Arrayref of error codes and messages received from the Twitter API.

=head2 connection_error

 my $message = $error->connection_error;
 $error      = $error->connection_error('Inactivity timeout');

Connection error if any.

=head2 http_status

 my $status = $error->http_status;
 $error     = $error->http_status(404);

HTTP status code returned by Twitter API.

=head2 http_message

 my $message = $error->http_message;
 $error      = $error->http_message('Not Found');

HTTP status message returned by Twitter API.

=head1 METHODS

L<Mojo::WebService::Twitter::Error> inherits all methods from L<Mojo::Base>,
and implements the following new ones.

=head2 from_tx

 $error = $error->from_tx($tx);

Load connection, API, and HTTP error data from transaction.

=head2 to_string

 my $string = $error->to_string;

String representation of connection, API, or HTTP error.

=head1 OPERATORS

L<Mojo::WebService::Twitter::Error> overloads the following operators.

=head2 bool

Always true.

=head2 stringify

Alias for L</"to_string">.

=head1 BUGS

Report any issues on the public bugtracker.

=head1 AUTHOR

Dan Book <dbook@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Dan Book.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=head1 SEE ALSO

L<Mojo::WebService::Twitter>
