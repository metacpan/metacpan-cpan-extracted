# -*- Mode: Perl -*-
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Scalar-Quote.t'

#########################

use Test::More tests => 153;

BEGIN { use_ok('Scalar::Quote') };

use Scalar::Quote qw(:quote :diff);

sub rs {
    my $len = 100+rand 1000;
    my @str=grep { !/[\$\@]/ } (map { chr(int(rand(200))) } 1..$len);
    join '', @str;
}

is (str_diffix('foo', 'fooa'), 3);
is (str_diffix('foao', 'fooa'), 2);

for $i (1..50) {
    my $str=rs;
    my $q=quote($str);
    my $e=eval "$q";

    is (quote($e), quote($str), "quote $i");

    my $str1=rs.'1';
    my $str2=rs.'2';
    my $c=rs;
    is(str_diffix($str2, $str1), str_diffix($c.$str1, $c.$str2)-length($c), "diffix $i");

    my ($d1, $d2)= str_diff($c.$str1, $c.$str2);
    is_deeply([$d2, $d1], [str_diff($c.$str2, $c.$str1)], "diff $i");
}
