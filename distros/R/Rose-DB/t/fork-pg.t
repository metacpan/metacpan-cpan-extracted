#!/usr/bin/perl -w

use strict;

use FindBin qw($Bin);

no warnings 'once';
$Rose::DB::TEST::DB_TYPE = 'pg_admin';
do "$Bin/fork-mysql.t";
die $@  if($@);
