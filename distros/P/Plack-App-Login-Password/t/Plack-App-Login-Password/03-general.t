use strict;
use warnings;

use CSS::Struct::Output::Indent;
use HTTP::Request;
use Plack::App::Login::Password;
use Plack::Test;
use Tags::Output::Indent;
use Test::More 'tests' => 4;
use Test::NoWarnings;

# Test.
my $app = Plack::App::Login::Password->new(
	'generator' => 'Plack::App::Login::Password',
);
my $test = Plack::Test->create($app);
my $res = $test->request(HTTP::Request->new(GET => '/'));
my $right_ret = <<"END";
<!DOCTYPE html>
<html lang="en"><head><meta http-equiv="Content-Type" content="text/html; charset=utf-8" /><meta name="generator" content="Plack::App::Login::Password" /><meta name="viewport" content="width=device-width, initial-scale=1.0" /><title>Login page</title><style type="text/css">
*{box-sizing:border-box;margin:0;padding:0;}.container{display:flex;align-items:center;justify-content:center;height:100vh;}.form-login{width:300px;background-color:#f2f2f2;padding:20px;border-radius:5px;box-shadow:0 0 10px rgba(0, 0, 0, 0.2);}.form-login .logo{height:5em;width:100%;}.form-login img{margin:auto;display:block;max-width:100%;max-height:5em;}.form-login fieldset{border:none;padding:0;margin-bottom:20px;}.form-login legend{font-weight:bold;margin-bottom:10px;}.form-login p{margin:0;padding:10px 0;}.form-login label{display:block;font-weight:bold;margin-bottom:5px;}.form-login input[type="text"],.form-login input[type="password"]{width:100%;padding:8px;border:1px solid #ccc;border-radius:3px;}.form-login button[type="submit"]{width:100%;padding:10px;background-color:#4CAF50;color:#fff;border:none;border-radius:3px;cursor:pointer;}.form-login button[type="submit"]:hover{background-color:#45a049;}.form-login .messages{text-align:center;}.error{color:red;}.info{color:blue;}
</style></head><body><div class="container"><div class="inner"><form class="form-login" method="post"><fieldset><legend>Login</legend><p><label for="username" />User name<input type="text" name="username" id="username" autofocus="autofocus" /></p><p><label for="password">Password</label><input type="password" name="password" id="password" /></p><p><button type="submit" name="login" value="login">Login</button></p></fieldset></form></div></div></body></html>
END
chomp $right_ret;
my $ret = $res->content;
is($ret, $right_ret, 'Get default main page in raw mode.');

# Test.
$app = Plack::App::Login::Password->new(
	'css' => CSS::Struct::Output::Indent->new,
	'generator' => 'Plack::App::Login::Password',
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
    <meta name="generator" content="Plack::App::Login::Password" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>
      Login page
    </title>
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
.form-login {
	width: 300px;
	background-color: #f2f2f2;
	padding: 20px;
	border-radius: 5px;
	box-shadow: 0 0 10px rgba(0, 0, 0, 0.2);
}
.form-login .logo {
	height: 5em;
	width: 100%;
}
.form-login img {
	margin: auto;
	display: block;
	max-width: 100%;
	max-height: 5em;
}
.form-login fieldset {
	border: none;
	padding: 0;
	margin-bottom: 20px;
}
.form-login legend {
	font-weight: bold;
	margin-bottom: 10px;
}
.form-login p {
	margin: 0;
	padding: 10px 0;
}
.form-login label {
	display: block;
	font-weight: bold;
	margin-bottom: 5px;
}
.form-login input[type="text"], .form-login input[type="password"] {
	width: 100%;
	padding: 8px;
	border: 1px solid #ccc;
	border-radius: 3px;
}
.form-login button[type="submit"] {
	width: 100%;
	padding: 10px;
	background-color: #4CAF50;
	color: #fff;
	border: none;
	border-radius: 3px;
	cursor: pointer;
}
.form-login button[type="submit"]:hover {
	background-color: #45a049;
}
.form-login .messages {
	text-align: center;
}
.error {
	color: red;
}
.info {
	color: blue;
}
</style>
  </head>
  <body>
    <div class="container">
      <div class="inner">
        <form class="form-login" method="post">
          <fieldset>
            <legend>
              Login
            </legend>
            <p>
              <label for="username" />
              User name
              <input type="text" name="username" id="username" autofocus=
                "autofocus" />
            </p>
            <p>
              <label for="password">
                Password
              </label>
              <input type="password" name="password" id="password" />
            </p>
            <p>
              <button type="submit" name="login" value="login">
                Login
              </button>
            </p>
          </fieldset>
        </form>
      </div>
    </div>
  </body>
</html>
END
chomp $right_ret;
$ret = $res->content;
is($ret, $right_ret, 'Get default main page in indent mode.');

# Test.
$app = Plack::App::Login::Password->new(
	'css' => CSS::Struct::Output::Indent->new,
	'generator' => 'Foo',
	'register_link' => '/register',
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
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
    <meta name="generator" content="Foo" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>
      Foo
    </title>
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
.form-login {
	width: 300px;
	background-color: #f2f2f2;
	padding: 20px;
	border-radius: 5px;
	box-shadow: 0 0 10px rgba(0, 0, 0, 0.2);
}
.form-login .logo {
	height: 5em;
	width: 100%;
}
.form-login img {
	margin: auto;
	display: block;
	max-width: 100%;
	max-height: 5em;
}
.form-login fieldset {
	border: none;
	padding: 0;
	margin-bottom: 20px;
}
.form-login legend {
	font-weight: bold;
	margin-bottom: 10px;
}
.form-login p {
	margin: 0;
	padding: 10px 0;
}
.form-login label {
	display: block;
	font-weight: bold;
	margin-bottom: 5px;
}
.form-login input[type="text"], .form-login input[type="password"] {
	width: 100%;
	padding: 8px;
	border: 1px solid #ccc;
	border-radius: 3px;
}
.form-login button[type="submit"] {
	width: 100%;
	padding: 10px;
	background-color: #4CAF50;
	color: #fff;
	border: none;
	border-radius: 3px;
	cursor: pointer;
}
.form-login button[type="submit"]:hover {
	background-color: #45a049;
}
.form-login .messages {
	text-align: center;
}
.error {
	color: red;
}
.info {
	color: blue;
}
</style>
  </head>
  <body>
    <div class="container">
      <div class="inner">
        <form class="form-login" method="post">
          <fieldset>
            <legend>
              Login
            </legend>
            <p>
              <label for="username" />
              User name
              <input type="text" name="username" id="username" autofocus=
                "autofocus" />
            </p>
            <p>
              <label for="password">
                Password
              </label>
              <input type="password" name="password" id="password" />
            </p>
            <p>
              <button type="submit" name="login" value="login">
                Login
              </button>
            </p>
            <a href="/register">
              Register
            </a>
          </fieldset>
        </form>
      </div>
    </div>
  </body>
</html>
END
chomp $right_ret;
$ret = $res->content;
is($ret, $right_ret, 'Get main page with changed values.');
