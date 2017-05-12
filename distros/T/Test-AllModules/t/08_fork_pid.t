use strict;
use warnings;
use FindBin;
use File::Spec;
use lib File::Spec->catdir($FindBin::Bin, 'lib');
use Test::AllModules;

BEGIN {
    all_ok(
        search_path => 'MyApp',
        lib => [ File::Spec->catfile('t','lib') ],
        check => +{
            'use_ok' => sub {
                my $class = shift;
                eval "use $class;1;";
            },
        },
        fork => 2,
    );
}