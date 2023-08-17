use strict;
use warnings;

use Test::More 'tests' => 4;
use Test::NoWarnings;

package App;

use base qw(Plack::Component::Tags::HTML);
use strict;
use warnings;

package main;

use HTTP::Request::Common;
use Plack::Test;

# Test.
my $app = App->new(
        'title' => 'My app',
);
$app->psgi_app(sub {
	return [
		200,
		['Content-Type' => 'text/plain'],
		['Hello World'],
	];
}->());
test_psgi($app, sub {
	my $cb = shift;

	my $res = $cb->(GET "/");
	is($res->code, 200, 'HTTP code (200).');
	is($res->header('Content-Type'), 'text/plain', 'Content type (plain).');
	is($res->content, 'Hello World', 'Content (string).');
});
