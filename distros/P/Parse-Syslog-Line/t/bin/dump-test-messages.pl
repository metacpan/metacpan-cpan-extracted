#!perl
#
use v5.16;
use warnings;

use FindBin;
use YAML::XS ();
use lib "$FindBin::Bin/../lib";
use test::Data;

my $match = shift;
my $tests = get_test_data("$FindBin::Bin/..");
foreach my $file ( sort keys %{ $tests } ) {
    my $t = $tests->{$file};
    my $msg = $t->{string};
    if ( $match ) {
        say $msg if index(lc($t->{name}), lc($match)) >= 0;
    }
    else {
        say $msg;
    }
}

