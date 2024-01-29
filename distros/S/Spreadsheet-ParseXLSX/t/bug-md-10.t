#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use Spreadsheet::ParseXLSX;

my $wb;
eval {
  $wb = Spreadsheet::ParseXLSX->new->parse('t/data/bug-md-10.xlsx');
};

ok(!defined($wb));
ok($@);
ok($@ =~ /^cannot expand &xxe/);

done_testing;



