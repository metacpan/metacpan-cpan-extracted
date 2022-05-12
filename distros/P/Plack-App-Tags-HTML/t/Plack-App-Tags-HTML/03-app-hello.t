use strict;
use warnings;

use File::Object;
use HTTP::Request::Common;
use Plack::App::Tags::HTML;
use Plack::Test;
use Test::More 'tests' => 4;
use Test::NoWarnings;

unshift @INC, File::Object->new->up->dir('lib')->s;

# Test.
my $app = Plack::App::Tags::HTML->new(
	'component' => 'Hello',
);
test_psgi($app, sub {
	my $cb = shift;

	my $res = $cb->(GET "/");
	is($res->code, 200, 'HTTP code (200).');
	is($res->header('Content-Type'), 'text/html; charset=utf-8', 'Content type (HTML).');
	my $right_content = <<'END';
<!DOCTYPE html>
<html lang="en"><head><meta http-equiv="Content-Type" content="text/html; charset=utf-8" /></head><body>Hello world</body></html>
END
	chomp $right_content;
	is($res->content, $right_content, 'Content (hello world html page).');
});
