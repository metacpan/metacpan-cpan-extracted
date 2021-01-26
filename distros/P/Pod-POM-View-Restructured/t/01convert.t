#!/usr/bin/env perl
#
# Copyright (c) 2016 Jeff Fearn <Jeff.Fearn@gmail.com>
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as Perl itself. See perlartistic.

use strict;
use warnings;

use Test::More tests => 5;

use Pod::POM::View::Restructured;

my $conv = Pod::POM::View::Restructured->new({namespace => "Pod::POM::View::Restructured"});
isa_ok($conv, 'Pod::POM::View::Restructured');

my $rv = $conv->convert_file('lib/Pod/POM/View/Restructured.pm');

ok($rv);

# An array of RST strings we should get in the output
# You will ahve to escape any quanity chars. e.g. ?, *, etc.
my @expected = (
    '.. _Pod::POM::View::Restructured:',
    '.. _Pod::POM::View::Restructured::NAME:',
    '`Pod::POM <http://search.cpan.org/search\?query=Pod%3a%3aPOM&mode=module>`_'
);

my $count = 0;

foreach my $str (@expected) {
    cmp_ok($rv->{content}, '=~', $str, "string cmp " . $count++);
}
