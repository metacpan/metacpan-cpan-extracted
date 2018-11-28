#!/usr/bin/env perl
#

use strict;
use warnings;

use Test::More;

use Pod::POM::View::Restructured;

my $conv = Pod::POM::View::Restructured->new({namespace => "Pod::POM::View::Restructured"});
isa_ok($conv, 'Pod::POM::View::Restructured');

use Cwd;
my $dir = getcwd;
my $rv = $conv->convert_file("$dir/t/test.pod");

ok($rv);

# An array of RST strings we should get in the output
# You will ahve to escape any quanity chars. e.g. ?, *, etc.
my @expected = (
    '- item1',
    '- item2',
    '* item3',
    '+ item4',
    '- item5',
);

my $count = 0;

foreach my $str (@expected) {
    cmp_ok($rv->{content}, '=~', "\Q$str\E", "string cmp " . $count++);
}

done_testing();
