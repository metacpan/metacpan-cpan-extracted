use strict;
use warnings;

use RPC::ExtDirect::Test::Pkg::Env;

use lib 't/lib';
use RPC::ExtDirect::Test::Util::Plack;
use RPC::ExtDirect::Test::Data::Env;

use Plack::Middleware::ExtDirect;

my $tests = RPC::ExtDirect::Test::Data::Env::get_tests;

run_tests($tests, @ARGV);
