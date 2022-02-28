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

my $app = App->new(
	'flag_begin' => 0,
	'flag_end' => 0,
);
test_psgi($app, sub {
	my $cb = shift;

	my $res = $cb->(GET "/");
	is($res->code, 200, 'HTTP code (200).');
	is($res->header('Content-Type'), 'text/html; charset=utf-8', 'Content type (HTML).');
	is($res->content, '', 'Content (blank).');
});
