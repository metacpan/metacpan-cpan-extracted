#! perl -I. -w
use t::Test::abeltje;

use File::Spec::Functions qw/:DEFAULT devnull/;
use File::Find;

my @to_compile;
BEGIN {
    find(
        sub {
            -f or return;
            /\.pm$/ or return;
            push @to_compile, $File::Find::name;
        },
        './lib'
    ) if -d './lib';
}

my $out = '2>&1';
if (!$ENV{TEST_VERBOSE}) {
    $out = sprintf "> %s 2>&1", devnull();
}

foreach my $src ( @to_compile ) {
    is(
        system( qq{$^X  "-Ilib" "-c" "$src" $out} ),
        0,
        "perl -c '$src'"
    );
}

abeltje_done_testing();
