#!/usr/bin/env perl
use strict;
use lib 't/lib';
use Test::More;
use Empty;

plan tests => 1;

my $obj = Empty->new;
is( ref($obj), "Empty" );

