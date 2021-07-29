use strict;
use warnings;
use Test2::V0;
use lib "t/lib";
use Util;

use Module::cpmfile;

my $cpmfile = Module::cpmfile->load("t/data/cpm.yml");
note dumper $cpmfile;

my $r1 = $cpmfile->effective_requirements;
is $r1, {
    P1 => {},
    P2 => {
        version => '2',
    },
    P3 => {},
    P4 => {
        version => '4',
    },
    P5 => {
        opt1 => 'a',
        opt2 => 'b',
        version => '5',
    }
};

my $r2 = $cpmfile->effective_requirements(undef, ["runtime"], ["requires"]);
is $r2, {
    P4 => {
        version => '4',
    },
    P5 => {
        opt1 =>  "a",
        opt2 =>  "b",
        version => "5",
    },
};

my $r3 = $cpmfile->effective_requirements(["hoge"]);
is $r3, {
    P1 => {},
    P2 => {
        version => '22',
    },
    P3 => {},
    P4 => {
        version => '4',
    },
    P5 => {
        opt1 => 'a',
        opt2 => 'b',
        version => '5',
    }
};

done_testing;
