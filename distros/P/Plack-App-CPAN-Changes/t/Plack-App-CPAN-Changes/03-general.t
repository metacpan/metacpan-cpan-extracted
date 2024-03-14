use strict;
use warnings;

use CPAN::Changes;
use CSS::Struct::Output::Indent;
use HTTP::Request;
use Plack::App::CPAN::Changes;
use Plack::Test;
use Tags::Output::Indent;
use Test::More 'tests' => 5;
use Test::NoWarnings;

# Common.
my $changes = CPAN::Changes->new(
        'preamble' => 'Revision history for perl module Foo::Bar',
);

# Test.
my $app = Plack::App::CPAN::Changes->new(
	'changes' => $changes,
);
my $test = Plack::Test->create($app);
my $res = $test->request(HTTP::Request->new(GET => '/'));
my $right_ret = <<"END";
<!DOCTYPE html>
<html lang="en"><head><meta http-equiv="Content-Type" content="text/html; charset=utf-8" /><meta name="generator" content="Plack::App::CPAN::Changes; Version: $Plack::App::CPAN::Changes::VERSION" /><meta name="viewport" content="width=device-width, initial-scale=1.0" /><title>Changes</title><style type="text/css">
*{box-sizing:border-box;margin:0;padding:0;}.changes{max-width:800px;margin:auto;background:#fff;padding:20px;border-radius:8px;box-shadow:0 2px 4px rgba(0, 0, 0, 0.1);}.changes .version{border-bottom:2px solid #eee;padding-bottom:20px;margin-bottom:20px;}.changes .version:last-child{border-bottom:none;}.changes .version h2,.changes .version h3{color:#007BFF;margin-top:0;}.changes .version-changes{list-style-type:none;padding-left:0;}.changes .version-change{background-color:#f8f9fa;margin:10px 0;padding:10px;border-left:4px solid #007BFF;border-radius:4px;}
</style></head><body><div class="changes"><h1>Revision history for perl module Foo::Bar</h1></div></body></html>
END
chomp $right_ret;
my $ret = $res->content;
is($ret, $right_ret, 'Get page with simple changes in raw mode.');

# Test.
$app = Plack::App::CPAN::Changes->new(
	'changes' => $changes,
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
    <meta name="generator" content="Plack::App::CPAN::Changes; Version: $Plack::App::CPAN::Changes::VERSION"
      />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>
      Changes
    </title>
    <style type="text/css">
* {
	box-sizing: border-box;
	margin: 0;
	padding: 0;
}
.changes {
	max-width: 800px;
	margin: auto;
	background: #fff;
	padding: 20px;
	border-radius: 8px;
	box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
}
.changes .version {
	border-bottom: 2px solid #eee;
	padding-bottom: 20px;
	margin-bottom: 20px;
}
.changes .version:last-child {
	border-bottom: none;
}
.changes .version h2, .changes .version h3 {
	color: #007BFF;
	margin-top: 0;
}
.changes .version-changes {
	list-style-type: none;
	padding-left: 0;
}
.changes .version-change {
	background-color: #f8f9fa;
	margin: 10px 0;
	padding: 10px;
	border-left: 4px solid #007BFF;
	border-radius: 4px;
}
</style>
  </head>
  <body>
    <div class="changes">
      <h1>
        Revision history for perl module Foo::Bar
      </h1>
    </div>
  </body>
</html>
END
chomp $right_ret;
$ret = $res->content;
is($ret, $right_ret, 'Get page with simple changes in indent mode.');

# Test.
$app = Plack::App::CPAN::Changes->new(
	'changes' => $changes,
	'css' => CSS::Struct::Output::Indent->new,
	'generator' => 'Foo',
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
.changes {
	max-width: 800px;
	margin: auto;
	background: #fff;
	padding: 20px;
	border-radius: 8px;
	box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
}
.changes .version {
	border-bottom: 2px solid #eee;
	padding-bottom: 20px;
	margin-bottom: 20px;
}
.changes .version:last-child {
	border-bottom: none;
}
.changes .version h2, .changes .version h3 {
	color: #007BFF;
	margin-top: 0;
}
.changes .version-changes {
	list-style-type: none;
	padding-left: 0;
}
.changes .version-change {
	background-color: #f8f9fa;
	margin: 10px 0;
	padding: 10px;
	border-left: 4px solid #007BFF;
	border-radius: 4px;
}
</style>
  </head>
  <body>
    <div class="changes">
      <h1>
        Revision history for perl module Foo::Bar
      </h1>
    </div>
  </body>
</html>
END
chomp $right_ret;
$ret = $res->content;
is($ret, $right_ret, 'Get page with simple changes and with changed values.');

# Test.
$app = Plack::App::CPAN::Changes->new(
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
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
    <meta name="generator" content="Plack::App::CPAN::Changes; Version: 0.01"
      />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>
      Changes
    </title>
    <style type="text/css">
* {
	box-sizing: border-box;
	margin: 0;
	padding: 0;
}
</style>
  </head>
  <body />
</html>
END
chomp $right_ret;
$ret = $res->content;
is($ret, $right_ret, 'Get page without init.');
