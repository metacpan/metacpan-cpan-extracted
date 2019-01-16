#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use File::Basename;
use File::Spec;

use_ok 'MySQL::Workbench::Parser';

my $mwb = File::Spec->catfile(
    dirname( __FILE__ ),
    'flags.mwb',
);

my $parser = MySQL::Workbench::Parser->new( file => $mwb );
my $table  = $parser->tables->[0];

# test column flags
my $int_column = $table->columns->[0];
is_deeply $int_column->flags, { unsigned => 1, zerofill => 1 };

my $char_column = $table->columns->[1];
is_deeply $char_column->flags, { binary => 1 };

# test "UNIQUE" index
my $index = $table->indexes->[1];
is $index->type, 'UNIQUE';
is $index->name, 'Rolename_UNIQUE';

done_testing();
