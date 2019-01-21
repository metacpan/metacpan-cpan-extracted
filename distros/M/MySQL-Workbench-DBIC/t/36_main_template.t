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
    file                => $file,
    schema_name         => 'Schema',
    version             => '0.01',
    result_namespace    => 'Core',
    resultset_namespace => 'Core',
    version_add         => '',
);

my $table = t::MySQL::Workbench::DBIC::Table->new( name => 'TestTable' );
my $col   = t::MySQL::Workbench::DBIC::Column->new( name => 'column_1' );
my $index = t::MySQL::Workbench::DBIC::Index->new( name => 'index_1' );

my $sub = $foo->can('_main_template');

{
    my $got = $foo->$sub();
    like_string $got, qr/package Schema;/;
}

{
    $foo->_set_schema_name(undef);
    my $got = $foo->$sub();
    like_string $got, qr/package DBIC_Schema;/;
}

{
    $foo->_set_schema_name('');
    my $got = $foo->$sub();
    like_string $got, qr/package DBIC_Schema;/;
}

{
    $foo->_set_schema_name('');
    $foo->_set_classes( [qw(DBIC_Schema Database DBIC MySchema MyDatabase DBIxClass_Schema)] );

    my $error;
    eval {
        my $got = $foo->$sub();
    } or $error = $@;

    like $error, qr/couldn't determine a package name for the schema/;
}

{
    $foo->_set_classes( [qw(Test)] );
    $foo->_set_schema_name('');
    my $got = $foo->$sub();
    like_string $got, qr/package DBIC_Schema;/;
}

{
    $foo->_set_schema_name('');
    my $got = $foo->$sub();
    like_string $got, qr/package DBIC_Schema;/;
    like_string $got, qr/result_namespace => 'Core::Result',/;
    like_string $got, qr/resultset_namespace => 'Core',/;
}

done_testing;
