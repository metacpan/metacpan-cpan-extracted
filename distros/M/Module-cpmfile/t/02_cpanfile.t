use strict;
use warnings;
use Test2::V0;
use lib "t/lib";
use Util;

use Module::cpmfile;
use Module::CPANfile;

my $cpanfile = Module::CPANfile->load("t/data/cpanfile");
my $cpmfile = Module::cpmfile->from_cpanfile($cpanfile);
note dumper $cpmfile;

my $features = $cpmfile->features;
my @name = keys %$features;
is \@name, ["name"];

is $features->{name}{description}, "desc";
is $features->{name}{prereqs}->cpanmeta->as_string_hash, {
    runtime => {
        requires => {
            X6 =>  '0',
        },
    },
};

done_testing;
