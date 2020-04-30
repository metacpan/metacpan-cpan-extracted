use strict;
use warnings;

use File::Object;
use Plack::App::Directory::PYX;
use Plack::Test;
use Test::More 'tests' => 6;
use Test::NoWarnings;

# Directories.
my $data_dir = File::Object->new->up->dir('data')->dir('root')->set;

# Test.
my $app = Plack::App::Directory::PYX->new('root' => $data_dir->s);
my $test = Plack::Test->create($app);
my $res = $test->request(HTTP::Request->new(GET => '/ex1.pyx'));
is($res->content,
	'<html><head><title>title</title></head><body><div>Example #1</div></body></html>',
	'Get content of ex1.pyx page.');

# Test.
$res = $test->request(HTTP::Request->new(GET => '/ex2.pyx'));
is($res->content,
	'<html><head><title>title</title></head><body><div>Example #2</div></body></html>',
	'Get content of ex2.pyx page.');

# Test.
$res = $test->request(HTTP::Request->new(GET => '/'));
is($res->content, 'DIR', 'Get content of directory index.');

# Test.
$app = Plack::App::Directory::PYX->new(
	'indent' => 1,
	'root' => $data_dir->s,
);
$test = Plack::Test->create($app);
$res = $test->request(HTTP::Request->new(GET => '/ex1.pyx'));
my $right_ret = <<'END';
<html>
  <head>
    <title>
      title
    </title>
  </head>
  <body>
    <div>
      Example #1
    </div>
  </body>
</html>
END
chomp $right_ret;
is($res->content,
	$right_ret,
	'Get content of ex1.pyx page in indent mode (version with directory).');

# Test.
$app = Plack::App::Directory::PYX->new(
	'file' => $data_dir->file('ex1.pyx')->s,
	'indent' => 1,
);
$test = Plack::Test->create($app);
$res = $test->request(HTTP::Request->new(GET => '/'));
$right_ret = <<'END';
<html>
  <head>
    <title>
      title
    </title>
  </head>
  <body>
    <div>
      Example #1
    </div>
  </body>
</html>
END
chomp $right_ret;
is($res->content,
	$right_ret,
	'Get content of ex1.pyx page in indent mode (version with one file).');
