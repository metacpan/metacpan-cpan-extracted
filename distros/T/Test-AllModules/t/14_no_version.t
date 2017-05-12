use strict;
use warnings;
use File::Spec;
use lib File::Spec->catfile('t','lib2');
use Test::AllModules;

BEGIN {
    all_ok(
        search_path => 'MyApp2',
        use => 1,
        show_version => 1,
    );
}
