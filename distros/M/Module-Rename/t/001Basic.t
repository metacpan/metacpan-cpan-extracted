######################################################################
# Test suite for Module::Rename
# by Mike Schilli <cpan@perlmeister.com>
######################################################################

use warnings;
use strict;

use Test::More qw(no_plan);
use Sysadm::Install qw(:all);
use Log::Log4perl qw(:easy);
use File::Basename;
use File::Find;
use FindBin qw( $Bin );

Log::Log4perl->easy_init({level => $ERROR, file => 'STDOUT'});

BEGIN { use_ok('Module::Rename') };

my $sbx = "$Bin/sandbox";
require "$sbx/utils/Utils.pm";

cd $sbx;
rmf "tmp" if -d "tmp";
cp_r("Foo-Bar", "tmp");

rmf "tmp/Foo-Bar/eg/remove_me";

my $ren = Module::Rename->new(
    name_old           => "Foo::Bar",
    name_new           => "Ka::Boom",
    wipe_empty_subdirs => 1,
);

$ren->find_and_rename("tmp");

ok(! -f "tmp/Foo-Bar/lib/Foo/Bar.pm", "Old file deleted");
ok( -f "tmp/Ka-Boom/lib/Ka/Boom.pm", "File renamed");

my $data = slurp "tmp/Ka-Boom/lib/Ka/Boom.pm";
unlike($data, qr/Foo::Bar/, "Content renamed");
like($data, qr/Ka::Boom/, "Content renamed");

$data = slurp "tmp/Ka-Boom/Makefile.PL";
unlike($data, qr/Foo::Bar/, "Content renamed");
unlike($data, qr/Foo\/Bar/, "Content renamed");

ok(-d   "tmp/Ka-Boom/eg",      "Leave previously empty dir untouched");
ok(! -d "tmp/Ka-Boom/lib/Foo", "Sweep away now-empty subdir");

ok(! -f "tmp/Ka-Boom/Bar.pm", "File renamed");
ok(-f "tmp/Ka-Boom/Boom.pm", "File renamed");

rmf "tmp";
