use strict;
use warnings;
use Test::More;
use Test::Exception;
use Test::MockModule;
use File::Temp qw(tempdir);
use File::Spec;
use File::Path qw(make_path remove_tree);
use FindBin;
use lib "$FindBin::Bin/../lib";

plan tests => 6;

my $test_dir = tempdir(CLEANUP => 1);

# Create mock modules
my $config_mock = Test::MockModule->new('NVMPL::Config');
my $utils_mock = Test::MockModule->new('NVMPL::Utils');
my $http_mock = Test::MockModule->new('HTTP::Tiny');

# Setup mocks
$config_mock->mock('load', sub {
    return {
        install_dir => $test_dir,
        mirror_url => 'https://nodejs.org/dist',
        cache_ttl => 86400,
    };
});

$utils_mock->mock('log_info', sub { });
$utils_mock->mock('log_warn', sub { });
$utils_mock->mock('log_error', sub { });

# Now require the module after all mocks are setup
require NVMPL::Remote;

# Test fetch_remote_list with cache
subtest 'fetch_remote_list with cache' => sub {
    plan tests => 3;
    
    my $cachefile = File::Spec->catfile($test_dir, 'node_index_cache.json');
    
    # Create a fake cache file
    my $fake_cache_data = '[{"version":"v22.3.0","lts":false},{"version":"v20.15.0","lts":"Iron"}]';
    open my $fh, '>', $cachefile or die "Cannot create cache file: $!";
    print $fh $fake_cache_data;
    close $fh;
    
    # Set the file modification time to be recent (within TTL)
    my $recent_time = time - 100;  # 100 seconds old
    utime $recent_time, $recent_time, $cachefile;
    
    my $releases;
    lives_ok {
        $releases = NVMPL::Remote::fetch_remote_list();
    } 'fetch_remote_list runs successfully with cache';
    
    is(scalar @$releases, 2, 'Returns correct number of releases from cache');
    is($releases->[0]{version}, 'v22.3.0', 'First release has correct version from cache');
};

# Test fetch_remote_list with expired cache
subtest 'fetch_remote_list with expired cache' => sub {
    plan tests => 4;  # Fixed: Changed from 3 to 4
    
    my $cachefile = File::Spec->catfile($test_dir, 'node_index_cache.json');
    
    # Create a fake cache file that's expired
    my $fake_cache_data = '[{"version":"v18.0.0","lts":false}]';
    open my $fh, '>', $cachefile or die "Cannot create cache file: $!";
    print $fh $fake_cache_data;
    close $fh;
    
    # Set the file modification time to be old (beyond TTL)
    my $old_time = time - 90000;  # 25 hours old
    utime $old_time, $old_time, $cachefile;
    
    # Mock HTTP response for fresh data
    $http_mock->mock('get', sub {
        my ($self, $url) = @_;
        return {
            success => 1,
            status => 200,
            content => '[{"version":"v22.3.0","lts":false},{"version":"v20.15.0","lts":"Iron"}]'
        };
    });
    
    my $releases;
    lives_ok {
        $releases = NVMPL::Remote::fetch_remote_list();
    } 'fetch_remote_list runs successfully with expired cache';
    
    is(scalar @$releases, 2, 'Returns correct number of releases from network');
    is($releases->[0]{version}, 'v22.3.0', 'First release has correct version from network');
    
    # Verify cache was updated
    ok(-f $cachefile, 'Cache file was updated');
};

# Test fetch_remote_list without cache
subtest 'fetch_remote_list without cache' => sub {
    plan tests => 3;
    
    my $cachefile = File::Spec->catfile($test_dir, 'node_index_cache.json');
    
    # Remove any existing cache file
    unlink $cachefile if -f $cachefile;
    
    # Mock HTTP response
    $http_mock->mock('get', sub {
        my ($self, $url) = @_;
        return {
            success => 1,
            status => 200,
            content => '[{"version":"v22.3.0","lts":false},{"version":"v20.15.0","lts":"Iron"}]'
        };
    });
    
    my $releases;
    lives_ok {
        $releases = NVMPL::Remote::fetch_remote_list();
    } 'fetch_remote_list runs successfully without cache';
    
    is(scalar @$releases, 2, 'Returns correct number of releases');
    ok(-f $cachefile, 'Cache file was created');
};

# Test fetch_remote_list network failure
subtest 'fetch_remote_list network failure' => sub {
    plan tests => 2;
    
    my $cachefile = File::Spec->catfile($test_dir, 'node_index_cache.json');
    
    # Remove any existing cache file
    unlink $cachefile if -f $cachefile;
    
    # Mock HTTP failure
    $http_mock->mock('get', sub {
        return {
            success => 0,
            status => 500,
            reason => 'Internal Server Error'
        };
    });
    
    throws_ok {
        NVMPL::Remote::fetch_remote_list();
    } qr/Network error while fetching index\.json/, 'Dies appropriately on network failure';
    
    ok(!-f $cachefile, 'No cache file created on network failure');
};

# Test list_remote_versions with LTS filter
subtest 'list_remote_versions with LTS filter' => sub {
    plan tests => 2;
    
    # Mock fetch_remote_list to return test data
    my $original_fetch = \&NVMPL::Remote::fetch_remote_list;
    no warnings 'redefine';
    local *NVMPL::Remote::fetch_remote_list = sub {
        return [
            { version => 'v22.3.0', lts => 0 },
            { version => 'v20.15.0', lts => 'Iron' },
            { version => 'v18.20.0', lts => 'Hydrogen' },
            { version => 'v16.20.0', lts => 'Gallium' },
        ];
    };
    
    # Capture output
    my $output = '';
    open my $fh, '>', \$output or die "Cannot capture output: $!";
    my $old_stdout = select $fh;
    
    lives_ok {
        NVMPL::Remote::list_remote_versions(lts => 1);
    } 'list_remote_versions with LTS filter runs successfully';
    
    # Restore STDOUT
    select $old_stdout;
    close $fh;
    
    like($output, qr/Available Node\.js versions:/, 'Output contains header');
};

# Test list_remote_versions with limit
subtest 'list_remote_versions with limit' => sub {
    plan tests => 2;
    
    # Mock fetch_remote_list to return test data
    my $original_fetch = \&NVMPL::Remote::fetch_remote_list;
    no warnings 'redefine';
    local *NVMPL::Remote::fetch_remote_list = sub {
        return [
            map { { version => "v$_.0.0", lts => 0 } } (1..30)  # Fixed: removed extra backslash
        ];
    };
    
    # Capture output
    my $output = '';
    open my $fh, '>', \$output or die "Cannot capture output: $!";
    my $old_stdout = select $fh;
    
    lives_ok {
        NVMPL::Remote::list_remote_versions(limit => 5);
    } 'list_remote_versions with limit runs successfully';
    
    # Restore STDOUT
    select $old_stdout;
    close $fh;
    
    # Count the number of version lines (excluding the header)
    my @lines = split("\n", $output);
    
    # The output format from your code is: " $r $lts"
    # So we need to count lines that start with space + version pattern
    my $version_count = grep { /^\s+v\d+\.\d+\.\d+/ } @lines;
    
    is($version_count, 5, 'Output is limited to 5 versions');
};

done_testing();