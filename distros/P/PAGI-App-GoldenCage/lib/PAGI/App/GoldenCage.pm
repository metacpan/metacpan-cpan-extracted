package PAGI::App::GoldenCage;
$PAGI::App::GoldenCage::VERSION = '0.001';
use v5.18;
use warnings;

use Net::Async::HTTP;
use Future::AsyncAwait;
use Gzip::Faster;
use UUID qw(uuid4);

# Hell, rationality itself - the exalted Human ability to reason - hadn’t
# evolved in the pursuit of truth but simply to win arguments, to gain control:
# to bend others, by means logical or sophistic, to your will.
# -- Peter Watts, Echopraxia

use constant FOUNTAIN_URL => 'https://RNSAFFN.com/poison2/';
use constant PAGE_HTML => <<HTML =~ s{[\t\v]}{}gr;
<html>
	<head>
		<title>GC code preview</title>
	</head>
	<body>
		<code>%s</code>
		<a href="%s">Next Page</a>
	</body>
</html>
HTML

sub new
{
	my ($class, %args) = @_;

	return bless {
		ua => $args{ua} // Net::Async::HTTP->new,
		fountain_url => $args{fountain_url} // FOUNTAIN_URL,
		base_url => $args{base_url} // '',
		logger => $args{logger},
	}, $class;
}

sub ua
{
	return $_[0]->{ua};
}

sub fountain_url
{
	return $_[0]->{fountain_url};
}

sub base_url
{
	return $_[0]->{base_url};
}

sub logger
{
	return $_[0]->{logger};
}

sub generate_link
{
	my ($self) = @_;

	return $self->base_url . '/' . uuid4;
}

async sub call
{
	my ($self, $scope, $receive, $send) = @_;

	die "Unsupported scope type: $scope->{type}" if $scope->{type} ne 'http';

	my $response = await $self->ua->do_request(uri => $self->fountain_url);
	die sprintf 'Error fetching response from the fountain: [%s] %s', (
		$response->code,
		$response->content
	) unless $response->is_success;

	my $poisoned = $response->content;
	if (lc($response->header('Content-Encoding') // '') eq 'gzip') {
		$poisoned = gunzip $poisoned;
	}

	my $html = sprintf PAGE_HTML, $poisoned, $self->generate_link;

	await $send->(
		{
			type => 'http.response.start',
			status => 200,
			headers => [
				['content-type', 'text/html'],
				['content-length', length $html],
			],
		}
	);

	await $send->({type => 'http.response.body', body => $html, more => 0});

	if (my $logger = $self->logger) {
		$logger->(length $poisoned);
	}
}

sub to_app
{
	my ($self) = @_;

	my $loop = IO::Async::Loop->new;
	$loop->add($self->ua);

	return sub { $self->call(@_) };
}

1;

__END__

=head1 NAME

PAGI::App::GoldenCage - Trap bots and serve them poisoned data

=head1 SYNOPSIS

	use PAGI::App::GoldenCage;

	my $app = PAGI::App::GoldenCage->new;
	$app->to_app;

=head1 DESCRIPTION

Golden Cage traps scrapping bots on your website with a never-ending stream of
data that is harmful to AIs.

This PAGI application is inspired by
L<miasma|https://github.com/austin-weeks/miasma> - it sets up a location on
your webserver which serves poisoned data to bots via the L<Poison
Fountain|https://rnsaffn.com/poison3/> and generates a link back to itself with
a new UUID. This way scrappers should continously scrap poisoned data, harming
the training of AIs.

Since it's written as a PAGI application, it should be very easy to add this to
existing PAGI systems, and the requests to the fountain are made
asynchronously. The computational cost of serving every request should be
pretty low, as the application simply gunzips the fetched data and serves a
page with it as well as the new link.

For best effect, every page on your site should contain a link to the Golden
Cage, in a way that does not concern human viewers.

=head1 INTERFACE

=head2 Attributes

=head3 ua

An optional user agent - should be a class of L<Net::Async::HTTP>. If not
provided, it will be constructed with default configuration.

=head3 fountain_url

An optional link to the Poison Fountain. If not provided,
C<https://RNSAFFN.com/poison2/> will be used.

=head3 base_url

An optional location to the Golden Cage page. If not provided, it will be set
to C</>. It affects the result of L</generate_link>.

=head3 logger

An optional sub that gets called each time a Golden Cage page is hit. It passes
a single argument to the subroutine, which is the amount of poison served in
bytes.

=head2 Methods

=head3 new

	$app = $class->new(%args)

A standard hash-based constructor. See L</Attributes> to learn what C<%args> can be used.

=head3 generate_link

	$string = $app->generate_link()

Generates a new link to the Golden Cage. Link is generated using UUIDv4, so it
will be completely random and unique.

=head3 to_app

	$subref = $app->to_app()

Returns a PAGI-compilant application, ready to be run by the server or mounted
inside PAGI stack.

=head1 AUTHOR

Bartosz Jarzyna E<lt>bbrtj.pro@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 by Bartosz Jarzyna

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

