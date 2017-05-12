use MooseX::Declare;
use FindBin;
use lib "$FindBin::Bin/lib";
use warnings;
use strict;
use Test::More;
use Plack::Test::Suite;

Plack::Test::Suite->run_server_tests('+MyTester');
done_testing;
