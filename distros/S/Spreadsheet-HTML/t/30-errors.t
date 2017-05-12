#!perl -T
use strict;
use warnings FATAL => 'all';
use Test::More tests => 5;

use Spreadsheet::HTML;

my $table = Spreadsheet::HTML->new;

ok $table->generate( file => 'foo.csv' ), "handle missing CSV file";
ok $table->generate( file => 'foo.html' ), "handle missing HTML file";
ok $table->generate( file => 'foo.json' ), "handle missing JSON file";
ok $table->generate( file => 'foo.xls' ), "handle missing XLS file";
ok $table->generate( file => 'foo.yaml' ), "handle missing YAML file";
