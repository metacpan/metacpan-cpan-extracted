use strict;
use warnings;

use HTTP::Request;
use Plack::App::Env;
use Plack::Test;
use Test::More 'tests' => 4;
use Test::NoWarnings;

# Test.
my $app = Plack::App::Env->new;
my $test = Plack::Test->create($app);
my $res = $test->request(HTTP::Request->new(GET => '/'));
my $ret = $res->content;
like($ret, qr{QUERY_STRING}, 'QUERY_STRING is present.');
like($ret, qr{PATH_INFO}, 'PATH_INFO is present.');
like($ret, qr{HTTP_HOST}, 'HTTP_HOST is present.');
