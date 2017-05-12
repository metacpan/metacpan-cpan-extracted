use strict;
use warnings;
use FindBin;
use File::Spec;
use lib File::Spec->catdir($FindBin::Bin, 'lib');
use Test::AllModules;

BEGIN {

    my $checks = [
        +{
            'use_ok' => sub {
                my $class = shift;
                eval "use $class;1;";
            },
        },
        +{
            'use_ok2' => sub {
                1;
            },
        },
    ];

    all_ok( search_path => 'MyApp', checks => $checks );
}