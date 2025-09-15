use strict;
use warnings;

use File::Object;
use HTTP::Request::Common;
use Plack::App::Tags::HTML;
use Plack::Test;
use Test::More 'tests' => 7;
use Test::NoWarnings;

unshift @INC, File::Object->new->up->dir('lib')->s;

# Test.
my $app = Plack::App::Tags::HTML->new(
	'component' => 'HelloConstructorArg',
);
test_psgi($app, sub {
	my $cb = shift;

	my $res = $cb->(GET "/");
	is($res->code, 200, 'HTTP code (200).');
	is($res->header('Content-Type'), 'text/html; charset=utf-8', 'Content type (HTML).');
	my $right_content = <<'END';
<!DOCTYPE html>
<html lang="en"><head><meta http-equiv="Content-Type" content="text/html; charset=utf-8" /><meta name="viewport" content="width=device-width, initial-scale=1.0" /><style type="text/css">
*{box-sizing:border-box;margin:0;padding:0;}
</style></head><body>Hello world</body></html>
END
	chomp $right_content;
	is($res->content, $right_content, 'Content (hello world html page).');
});

# Test.
$app = Plack::App::Tags::HTML->new(
	'component' => 'HelloConstructorArg',
	'constructor_args' => {
		'cb_value' => sub {
			return 'Foo bar baz',
		},
	},
);
test_psgi($app, sub {
	my $cb = shift;

	my $res = $cb->(GET "/");
	is($res->code, 200, 'HTTP code (200).');
	is($res->header('Content-Type'), 'text/html; charset=utf-8', 'Content type (HTML).');
	my $right_content = <<'END';
<!DOCTYPE html>
<html lang="en"><head><meta http-equiv="Content-Type" content="text/html; charset=utf-8" /><meta name="viewport" content="width=device-width, initial-scale=1.0" /><style type="text/css">
*{box-sizing:border-box;margin:0;padding:0;}
</style></head><body>Foo bar baz</body></html>
END
	chomp $right_content;
	is($res->content, $right_content, 'Content (hello world html page with explicit value defined by constructor parameter).');
});
