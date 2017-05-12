#!/usr/bin/perl -w

use Test::More no_plan => 1;
use Pod::Snippets;

=head1 NAME

as_data.t - Tests that the I<as_data()> method works as documented.

=head1 DESCRIPTION

This test doubles as an excellent showcase of how to use
B<Pod::Snippets> to perform unit testing.

=cut

my $snips = Pod::Snippets->load($INC{"Pod/Snippets.pm"},
                                -markup => "metatests",
                                -named_snippets => "strict");
my @expected;
eval "\@expected =\n" .
    $snips->named("as_data multiple blocks return")->as_code();
die $@ if $@;

ok(@expected, "got the expected results from the POD");

my $pod_in_pod = "=pod\n\n" .
    $snips->named("as_data multiple blocks input")->as_data .
    "\n\n=cut\n";

my $recursnips = Pod::Snippets->parse
    ($pod_in_pod, -markup => "test", -named_snippets => "strict");

my @as_data = $recursnips->as_data;
is(scalar(@as_data), scalar(@expected),
   "got correct number of snippets back");

foreach my $i (0..$#as_data) {
    is($as_data[$i], $expected[$i], "snippet #$i is as expected");
}
