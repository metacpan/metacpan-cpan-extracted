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
    ];

    all_ok(
        search_path => 'MyApp',
        checks => $checks,
        lib => [ File::Spec->catfile('t','lib') ],
        except      => [ 'MyApp::Test', qr/MyApp::RegEx*/ ]
    );
}