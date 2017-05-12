#!perl
#
# This file is part of MooX-Options
#
# This software is copyright (c) 2013 by celogeek <me@celogeek.com>.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use t::Test;

package Foo;
use Moo;
use MooX::Options;
option start_from => ( is => "ro", format => "s" );

package main;
local @ARGV = qw/--start_from 0/;
my $f = Foo->new_with_options;
my $n = $f->start_from;
is $n, 0, 'option with value 0 works';
$n++;
is $n, 1, 'and can be increment';

done_testing;
