use strict;
use warnings;

use CSS::Struct::Output::Indent;
use HTTP::Request;
use Plack::App::Login;
use Plack::Test;
use Tags::Output::Indent;
use Test::More 'tests' => 4;
use Test::NoWarnings;

# Test.
my $app = Plack::App::Login->new;
my $test = Plack::Test->create($app);
my $res = $test->request(HTTP::Request->new(GET => '/'));
my $right_ret = <<'END';
<!DOCTYPE html>
<html lang="en"><head><meta http-equiv="Content-Type" content="text/html; charset=UTF-8" /><meta name="generator" content="Login" /><title>Login page</title><style type="text/css">.outer{position:fixed;top:50%;left:50%;transform:translate(-50%, -50%);}.login{text-align:center;background-color:blue;padding:1em;}.login a{text-decoration:none;color:white;font-size:3em;}
</style></head><body class="outer"><div class="login"><a href="login">LOGIN</a></div></body></html>
END
chomp $right_ret;
my $ret = $res->content;
is($ret, $right_ret, 'Get default main page in raw mode.');

# Test.
$app = Plack::App::Login->new(
	'css' => CSS::Struct::Output::Indent->new,
	'tags' => Tags::Output::Indent->new(
		'preserved' => ['style'],
		'xml' => 1,
	),
);
$test = Plack::Test->create($app);
$res = $test->request(HTTP::Request->new(GET => '/'));
$right_ret = <<'END';
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
    <meta name="generator" content="Login" />
    <title>
      Login page
    </title>
    <style type="text/css">
.outer {
	position: fixed;
	top: 50%;
	left: 50%;
	transform: translate(-50%, -50%);
}
.login {
	text-align: center;
	background-color: blue;
	padding: 1em;
}
.login a {
	text-decoration: none;
	color: white;
	font-size: 3em;
}
</style>
  </head>
  <body class="outer">
    <div class="login">
      <a href="login">
        LOGIN
      </a>
    </div>
  </body>
</html>
END
chomp $right_ret;
$ret = $res->content;
is($ret, $right_ret, 'Get default main page in indent mode.');

# Test.
$app = Plack::App::Login->new(
	'css' => CSS::Struct::Output::Indent->new,
	'generator' => 'Foo',
	'login_link' => 'https://example.com',
	'login_title' => 'Bar',
	'tags' => Tags::Output::Indent->new(
		'preserved' => ['style'],
		'xml' => 1,
	),
	'title' => 'Foo',
);
$test = Plack::Test->create($app);
$res = $test->request(HTTP::Request->new(GET => '/'));
$right_ret = <<'END';
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
    <meta name="generator" content="Foo" />
    <title>
      Foo
    </title>
    <style type="text/css">
.outer {
	position: fixed;
	top: 50%;
	left: 50%;
	transform: translate(-50%, -50%);
}
.login {
	text-align: center;
	background-color: blue;
	padding: 1em;
}
.login a {
	text-decoration: none;
	color: white;
	font-size: 3em;
}
</style>
  </head>
  <body class="outer">
    <div class="login">
      <a href="https://example.com">
        Bar
      </a>
    </div>
  </body>
</html>
END
chomp $right_ret;
$ret = $res->content;
is($ret, $right_ret, 'Get main page with changed values.');
