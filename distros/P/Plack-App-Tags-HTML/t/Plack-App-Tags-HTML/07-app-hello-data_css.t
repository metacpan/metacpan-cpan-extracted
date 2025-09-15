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
	'component' => 'HelloCSS',
	'data' => ['Hello world'],
	'data_css' => [
		['s', 'div'],
		['d', 'font-size', '1em'],
		['e'],
	],
);
test_psgi($app, sub {
	my $cb = shift;

	my $res = $cb->(GET "/");
	is($res->code, 200, 'HTTP code (200).');
	is($res->header('Content-Type'), 'text/html; charset=utf-8', 'Content type (HTML).');
	my $right_content = <<'END';
<!DOCTYPE html>
<html lang="en"><head><meta http-equiv="Content-Type" content="text/html; charset=utf-8" /><meta name="viewport" content="width=device-width, initial-scale=1.0" /><style type="text/css">
*{box-sizing:border-box;margin:0;padding:0;}.foo{border:1px solid red;}div{font-size:1em;}
</style></head><body><div class="foo">Hello world</div></body></html>
END
	chomp $right_content;
	is($res->content, $right_content, 'Content (hello world html page and explicit CSS data).');
});
