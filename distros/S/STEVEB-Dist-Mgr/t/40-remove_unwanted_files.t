use warnings;
use strict;

use Cwd qw(getcwd);
use Test::More;
use Data::Dumper;
use Hook::Output::Tiny;
use Module::Starter;
use STEVEB::Dist::Mgr qw(:all);
use STEVEB::Dist::Mgr::FileData;

use lib 't/lib';
use Helper qw(:all);

my $work = 't/data/work';
my $orig = 't/data/orig';

my @unwanted_entries = _unwanted_filesystem_entries();

my %module_args = (
    author  => 'Steve Bertrand',
    email   => 'steveb@cpan.org',
    modules => [ qw(Test::Module) ],
    license => 'artistic2',
    builder => 'ExtUtils::MakeMaker',
);

my $h = Hook::Output::Tiny->new;

remove_unwanted();

my $cwd = getcwd();

like $cwd, qr/steveb-dist-mgr/, "in proper directory ok";

chdir $work or die $!;
like getcwd(), qr/$work$/, "in $work directory ok";

mkdir 'unwanted' or die $!;
is -d 'unwanted', 1, "'unwanted' dir created ok";

chdir 'unwanted' or die $!;
like getcwd(), qr/$work\/unwanted$/, "in $work/unwanted directory ok";

$h->hook('stderr');
Module::Starter->create_distro(%module_args);
$h->unhook('stderr');

is -d 'Test-Module', 1, "Test-Module directory created ok";

chdir 'Test-Module' or die $!;
like getcwd(), qr/Test-Module/, "in Test-Module dir ok";

# do stuff
{
    for (@unwanted_entries) {
        is -e $_, 1, "'$_' exists ok";
    }

    remove_unwanted_files();

    for (@unwanted_entries) {
        is -e $_, undef, "'$_' removed ok";
    }
}

chdir $cwd or die $!;
like getcwd(), qr/steveb-dist-mgr/, "back in root directory ok";

remove_unwanted();

done_testing;

