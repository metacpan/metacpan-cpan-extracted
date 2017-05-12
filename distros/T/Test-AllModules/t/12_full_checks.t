use strict;
use warnings;
use FindBin;
use File::Spec;
use lib File::Spec->catdir($FindBin::Bin, 'lib');
use Test::AllModules;

BEGIN {
    all_ok(
        search_path => 'MyApp',
        use         => 1,
        require     => 1,
        check       => +{
            foo => sub { 1; },
        },
        checks      => [
            +{ bar => sub { 1; } },
            +{ baz => sub { 1; } },
        ],
    );
}
