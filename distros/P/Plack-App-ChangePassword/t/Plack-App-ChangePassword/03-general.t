use strict;
use warnings;

use CSS::Struct::Output::Indent;
use HTTP::Request;
use Plack::App::ChangePassword;
use Plack::Test;
use Tags::Output::Indent;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $app = Plack::App::ChangePassword->new;
my $test = Plack::Test->create($app);
my $res = $test->request(HTTP::Request->new(GET => '/'));
my $right_ret = <<"END";
<!DOCTYPE html>
<html lang="en"><head><meta http-equiv="Content-Type" content="text/html; charset=utf-8" /><meta name="generator" content="Plack::App::ChangePassword; Version: $Plack::App::ChangePassword::VERSION" /><meta name="viewport" content="width=device-width, initial-scale=1.0" /><title>Change password page</title><style type="text/css">
*{box-sizing:border-box;margin:0;padding:0;}.form-change-password{width:300px;background-color:#f2f2f2;padding:20px;border-radius:5px;box-shadow:0 0 10px rgba(0, 0, 0, 0.2);}.form-change-password fieldset{border:none;padding:0;margin-bottom:20px;}.form-change-password legend{font-weight:bold;margin-bottom:10px;}.form-change-password p{margin:0;padding:10px 0;}.form-change-password label{display:block;font-weight:bold;margin-bottom:5px;}.form-change-password input[type="text"],.form-change-password input[type="password"]{width:100%;padding:8px;border:1px solid #ccc;border-radius:3px;}.form-change-password button[type="submit"]{width:100%;padding:10px;background-color:#4CAF50;color:#fff;border:none;border-radius:3px;cursor:pointer;}.form-change-password button[type="submit"]:hover{background-color:#45a049;}.form-change-password .messages{text-align:center;}.container{display:flex;align-items:center;justify-content:center;height:100vh;}
</style></head><body><div class="container"><div class="inner"><form class="form-change-password" method="post"><fieldset><legend>Change password</legend><p><label for="old_password">Old password</label><input type="password" name="old_password" id="old_password" autofocus="autofocus" /></p><p><label for="password1">New password</label><input type="password" name="password1" id="password1" /></p><p><label for="password2">Confirm new password</label><input type="password" name="password2" id="password2" /></p><p><button type="submit" name="change_password" value="change_password">Save Changes</button></p></fieldset></form></div></div></body></html>
END
chomp $right_ret;
my $ret = $res->content;
is($ret, $right_ret, 'Get default main page in raw mode.');

# Test.
$app = Plack::App::ChangePassword->new(
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
    <meta name="generator" content="Plack::App::ChangePassword; Version: $Plack::App::ChangePassword::VERSION"
      />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>
      Change password page
    </title>
    <style type="text/css">
* {
	box-sizing: border-box;
	margin: 0;
	padding: 0;
}
.form-change-password {
	width: 300px;
	background-color: #f2f2f2;
	padding: 20px;
	border-radius: 5px;
	box-shadow: 0 0 10px rgba(0, 0, 0, 0.2);
}
.form-change-password fieldset {
	border: none;
	padding: 0;
	margin-bottom: 20px;
}
.form-change-password legend {
	font-weight: bold;
	margin-bottom: 10px;
}
.form-change-password p {
	margin: 0;
	padding: 10px 0;
}
.form-change-password label {
	display: block;
	font-weight: bold;
	margin-bottom: 5px;
}
.form-change-password input[type="text"], .form-change-password input[type="password"] {
	width: 100%;
	padding: 8px;
	border: 1px solid #ccc;
	border-radius: 3px;
}
.form-change-password button[type="submit"] {
	width: 100%;
	padding: 10px;
	background-color: #4CAF50;
	color: #fff;
	border: none;
	border-radius: 3px;
	cursor: pointer;
}
.form-change-password button[type="submit"]:hover {
	background-color: #45a049;
}
.form-change-password .messages {
	text-align: center;
}
.container {
	display: flex;
	align-items: center;
	justify-content: center;
	height: 100vh;
}
</style>
  </head>
  <body>
    <div class="container">
      <div class="inner">
        <form class="form-change-password" method="post">
          <fieldset>
            <legend>
              Change password
            </legend>
            <p>
              <label for="old_password">
                Old password
              </label>
              <input type="password" name="old_password" id="old_password"
                autofocus="autofocus" />
            </p>
            <p>
              <label for="password1">
                New password
              </label>
              <input type="password" name="password1" id="password1" />
            </p>
            <p>
              <label for="password2">
                Confirm new password
              </label>
              <input type="password" name="password2" id="password2" />
            </p>
            <p>
              <button type="submit" name="change_password" value=
                "change_password">
                Save Changes
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
