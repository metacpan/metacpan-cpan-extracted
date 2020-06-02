#!/usr/bin/env perl

use strict;
use warnings;

use Capture::Tiny qw(capture_stderr);
use FindBin ();
use File::Basename;
use Test::More;
use Test::LongString;

use lib dirname(__FILE__) . '/../';

use MySQL::Workbench::DBIC;
use t::MySQL::Workbench::DBIC::Table;

my $bin  = $FindBin::Bin;
my $file = $bin . '/test.mwb';

my $col    = t::MySQL::Workbench::DBIC::Column->new( name => 'column_1' );
my $table  = t::MySQL::Workbench::DBIC::Table->new( name => 'ot_TestTable', columns => [ $col ] );

my $foo = MySQL::Workbench::DBIC->new(
    file                => $file,
    schema_name         => 'Schema',
    version             => '0.01',
    remove_table_prefix => 'ot_',
);

my $class = $foo->_class_template( $table, { to => {}, from => {} }, '' );
like_string $class, qr/package Schema::Result::(?!ot_)TestTable;/;

done_testing;
