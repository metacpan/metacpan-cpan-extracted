#!/usr/bin/perl
# Test the loadability of our modules
use Test::More qw(no_plan);
my @modules = qw(XML::LibXML);
for my $m (@modules){
    use_ok($m);
}
