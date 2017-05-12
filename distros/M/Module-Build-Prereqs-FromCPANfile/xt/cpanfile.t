use strict;
use warnings;
use Test::More;
use Module::Build::Prereqs::FromCPANfile;
use FindBin;

chdir $FindBin::RealBin;

my %got = mb_prereqs_from_cpanfile(version => "0.50");
is_deeply \%got, +{
    requires => { A => 0 },
    test_requires => {
        B => 0,
        B2 => "2.00"
    },
}, "read cpanfile from the current directory";

done_testing;
