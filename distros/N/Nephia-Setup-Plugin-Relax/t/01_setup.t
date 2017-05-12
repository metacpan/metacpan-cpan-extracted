use strict;
use warnings;
use Test::More;
use Nephia::Setup;
use Nephia::Setup::Plugin::Relax;
use File::Temp 'tempdir';
use File::Spec;

my $approot = File::Spec->catdir(tempdir(CLEANUP => 1), 'approot');

my $setup = Nephia::Setup->new(
    appname => 'My::WebApp', 
    approot => $approot,
    plugins => [ 'Relax' ],
);

$setup->do_task;

my @files = (
    [qw/app.psgi/],
    [qw/config common.pl/],
    [qw/config local.pl/],
    [qw/config dev.pl/],
    [qw/config real.pl/],
    [qw/lib My WebApp.pm/],
    [qw/lib My WebApp C Root.pm/],
    [qw/lib My WebApp C API Member.pm/],
    [qw/lib My WebApp M.pm/],
    [qw/lib My WebApp M DB.pm/],
    [qw/lib My WebApp M DB Member.pm/],
    [qw/lib My WebApp M Cache.pm/],
    [qw/view index.tt/],
    [qw/view include layout.tt/],
    [qw/view include navbar.tt/],
    [qw/view error.tt/],
    [qw/sql sqlite.sql/],
    [qw/sql mysql.sql/],
    [qw/script setup.sh/],
    [qw/cpanfile/]
);

my @dirs = (
    [qw/var/],
);

for my $entry ( @files ) {
    my $file = File::Spec->catfile($approot, @$entry);
    ok -f $file, "exists $file";
}

for my $entry ( @dirs ) {
    my $dir = File::Spec->catfile($approot, @$entry);
    ok -d $dir, "exists $dir";
}

done_testing;
