######################################################################
# Test suite for Module::Rename
# by Mike Schilli <cpan@perlmeister.com>
######################################################################

use warnings;
use strict;

use Test::More;
use Sysadm::Install qw(:all);
use Module::Rename;
use File::Find;
use File::Basename;
use FindBin qw( $Bin );
use File::Temp qw( tempfile );

my $sbx = "$Bin/sandbox";
require "$sbx/utils/Utils.pm";

my $git = bin_find( "git" );

my $nof_tests = 8;
plan tests => $nof_tests;

SKIP: {
    skip "Skipping git tests - no git found", $nof_tests if !$git;

    my $sbx = "sandbox";
    $sbx = "t/$sbx" unless -d $sbx;
    $sbx = "../t/$sbx" unless -d $sbx;

    cd $sbx;

    rmf "tmp" if -d "tmp";
    cp_r("Foo-Bar", "tmp");

    cd "tmp/Foo-Bar";
    tap $git, "init";
    tap $git, "add", ".";
    tap $git, "commit", "-m", "init";
    cdback;
    
    my $ren = Module::Rename->new(
        name_old           => "Foo::Bar",
        name_new           => "Ka::Boom",
        wipe_empty_subdirs => 1,
        use_git            => 1,
    );

    $ren->find_and_rename("tmp");

    cd "tmp/Ka-Boom";
    tap $git, "add", ".";
    tap $git, "commit", "-m", "renamed";
    cdback;

    ok(! -f "tmp/Foo-Bar/lib/Foo/Bar.pm", "Old file deleted");
    ok( -f "tmp/Ka-Boom/lib/Ka/Boom.pm", "File renamed");

    my $data = slurp "tmp/Ka-Boom/lib/Ka/Boom.pm";
    unlike($data, qr/Foo::Bar/, "Content renamed");
    like($data, qr/Ka::Boom/, "Content renamed");

    ok(-d   "tmp/Ka-Boom/eg",      "Leave previously empty dir untouched");
    ok(! -d "tmp/Ka-Boom/lib/Foo", "Sweep away now-empty subdir");
    
    ok(! -f "tmp/Ka-Boom/Bar.pm", "File renamed");
    ok(-f "tmp/Ka-Boom/Boom.pm", "File renamed");
    
    rmf "tmp";
}
