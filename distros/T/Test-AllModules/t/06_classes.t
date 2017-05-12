use strict;
use warnings;
use FindBin;
use File::Spec;
use lib File::Spec->catdir($FindBin::Bin, 'lib');
use Test::More;
use Test::AllModules;

my $SORTED_LIST = 'MyApp MyApp::RegExp::Test MyApp::Test';

my $fail = 1;

for (1..9) {
    my @classes = Test::AllModules::_classes(
        'MyApp',
        [ File::Spec->catfile('t','lib') ], # lib
        1, # shuffle
    );
    my $got = join ' ', @classes;
    if ($got ne $SORTED_LIST) {
        ok 1, $got;
        $fail = 0;
        last;
    }
}

fail("perhaps shuffle is broken") if $fail;

done_testing;
