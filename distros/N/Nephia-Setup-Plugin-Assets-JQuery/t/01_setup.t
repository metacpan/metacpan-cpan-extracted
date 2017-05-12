use strict;
use warnings;
use Test::More;
use File::Temp 'tempdir';
use File::Spec;
use Nephia::Setup;

{
    package 
        Nephia::Setup::Plugin::Dummy::JQuery;
    use parent 'Nephia::Setup::Plugin';
    sub bundle {qw/ Assets::JQuery /};
}

my $approot = tempdir(CLEANUP => 1);
my $setup = Nephia::Setup->new(
    approot => $approot,
    appname => 'MyApp::JQueryTest',
    plugins => [qw/Dummy::JQuery/],
);

$setup->do_task;

my @path_list = (
    [qw/js jquery.min.js/],
);

for my $path ( @path_list ) {
    my $subpath = File::Spec->catfile(@$path);
    ok( -e File::Spec->catfile($setup->approot, 'static', $subpath), sprintf('exists %s', $subpath) );
}

done_testing;
    
