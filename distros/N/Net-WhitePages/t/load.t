#!/usr/bin/perl -w
# vim: set ft=perl:

use Test::More;

plan tests => 2;

use_ok("Net::WhitePages");

my $wp = Net::WhitePages->new(TOKEN => "abc");
ok($wp, "Created Net::WhitePages object");

