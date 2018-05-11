#

use strict;
use warnings;
use Test::More;
use Data::Dumper;
use File::Spec;
use File::Spec::Unix;
use lib qw(./lib);
require_ok("Pod::Weaver::Plugin::Include::Finder");

sub normalizePath {
    my @nd;

    foreach my $d (@_) {
        push @nd, File::Spec->catdir( File::Spec::Unix->splitdir($d) );
    }
    return wantarray ? @nd : $nd[0];
}

my $finder = new_ok(
    "Pod::Weaver::Plugin::Include::Finder",
    [ pod_path => [ normalizePath(qw<t/simple/lib t/simple>) ] ],
    "finder object"
);

is_deeply(
    $finder->pod_path,
    [ normalizePath(qw<t/simple/lib t/simple>) ],
    "Pod path attribute"
);

my $podFile = $finder->find_source("src.pod");

is( $podFile, normalizePath("t/simple/src.pod"), "src.pod found" );

my $modFile = $finder->find_source("Test::Module");
is( $modFile, normalizePath("t/simple/lib/Test/Module.pm"), "Test::Module found" );

$modFile = $finder->find_source("Test/Module.pm");
is( $modFile, normalizePath("t/simple/lib/Test/Module.pm"), "Test/Module.pm found" );

is_deeply(
    $finder->maps,
    {
        "src.pod"        => normalizePath("t/simple/src.pod"),
        "Test::Module"   => normalizePath("t/simple/lib/Test/Module.pm"),
        "Test/Module.pm" => normalizePath("t/simple/lib/Test/Module.pm"),
    },
    "maps are built"
);

my $tmpl = $finder->get_template( template => 'info', source => 'src.pod', );

is( scalar @$tmpl, 1, "single paragraph template 'info\@src.pod'" );
is(
    $tmpl->[0]->as_pod_string,
    "Some more info\n\n",
    "content of info\@src.pod is correct"
);

is_deeply(
    [ sort keys %{ $finder->cache->{normalizePath('t/simple/src.pod')} } ],
    [qw<cont forNonPod info opts test>],
    "all expected templates are in place"
);

done_testing;
