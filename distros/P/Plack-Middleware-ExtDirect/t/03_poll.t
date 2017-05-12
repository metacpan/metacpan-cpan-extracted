use strict;
use warnings;

use RPC::ExtDirect::Test::Pkg::PollProvider;

use lib 't/lib';
use RPC::ExtDirect::Test::Util::Plack;
use RPC::ExtDirect::Test::Data::Poll;

use Plack::Middleware::ExtDirect;

my $tests = RPC::ExtDirect::Test::Data::Poll::get_tests;

run_tests($tests, @ARGV);
