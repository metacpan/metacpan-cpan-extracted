#!perl

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;

use File::Temp qw(tempfile);
use PMVersions::Util qw(read_pmversions version_from_pmversions);

my ($pmvfh, $pmvpath) = tempfile();
print $pmvfh "Foo::Bar=1.23\nBaz=0\n";
close $pmvfh;

subtest read_pmversions => sub {
    is_deeply(read_pmversions($pmvpath), {"Foo::Bar"=>1.23, "Baz"=>0});
};

subtest version_from_pmversions => sub {
    is_deeply(version_from_pmversions("Foo::Bar", $pmvpath), "1.23");
    is_deeply(version_from_pmversions("Baz"), "0");
    is_deeply(version_from_pmversions("Qux"), undef);
};

done_testing;
