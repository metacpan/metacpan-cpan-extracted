use strict;
use warnings;
use Test::More;
use Test::MockModule;
use Test::Exception;  # Add this for testing code that dies/exits
use File::Temp qw(tempdir);
use File::Spec;
use Capture::Tiny qw(capture);
use FindBin;
use lib "$FindBin::Bin/../lib";
use NVMPL::Switcher;

plan tests => 8;

# --------------------------------------------------------------------
# Setup: temporary fake install_dir with version directories
# --------------------------------------------------------------------
my $tmp_root     = tempdir(CLEANUP => 1);
my $install_dir  = File::Spec->catdir($tmp_root, 'install');
my $versions_dir = File::Spec->catdir($install_dir, 'versions');
mkdir $install_dir;
mkdir $versions_dir;

mkdir File::Spec->catdir($versions_dir, 'v18.17.0');
mkdir File::Spec->catdir($versions_dir, 'v20.10.0');

# --------------------------------------------------------------------
# Mock NVMPL::Config->load to always return our temp install_dir
# --------------------------------------------------------------------
my $mock_cfg = Test::MockModule->new('NVMPL::Config');
$mock_cfg->redefine('load', sub {
    return { install_dir => $install_dir };
});

# --------------------------------------------------------------------
# Test list_installed()
# --------------------------------------------------------------------
my ($stdout, $stderr) = capture {
    NVMPL::Switcher::list_installed();
};

like($stdout, qr/Installed versions/, 'lists header');
like($stdout, qr/v18\.17\.0/, 'shows v18.17.0');
like($stdout, qr/v20\.10\.0/, 'shows v20.10.0');

# --------------------------------------------------------------------
# Test show_current() - no symlink yet
# --------------------------------------------------------------------
($stdout, $stderr) = capture {
    NVMPL::Switcher::show_current();
};
like($stdout, qr/No active Node version/, 'no current symlink yet');

# --------------------------------------------------------------------
# Test use_version() - valid version
# --------------------------------------------------------------------
my $target = File::Spec->catdir($versions_dir, 'v18.17.0');
my $current = File::Spec->catfile($versions_dir, 'current');

($stdout, $stderr) = capture {
    NVMPL::Switcher::use_version('18.17.0');
};

ok(-l $current, 'creates current symlink');
is(readlink($current), $target, 'symlink points to v18.17.0');
like($stdout, qr/Active version is now v18\.17\.0/, 'shows success message');
like($stdout, qr/Restart your shell/, 'shows restart instructions');

# --------------------------------------------------------------------
# Test use_version() - missing version (using Test::Exception)
# --------------------------------------------------------------------
($stdout, $stderr) = capture {
    eval { NVMPL::Switcher::use_version('99.99.99'); 1 } || do {
        like($stdout, qr/Version v99\.99\.99 is not installed/, 'warns about missing version');
    };
};