use strict;
use warnings;

use Test2::V0;
use Test2::Tools::Explain;
use Test2::Tools::Subtest qw{subtest_streamed};
use Test2::Plugin::NoWarnings;
use Test::MockModule qw{strict};

use FindBin;

use lib "$FindBin::Bin/../lib";

use Net::OpenSSH::More;

subtest_streamed "Live tests versus localhost" => sub {
    plan 'skip_all' => 'AUTHOR_TESTS not set in shell environment, skipping...' if !$ENV{'AUTHOR_TESTS'};
    local %Net::OpenSSH::More::cache;
    my $obj = Net::OpenSSH::More->new( 'host' => '127.0.0.1', 'no_cache' => 1 );
    is( ref $obj, 'Net::OpenSSH::More', "Got right ref type for object upon instantiation (using IP)" );
    $obj = Net::OpenSSH::More->new(
        'host' => 'localhost', 'output_prefix' => '# ', 'use_persistent_shell' => 0, 'expect_timeout' => 1,
    );
    is( ref $obj, 'Net::OpenSSH::More', "Got right ref type for object upon instantiation (using localhost)" );
    my @cmd_ret  = $obj->cmd(qw{echo whee});
    my $expected = [ "whee", '', 0 ];
    is( \@cmd_ret, $expected, "Got expected return (non-persistent shell)" );
    $obj->use_persistent_shell(1);
    @cmd_ret = $obj->cmd(qw{echo whee});
    is( \@cmd_ret, $expected, "Got expected return (persistent shell)" );
    $obj->write( "net-openssh-more-test", "whee" );
    @cmd_ret = $obj->cmd(qw{cat net-openssh-more-test});
    is( \@cmd_ret, $expected, "Got expected result from write" );
    my $ec = $obj->cmd_exit_code(qw{rm -f net-openssh-more-test});
    is( $ec, 0, "cmd_exit_code returns 0 on successful command" );
    my $ret = $obj->eval_full( 'code' => sub { return $_[0] ? "whee" : "widdly"; }, 'args' => [1] );
    is( $ret, "whee", "Got expected result from eval_full" );
};

# Mock based testing
subtest_streamed "Common tests using mocks" => sub {
    local %Net::OpenSSH::More::cache;
    my $parent_mock = Test::MockModule->new('Net::OpenSSH');
    $parent_mock->redefine(
        'new'          => sub { bless {}, $_[0] },
        'check_master' => 1,
    );
    {
        # MockModule can't actually redefine destructors properly due to the mock also going out of scope.
        no warnings qw{redefine};
        *Net::OpenSSH::DESTROY = sub { undef };
    }
    my $obj = Net::OpenSSH::More->new( 'host' => '127.0.0.1', retry_max => 1, 'output_prefix' => '# ' );
    is( ref $obj,           'Net::OpenSSH::More', "Got right ref type for object upon instantiation" );
    is( $obj->diag("Whee"), undef,                "You should see whee before this subtest" );
};

done_testing();
