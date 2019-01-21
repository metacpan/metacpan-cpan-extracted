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

my $foo = MySQL::Workbench::DBIC->new(
    file        => $file,
    schema_name => 'Schema',
    version     => '0.01',
);

my $table = t::MySQL::Workbench::DBIC::Table->new( name => 'TestTable' );
my $col   = t::MySQL::Workbench::DBIC::Column->new( name => 'column_1' );

my $sub = $foo->can('_column_details');

{
    my $expected = q~    column_1 => {
        data_type          => 'VARCHAR',
        size               => 34,
        default_value      => '0',
    },
~;
    my $got      = $foo->$sub( $table, $col, {}, {} );
    is_string $got, $expected;
}

{
    $table->comment('[]');
    my $expected = q~    column_1 => {
        data_type          => 'VARCHAR',
        size               => 34,
        default_value      => '0',
    },
~;
    my $got      = $foo->$sub( $table, $col, {}, {} );
    is_string $got, $expected;
}

{
    $table->comment('');
    my $expected = q~    column_1 => {
        data_type          => 'VARCHAR',
        size               => 34,
        default_value      => '0',
    },
~;
    my $got      = $foo->$sub( $table, $col, {}, {} );
    is_string $got, $expected;
}

{
    $col->default_value('');
    $table->comment('');
    my $expected = q~    column_1 => {
        data_type          => 'VARCHAR',
        size               => 34,
    },
~;
    my $got      = $foo->$sub( $table, $col, {}, {} );
    is_string $got, $expected;
}

{
    $col->default_value("''");
    $table->comment('');
    my $expected = q~    column_1 => {
        data_type          => 'VARCHAR',
        size               => 34,
        default_value      => '\\'\\'',
    },
~;
    my $got      = $foo->$sub( $table, $col, {}, {} );
    is_string $got, $expected;
}

{
    $col->default_value(undef);
    $table->comment('');
    my $expected = q~    column_1 => {
        data_type          => 'VARCHAR',
        size               => 34,
    },
~;
    my $got      = $foo->$sub( $table, $col, {}, {} );
    is_string $got, $expected;
}

{
    $col->default_value(undef);
    $col->length( -1 );
    $table->comment('');
    my $expected = q~    column_1 => {
        data_type          => 'VARCHAR',
        size               => 255,
    },
~;
    my $got      = $foo->$sub( $table, $col, {}, {} );
    is_string $got, $expected;
}

{
    $col->default_value(undef);
    $col->length( -1 );
    $table->comment('');
    my $expected = q~    column_1 => {
        data_type          => 'VARCHAR',
        size               => 255,
    },
~;
    my $got      = $foo->$sub( $table, $col, {} );
    is_string $got, $expected;
}

{
    $col->default_value(undef);
    $col->length( -1 );
    $col->comment( '{}' );
    $table->comment('');
    my $expected = q~    column_1 => {
        data_type          => 'VARCHAR',
        size               => 255,
    },
~;
    my $got      = $foo->$sub( $table, $col, {} );
    is_string $got, $expected;
}

{
    $col->default_value(undef);
    $col->length( -1 );
    $col->comment( '[]' );
    $table->comment('');
    my $expected = q~    column_1 => { # []
        data_type          => 'VARCHAR',
        size               => 255,
    },
~;
    my $got      = $foo->$sub( $table, $col, {} );
    is_string $got, $expected;
}

{
    $col->default_value(undef);
    $col->length( -1 );
    $col->comment( 'Test mit {' );
    $table->comment('');
    my $expected = q~    column_1 => { # Test mit {
        data_type          => 'VARCHAR',
        size               => 255,
    },
~;
    my $got;
    my $error = capture_stderr {
        $got = $foo->$sub( $table, $col, {} );
    };

    is_string $got, $expected;
    like_string $error, qr/malformed JSON string/;
}

done_testing;
