#!/usr/bin/perl
#Editor vim:syn=perl

use strict;
use warnings;
use Test::More 'no_plan';
use lib 'lib';

use Panotools::Makefile::Variable;
use Panotools::Makefile::Utils qw/platform/;
ok (1);

my $var = new Panotools::Makefile::Variable;

$var->Name ('USERS');

$var->Values ('James Brine', 'George Loveless');
$var->Values ('Thomas Standfield');

platform ('MSWin32');

ok ($var->Assemble =~ /USERS_SHELL = "James Brine" "George Loveless" "Thomas Standfield"/);
ok ($var->Assemble =~ /USERS = James\\ Brine George\\ Loveless Thomas\\ Standfield/);

platform ('linux');

ok ($var->Assemble =~ /USERS_SHELL = James\\ Brine George\\ Loveless Thomas\\ Standfield/);
ok ($var->Assemble =~ /USERS = James\\ Brine George\\ Loveless Thomas\\ Standfield/);

undef $var;

my $var2 = new Panotools::Makefile::Variable ('USERS');

$var2->Values ('James Brine', 'George Loveless');
$var2->Values ('Thomas Standfield');

platform ('MSWin32');

ok ($var2->Assemble =~ /USERS_SHELL = "James Brine" "George Loveless" "Thomas Standfield"/);
ok ($var2->Assemble =~ /USERS = James\\ Brine George\\ Loveless Thomas\\ Standfield/);

platform ('linux');

ok ($var2->Assemble =~ /USERS_SHELL = James\\ Brine George\\ Loveless Thomas\\ Standfield/);
ok ($var2->Assemble =~ /USERS = James\\ Brine George\\ Loveless Thomas\\ Standfield/);

