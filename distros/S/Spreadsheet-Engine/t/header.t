#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 5;

use lib 'lib';
use Spreadsheet::Engine::Sheet;

my @lines  = <DATA>;
my $header = {};
parse_header_save(\@lines => $header);

is $header->{version},    1.1,  'Version';
is $header->{lastauthor}, 'me', 'Author';

# this behaviour is currently unspecified - people shouldn't rely on it
is $header->{club}, 'my playground is all in flames', 'Unknown fields fill';
is scalar @{ $header->{editlog} }, 3, '3 edits';
is $header->{editlog}->[1], 'set A2 value n 2', 'Filled OK';

__DATA__
version:1.1
lastauthor:me

# comments and blank lines should be OK
club:my playground is all in flames
edit:set A1 value n 1
edit:set A2 value n 2
   
edit:set A3 value n 3
