use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use FindBin;
use lib "$FindBin::Bin/../lib";

my $platform_module = $^O eq 'MSWin32' 
    ? 'NVMPL::Platform::Windows' 
    : 'NVMPL::Platform::Unix';
my $is_windows = $^O eq 'MSWin32';

use_ok($platform_module);

my $test_dir = tempdir(CLEANUP => 1);

# Test node_bin_path - call as function, not method
subtest 'node_bin_path' => sub {
    plan tests => 2;
    
    my $base_dir = File::Spec->catdir($test_dir, 'nvm_test');
    my $expected_bin = File::Spec->catfile($base_dir, 'versions', 'current', 'bin');
    
    # Call as function, not method
    my $result;
    if ($is_windows) {
        $result = NVMPL::Platform::Windows::node_bin_path($base_dir);
    } else {
        $result = NVMPL::Platform::Unix::node_bin_path($base_dir);
    }
    is($result, $expected_bin, "Returns correct bin path");
    
    # Test with trailing slash
    my $result2;
    if ($is_windows) {
        $result2 = NVMPL::Platform::Windows::node_bin_path($base_dir . '/');
    } else {
        $result2 = NVMPL::Platform::Unix::node_bin_path($base_dir . '/');
    }
    is($result2, $expected_bin, "Handles trailing slash correctly");
};

# Test remove_version_dir - call as function
subtest 'remove_version_dir' => sub {
    plan tests => 2;
    
    my $dir_to_remove = File::Spec->catdir($test_dir, 'remove_test');
    mkdir $dir_to_remove;
    
    my $result;
    if ($is_windows) {
        $result = NVMPL::Platform::Windows::remove_version_dir($dir_to_remove);
    } else {
        $result = NVMPL::Platform::Unix::remove_version_dir($dir_to_remove);
    }
    is($result, 1, "Successfully removes existing directory");
    ok(!-d $dir_to_remove, "Directory is actually gone");
};

# Test symlink/junction creation - call as function
subtest 'link_creation' => sub {
    plan tests => 2;
    
    my $target_dir = File::Spec->catdir($test_dir, 'link_target');
    my $link_path = File::Spec->catdir($test_dir, 'link_test');
    
    mkdir $target_dir;
    
    my $result;
    if ($is_windows) {
        $result = NVMPL::Platform::Windows::create_junction($target_dir, $link_path);
    } else {
        $result = NVMPL::Platform::Unix::create_symlink($target_dir, $link_path);
    }
    
    is($result, 1, "Successfully creates link");
    
    # Verify link exists
    if ($is_windows) {
        ok(-d $link_path, "Junction exists as directory");
    } else {
        ok(-l $link_path, "Symlink exists");
    }
};

# Test export_path_snippet - call as function
subtest 'export_path_snippet' => sub {
    plan tests => 1;
    
    my $base_dir = File::Spec->catdir($test_dir, 'export_test');
    
    # Simple test - just check it doesn't crash
    if ($is_windows) {
        NVMPL::Platform::Windows::export_path_snippet($base_dir);
    } else {
        NVMPL::Platform::Unix::export_path_snippet($base_dir);
    }
    pass("export_path_snippet runs without crashing");
};

plan tests => 5;