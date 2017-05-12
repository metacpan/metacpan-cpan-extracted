#!/usr/bin/perl

BEGIN { $ENV{TESTING} = 1 }

use strict;
use warnings;
use Test::More;
use Test::Warnings;

my $module = 'Tail::Tool::File';
use_ok( $module );

my $file = $module->new( name => __FILE__ );

isa_ok $file, $module, 'Get a new file object';

my $w = eval { $file->watch };
diag $@ if $@;
ok !$@, 'No errors when trying to watch a file';
ok $w, 'Get a watcher back';
done_testing();
