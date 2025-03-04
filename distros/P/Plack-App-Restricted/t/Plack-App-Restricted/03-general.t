use strict;
use warnings;

use CSS::Struct::Output::Indent;
use HTTP::Request;
use Plack::App::Restricted;
use Plack::Test;
use Tags::Output::Indent;
use Test::More 'tests' => 4;
use Test::NoWarnings;

# Test.
my $app = Plack::App::Restricted->new;
my $test = Plack::Test->create($app);
my $res = $test->request(HTTP::Request->new(GET => '/'));
my $right_ret = <<"END";
<!DOCTYPE html>
<html lang="en"><head><meta http-equiv="Content-Type" content="text/html; charset=utf-8" /><meta name="viewport" content="width=device-width, initial-scale=1.0" /><style type="text/css">
*{box-sizing:border-box;margin:0;padding:0;}.container{display:flex;align-items:center;justify-content:center;height:100vh;}.restricted{color:red;font-family:sans-serif;font-size:3em;}
</style></head><body><div class="container"><div class="inner"><div class="restricted">Restricted access</div></div></div></body></html>
END
chomp $right_ret;
my $ret = $res->content;
is($ret, $right_ret, 'Get default main page in raw mode.');

# Test.
$app = Plack::App::Restricted->new(
	'css' => CSS::Struct::Output::Indent->new,
	'tags' => Tags::Output::Indent->new(
		'preserved' => ['style'],
		'xml' => 1,
	),
);
$test = Plack::Test->create($app);
$res = $test->request(HTTP::Request->new(GET => '/'));
$right_ret = <<"END";
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <style type="text/css">
* {
	box-sizing: border-box;
	margin: 0;
	padding: 0;
}
.container {
	display: flex;
	align-items: center;
	justify-content: center;
	height: 100vh;
}
.restricted {
	color: red;
	font-family: sans-serif;
	font-size: 3em;
}
</style>
  </head>
  <body>
    <div class="container">
      <div class="inner">
        <div class="restricted">
          Restricted access
        </div>
      </div>
    </div>
  </body>
</html>
END
chomp $right_ret;
$ret = $res->content;
is($ret, $right_ret, 'Get default main page in indent mode.');

# Test.
$app = Plack::App::Restricted->new(
	'css' => CSS::Struct::Output::Indent->new,
	'label' => 'Page is restricted',
	'tags' => Tags::Output::Indent->new(
		'preserved' => ['style'],
		'xml' => 1,
	),
);
$test = Plack::Test->create($app);
$res = $test->request(HTTP::Request->new(GET => '/'));
$right_ret = <<"END";
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <style type="text/css">
* {
	box-sizing: border-box;
	margin: 0;
	padding: 0;
}
.container {
	display: flex;
	align-items: center;
	justify-content: center;
	height: 100vh;
}
.restricted {
	color: red;
	font-family: sans-serif;
	font-size: 3em;
}
</style>
  </head>
  <body>
    <div class="container">
      <div class="inner">
        <div class="restricted">
          Page is restricted
        </div>
      </div>
    </div>
  </body>
</html>
END
chomp $right_ret;
$ret = $res->content;
is($ret, $right_ret, 'Get default main page in indent mode (explicit restricted text).');
