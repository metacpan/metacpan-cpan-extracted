#!/usr/bin/env perl
use warnings;
use strict;
use Test::More tests => 4;
use FindBin '$Bin';
use Property::Lookup::File;

my $o = Property::Lookup::File->new(filename => "$Bin/conf.yaml");
is($o->foo, 'bar', 'key [foo]');
is_deeply($o->baz, [ 42 ], 'key [baz]');
is($o->wiz, undef, 'key [wiz] is undef');
is($o->dir, $Bin, '$SELF');
