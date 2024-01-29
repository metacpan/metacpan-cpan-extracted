use strict;
use warnings;
use Test::More;
use POSIX::strftime::Compiler;

use File::Basename;

my $inc = join ' ', map { "-I\"$_\"" } @INC;
my $dir = dirname(__FILE__);

$ENV{TEST_TZ} = 'CET-1CEST';

eval {
    my $d = `"$^X" $inc $dir/02_timezone.pl %z 0 0 0 1 7 112`;
    if ($d !~ m!^\+0200!) {
        die "tzdada is not enough: $d";
    }
    $d = `"$^X" $inc $dir/02_timezone.pl %z 0 0 0 1 1 112`;
    if ($d !~ m!^\+0100!) {
        die "tzdada is not enough: $d";
    }
};
if ( $@ ) {
    plan skip_all => $@;
}

my @t1 = (0, 0, 0, 1, 1, 112);
my @t2 = (0, 0, 0, 1, 7, 112);

is `"$^X" $inc $dir/02_timezone.pl %z @t1`, '+0100', "tmzone1($ENV{TEST_TZ})";
is `"$^X" $inc $dir/02_timezone.pl %Z @t1`, 'CET',   "tmname1($ENV{TEST_TZ})";
is `"$^X" $inc $dir/02_timezone.pl %z @t2`, '+0200', "tmzone2($ENV{TEST_TZ})";
is `"$^X" $inc $dir/02_timezone.pl %Z @t2`, 'CEST',  "tmname2($ENV{TEST_TZ})";

done_testing();