use strict;
use warnings;

use Test2::V0;
use Test2::Tools::Explain;
use Test2::Tools::Subtest qw{subtest_streamed};
use Test2::Plugin::NoWarnings;
use Test::MockModule qw{strict};

use FindBin;

use lib "$FindBin::Bin/../lib";

use Net::OpenSSH::More::Linux;

subtest_streamed "Live tests versus localhost" => sub {
    plan 'skip_all' => 'AUTHOR_TESTS not set in shell environment, skipping...' if !$ENV{'AUTHOR_TESTS'};
    local %Net::OpenSSH::More::cache;
    my $obj = Net::OpenSSH::More::Linux->new(
        'host' => '127.0.0.1', 'output_prefix' => '# ', 'retry_max' => 1,
    );
    is( ref $obj, 'Net::OpenSSH::More::Linux', "Got right ref type for object upon instantiation (using localhost)" );
    my $adapter = $obj->get_primary_adapter(1);
    ok( $adapter, "Got something back as the primary adapter (use_local)" );
    is( $obj->get_primary_adapter(), $adapter, "Got expected adapter (remote)" );

    # Test backup/restore, first with existing
    $obj->cmd(qw{touch /tmp/howdy});
    $obj->backup_files('/tmp/howdy');
    $obj->cmd(qw{rm -f /tmp/howdy});
    $obj->restore_files();
    ok( $obj->sftp->test_e('/tmp/howdy'), "Created /tmp/howdy file restored via backup/restore methods" );
    $obj->cmd(qw{rm -f /tmp/howdy});

    # "Backup" non-existing file
    $obj->backup_files('/tmp/yeehaw');
    $obj->cmd(qw{touch /tmp/yeehaw});
    ok( $obj->sftp->test_e('/tmp/yeehaw'), "Created /tmp/yeehaw touch file for testing backup/restore" );
    $obj->DESTROY();
    $obj = Net::OpenSSH::More::Linux->new(
        'host' => 'localhost', 'use_persistent_shell' => 0, 'retry_max' => 1,
    );
    ok( !$obj->sftp->test_e('/tmp/yeehaw'), "File no longer exists after restored to original state via destructor" );
};

# Mock based testing
subtest_streamed "Common tests using mocks" => sub {
    local %Net::OpenSSH::More::cache;
    my $parent_mock = Test::MockModule->new('Net::OpenSSH::More');
    $parent_mock->redefine(
        'new'          => sub { bless {}, $_[0] },
        'check_master' => 1,
        'DESTROY'      => undef,
    );
    my $obj = Net::OpenSSH::More::Linux->new( 'host' => 'localhost', retry_max => 1 );
    is( ref $obj, 'Net::OpenSSH::More::Linux', "Got right ref type for object upon instantiation" );
};

done_testing();
