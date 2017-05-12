use strict;
use warnings;
use Test::More;
use File::Temp 'tempdir';
use File::Spec;
use Test::File::ShareDir::Dist {
    'Nephia-Setup-Plugin-Assets-Bootstrap' => File::Spec->catdir('share')
};
use Nephia::Setup;

{
    package 
        Nephia::Setup::Plugin::Dummy::Bootstrap;
    use parent 'Nephia::Setup::Plugin';
    sub bundle {qw/ Assets::Bootstrap /};
}

my $approot = tempdir(CLEANUP => 1);
my $setup = Nephia::Setup->new(
    approot => $approot,
    appname => 'MyApp::BootstrapTest',
    plugins => [qw/Dummy::Bootstrap/],
);

$setup->do_task;

my @path_list = (
    [qw/css bootstrap-responsive.css/],
    [qw/css bootstrap-responsive.min.css/],
    [qw/css bootstrap.css/],
    [qw/css bootstrap.min.css/],
    [qw/img glyphicons-halflings-white.png/],
    [qw/img glyphicons-halflings.png/],
    [qw/js bootstrap.js/],
    [qw/js bootstrap.min.js/],
);

for my $path ( @path_list ) {
    my $subpath = File::Spec->catfile(@$path);
    ok( -e File::Spec->catfile($setup->approot, qw/static bootstrap/, $subpath), sprintf('exists %s', $subpath) );
}

done_testing;
    
