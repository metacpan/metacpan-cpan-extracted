#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Test::MockModule;
use File::Spec;
use File::Path qw(make_path remove_tree);
use File::Temp qw(tempdir);
use FindBin;

# Add lib to include path
use lib "$FindBin::Bin/../lib";

# Module to test
use_ok('NVMPL::Uninstaller');

# Mock dependencies
my $mock_config;
my $mock_switcher;
my $mock_utils;

# Test variables
my $test_dir;
my $install_dir;
my $versions_dir;
my $downloads_dir;

# Setup test environment
sub setup_test_env {
    $test_dir = tempdir(CLEANUP => 1);
    $install_dir = File::Spec->catdir($test_dir, 'nvm-pl');
    $versions_dir = File::Spec->catdir($install_dir, 'versions');
    $downloads_dir = File::Spec->catdir($install_dir, 'downloads');
    
    make_path($versions_dir, $downloads_dir);
    
    # Mock Config
    $mock_config = Test::MockModule->new('NVMPL::Config');
    $mock_config->mock('load', sub {
        return {
            install_dir => $install_dir,
            mirror_url => 'https://nodejs.org/dist',
            cache_ttl => 86400,
            auto_use => 1,
            color_output => 1,
            log_level => 'info',
        };
    });
    
    # Mock Switcher
    $mock_switcher = Test::MockModule->new('NVMPL::Switcher');
    $mock_switcher->mock('_get_current_version', sub { return undef });
    $mock_switcher->mock('use_version', sub { return 1 });
    
    # Mock Utils
    $mock_utils = Test::MockModule->new('NVMPL::Utils');
}

# Teardown test environment
sub teardown_test_env {
    remove_tree($test_dir) if -d $test_dir;
    undef $mock_config;
    undef $mock_switcher;
    undef $mock_utils;
}

# Create a mock version directory
sub create_mock_version {
    my ($version) = @_;
    my $version_dir = File::Spec->catdir($versions_dir, $version);
    make_path($version_dir);
    
    # Create some mock files to simulate a Node.js installation
    my $bin_dir = File::Spec->catdir($version_dir, 'bin');
    make_path($bin_dir);
    
    open my $fh, '>', File::Spec->catfile($bin_dir, 'node') or die $!;
    print $fh "mock node binary\n";
    close $fh;
    
    return $version_dir;
}

# Create a mock download file
sub create_mock_download {
    my ($version, $platform) = @_;
    my $filename = "node-$version-$platform-x64.tar.xz";
    my $filepath = File::Spec->catfile($downloads_dir, $filename);
    
    open my $fh, '>', $filepath or die $!;
    print $fh "mock download content\n";
    close $fh;
    
    return $filepath;
}

# Mock the exit function to prevent test termination
sub mock_exit {
    my $mock_uninstaller = Test::MockModule->new('NVMPL::Uninstaller');
    $mock_uninstaller->mock('_exit_with_error', sub { 
        my ($message) = @_;
        die "EXIT: $message";
    });
    return $mock_uninstaller;
}

# Test suite
subtest 'Basic functionality' => sub {
    setup_test_env();
    
    # Test module loads
    ok(defined &NVMPL::Uninstaller::uninstall_version, 'uninstall_version sub is defined');
    
    teardown_test_env();
};

subtest 'Version argument validation' => sub {
    setup_test_env();
    
    my $mock_exit = mock_exit();
    
    # Test no version provided
    throws_ok {
        NVMPL::Uninstaller::uninstall_version();
    } qr/EXIT: Usage:/, 'Dies with usage message when no version provided';
    
    # Test empty version
    throws_ok {
        NVMPL::Uninstaller::uninstall_version('');
    } qr/EXIT: Usage:/, 'Dies with usage message when version is empty';
    
    undef $mock_exit;
    teardown_test_env();
};

subtest 'Non-existent version' => sub {
    setup_test_env();
    
    # Test uninstalling non-existent version
    throws_ok {
        NVMPL::Uninstaller::uninstall_version('v99.99.99');
    } qr/is not installed/, 'Dies when trying to uninstall non-existent version';
    
    teardown_test_env();
};

subtest 'Successful uninstall' => sub {
    setup_test_env();
    
    # Create a mock version
    my $version = 'v22.3.0';
    my $version_dir = create_mock_version($version);
    ok(-d $version_dir, 'Mock version directory created');
    
    # Mock confirmation
    my $mock_uninstaller = Test::MockModule->new('NVMPL::Uninstaller');
    $mock_uninstaller->mock('_confirm_uninstall', sub { return 1 });
    
    # Test successful uninstall
    lives_ok {
        NVMPL::Uninstaller::uninstall_version('22.3.0');
    } 'Uninstall completes without errors';
    
    ok(!-d $version_dir, 'Version directory removed');
    
    undef $mock_uninstaller;
    teardown_test_env();
};

subtest 'Version prefix handling' => sub {
    setup_test_env();
    
    # Test with 'v' prefix
    my $version_dir1 = create_mock_version('v22.3.0');
    my $mock_uninstaller = Test::MockModule->new('NVMPL::Uninstaller');
    $mock_uninstaller->mock('_confirm_uninstall', sub { return 1 });
    
    lives_ok {
        NVMPL::Uninstaller::uninstall_version('v22.3.0');
    } 'Uninstall works with v prefix';
    
    ok(!-d $version_dir1, 'Version directory with v prefix removed');
    
    # Test without 'v' prefix
    my $version_dir2 = create_mock_version('v21.6.0');
    
    lives_ok {
        NVMPL::Uninstaller::uninstall_version('21.6.0');
    } 'Uninstall works without v prefix';
    
    ok(!-d $version_dir2, 'Version directory without v prefix removed');
    
    undef $mock_uninstaller;
    teardown_test_env();
};

subtest 'Uninstall currently active version' => sub {
    setup_test_env();
    
    # Create multiple versions
    create_mock_version('v22.3.0');
    create_mock_version('v21.6.0');
    create_mock_version('v20.10.0');
    
    # Mock current version
    $mock_switcher->mock('_get_current_version', sub { return 'v22.3.0' });
    
    my $switch_called = 0;
    $mock_switcher->mock('use_version', sub { 
        $switch_called++;
        return 1;
    });
    
    my $mock_uninstaller = Test::MockModule->new('NVMPL::Uninstaller');
    $mock_uninstaller->mock('_confirm_uninstall', sub { return 1 });
    
    lives_ok {
        NVMPL::Uninstaller::uninstall_version('22.3.0');
    } 'Uninstall completes when uninstalling active version';
    
    is($switch_called, 1, 'Switcher was called to change active version');
    
    undef $mock_uninstaller;
    teardown_test_env();
};

subtest 'Download cache cleanup' => sub {
    setup_test_env();
    
    # Create version and download files
    my $version = 'v22.3.0';
    create_mock_version($version);
    my $download_file1 = create_mock_download($version, 'linux');
    my $download_file2 = create_mock_download($version, 'darwin');
    
    ok(-f $download_file1, 'Mock download file 1 created');
    ok(-f $download_file2, 'Mock download file 2 created');
    
    my $mock_uninstaller = Test::MockModule->new('NVMPL::Uninstaller');
    $mock_uninstaller->mock('_confirm_uninstall', sub { return 1 });
    
    lives_ok {
        NVMPL::Uninstaller::uninstall_version('22.3.0');
    } 'Uninstall completes with cache cleanup';
    
    ok(!-f $download_file1, 'Download file 1 removed');
    ok(!-f $download_file2, 'Download file 2 removed');
    
    undef $mock_uninstaller;
    teardown_test_env();
};

subtest 'User confirmation' => sub {
    setup_test_env();
    
    create_mock_version('v22.3.0');
    
    my $mock_uninstaller = Test::MockModule->new('NVMPL::Uninstaller');
    
    # Test confirmation accepted
    $mock_uninstaller->mock('_confirm_uninstall', sub { return 1 });
    
    lives_ok {
        NVMPL::Uninstaller::uninstall_version('22.3.0');
    } 'Uninstall proceeds when user confirms';
    
    # Recreate for second test
    create_mock_version('v21.6.0');
    
    # Test confirmation denied
    $mock_uninstaller->mock('_confirm_uninstall', sub { return 0 });
    
    lives_ok {
        NVMPL::Uninstaller::uninstall_version('21.6.0');
    } 'Uninstall cancels when user denies';
    
    my $version_dir = File::Spec->catdir($versions_dir, 'v21.6.0');
    ok(-d $version_dir, 'Version directory still exists after cancellation');
    
    undef $mock_uninstaller;
    teardown_test_env();
};

subtest 'Multiple version uninstall' => sub {
    setup_test_env();
    
    # Create multiple versions
    create_mock_version('v22.3.0');
    create_mock_version('v21.6.0');
    create_mock_version('v20.10.0');
    
    my $mock_uninstaller = Test::MockModule->new('NVMPL::Uninstaller');
    $mock_uninstaller->mock('_confirm_uninstall', sub { return 1 });
    
    # Test batch uninstall
    lives_ok {
        NVMPL::Uninstaller::uninstall_multiple('22.3.0', '21.6.0', '20.10.0');
    } 'Batch uninstall completes';
    
    ok(!-d File::Spec->catdir($versions_dir, 'v22.3.0'), 'Version 1 removed');
    ok(!-d File::Spec->catdir($versions_dir, 'v21.6.0'), 'Version 2 removed');
    ok(!-d File::Spec->catdir($versions_dir, 'v20.10.0'), 'Version 3 removed');
    
    undef $mock_uninstaller;
    teardown_test_env();
};

done_testing();