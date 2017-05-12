#!/usr/bin/perl -w
# vim:set ft=perl:

use strict;
use Test::More;

use Pod::XPath;

my $p = Pod::XPath->new("t/data/xml.pod");
my $test;

my %scalar_tests = (
    q{/pod/head/title/text()}
        => "Chapter 9 - Using XML",
    q{/pod/sect1/sect2/title[contains(text(), "DTD")]/following-sibling::para[2]}
        => "\nHere's the DTD that we'll be using for our XML.\n",
    q{/pod/sect1[title="CHAPTER OUTLINE"]/list/item[2]/itemtext/text()}
        => 'o',
);

my %list_tests = (
    q{//verbatim} => 75,
    q{//list[1]/item} => 11,
    q{//list/item} => 11,
    q{//code} => 68,
);

plan tests => (keys(%scalar_tests) * 2)
            + (keys(%list_tests) * 2)
            + 3;

use_ok("Pod::XPath");
ok(defined $p, "Pod::XPath->new");
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
