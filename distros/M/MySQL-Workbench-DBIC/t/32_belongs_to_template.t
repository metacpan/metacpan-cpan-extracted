#!/usr/bin/env perl

use strict;
use warnings;

use FindBin ();
use Test::More;
use MySQL::Workbench::DBIC;
use Test::LongString;

my $bin  = $FindBin::Bin;
my $file = $bin . '/test.mwb';

my $foo = MySQL::Workbench::DBIC->new(
    file        => $file,
    schema_name => 'Schema',
);


my $sub = $foo->can('_belongs_to_template');

{
    my $expected = q~~;
    my $got      = $foo->$sub('test');
    is_string $got, $expected;
}

{
    my $expected = q~
__PACKAGE__->belongs_to(test => 'Schema::Result::test',
             { 'foreign.test_id' => 'self.id' });
~;
    my $got      = $foo->$sub('test', [{foreign => 'test_id', me => 'id'}]);
    is_string $got, $expected;
}

{
    my $expected = q~
__PACKAGE__->belongs_to(test => 'Schema::Result::test',
             { 'foreign.test_id' => 'self.id' });

__PACKAGE__->belongs_to(test1 => 'Schema::Result::test',
             { 'foreign.another_id' => 'self.id' });
~;
    my $got      = $foo->$sub('test', [{foreign => 'test_id', me => 'id'},{foreign => 'another_id', me => 'id'}]);
    is_string $got, $expected;
}

done_testing;
