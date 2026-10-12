use Test2::V0;
use Test2::Tools::Compare qw(number_gt);
use PAGI::App::GoldenCage;
use PAGI::Test::Client;
use Encode qw(encode);
use Gzip::Faster;
use HTTP::Response;

use utf8;

################################################################################
# This tests whether the system works with fake user agent
################################################################################

sub is_status
{
	my ($res, $wanted, $name) = @_;

	is $res->status, $wanted, $name;
	if ($res->status != $wanted) {
		diag $res->exception;
	}
}

my $text = encode 'UTF-8', 'ala ma kota a kot ma alę';
my @responses = (
	HTTP::Response->new(200, 'OK', ['Content-Encoding', 'gzip'], gzip $text),
	HTTP::Response->new(200, 'OK', [], $text),
);

my @sizes;
my $app = PAGI::App::GoldenCage->new(
	ua => Fake::UA->new(responses => \@responses),
	base_url => '/test',
	logger => sub { push @sizes, shift },
);

my $client = PAGI::Test::Client->new(
	app => $app->to_app,
	lifespan => 1,
);
my $link = $app->generate_link;
like $link, qr{/test/[0-9a-f-]{36}}, 'link ok';

$client->start;

my $res = $client->get($link);
is_status $res, 200, 'code ok';
is $res->header('Content-Type'), 'text/html', 'content-type ok';
is $res->header('Content-Length'), number_gt(length $text), 'content-length ok';
like $res->content, qr{\Q<code>$text</code>\E}, 'content snippet ok';

undef $link;
if ($res->content =~ m{<a href="([^"]+)">}) {
	my $new_link = $1;
	isnt $link, $new_link, 'new link generated ok';
	$link = $new_link;
}
else {
	fail 'no link in content';
}

bail_out 'no link found in the html page'
	unless defined $link;

$res = $client->get($link);
is_status $res, 200, 'code ok';
like $res->content, qr{\Q<code>$text</code>\E}, 'content snippet ok';

is \@sizes, [length $text, length $text], 'logger ok';

done_testing;

package Fake::UA
{
	use parent 'Net::Async::HTTP';
	use Future;

	sub new
	{
		my ($class, %args) = @_;

		# requires 'responses' (aref of HTTP::Response)
		return bless {%args}, $class;
	}

	sub do_request
	{
		my ($self) = @_;

		return Future->done(shift @{$self->{responses}});
	}
}

