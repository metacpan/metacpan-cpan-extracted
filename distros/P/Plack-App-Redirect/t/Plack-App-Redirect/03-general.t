use strict;
use warnings;

use HTTP::Request;
use Plack::App::Redirect;
use Plack::Test;
use Test::More 'tests' => 5;
use Test::NoWarnings;

# Test.
my $app = Plack::App::Redirect->new;
my $test = Plack::Test->create($app);
my $res = $test->request(HTTP::Request->new(GET => '/'));
my $right_ret = <<"END";
No redirect.
END
chomp $right_ret;
my $ret = $res->content;
is($ret, $right_ret, 'No redirect.');

# Test.
$app = Plack::App::Redirect->new(
	'redirect_url' => 'https://skim.cz',
);
$test = Plack::Test->create($app);
$res = $test->request(HTTP::Request->new(GET => '/'));
$ret = $res->content;
is($ret, '', "Redirect content ('').");
is($res->code, 308, 'Redirect HTTP code (308).');
is($res->header('Location'), 'https://skim.cz/', 'Redirect location (https://skim.cz).');
