#!/usr/bin/perl -w
# vim:set ft=perl:

use strict;
use Test::More;

use Pod::XPath;

my $p = Pod::XPath->new('Pod::XPath');
my $test;

my %scalar_tests = (
    q{/pod/head/title/text()}
        => "Pod::XPath - use XPath expressions to navigate a POD document",
    q{/pod/sect1[1]/title/text()}
        => "SYNOPSIS",
);

my %list_tests = (
    q{/pod/sect1} => 8,
);

plan tests => (keys(%scalar_tests) * 2)
            + (keys(%list_tests) * 2)
            + 3;

use_ok("Pod::XPath");
ok(defined $p, "Pod::XPath->new('Pod::XPath')");
isa_ok($p, "XML::XPath", '$p');

for $test (keys %scalar_tests) {
    my ($str, $output);
    ok($str = $p->find($test), $test);

    $output = $str;
    $output =~ s/\n/\\n/g;

    is("$str", $scalar_tests{$test}, $output);
}

for $test (keys %list_tests) {
    my (@ary, $output);
    ok(@ary = $p->findnodes($test), $test);

    $output = "('" . ref($ary[0]) . "' x " . scalar(@ary) . ")";
    $output =~ s/\n/\\n/g;

    is(scalar(@ary), $list_tests{$test}, $output);
}
