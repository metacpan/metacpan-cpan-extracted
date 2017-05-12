use strict;
use warnings;

use RPC::ExtDirect::Test::Pkg::Foo;
use RPC::ExtDirect::Test::Pkg::Bar;
use RPC::ExtDirect::Test::Pkg::JuiceBar;
use RPC::ExtDirect::Test::Pkg::Qux;
use RPC::ExtDirect::Test::Pkg::PollProvider;
use RPC::ExtDirect::Test::Pkg::Meta;

use lib 't/lib';
use RPC::ExtDirect::Test::Util::Plack;
use RPC::ExtDirect::Test::Data::Router;

use Plack::Middleware::ExtDirect;

my $tests = RPC::ExtDirect::Test::Data::Router::get_tests;

run_tests($tests, @ARGV);
