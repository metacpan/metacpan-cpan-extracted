use strict;
use warnings;
use FindBin;
use File::Spec;
use lib File::Spec->catdir($FindBin::Bin, 'lib');
use Test::AllModules;

BEGIN {
    all_ok(
        search_path => 'MyApp',
        require => 1,
    );
}
