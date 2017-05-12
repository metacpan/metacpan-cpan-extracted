use strict;
use warnings;
use FindBin;
use File::Spec;
use lib File::Spec->catdir($FindBin::Bin, 'lib');
use Test::AllModules;

BEGIN {
    all_ok(
        search_path => 'MyApp',
        use => 1,
        show_version => 1,
    );
}