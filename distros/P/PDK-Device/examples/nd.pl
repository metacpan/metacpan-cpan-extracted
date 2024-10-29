#!/usr/bin/perl

use utf8;
use 5.030;
use strict;
use warnings;

use Test::More;
use PDK::DBI::Pg;
use PDK::Device::ConfigBackup;
use PDK::Device::Concern::Netdisco;

my $db_params
  = {host => '192.168.99.99', port => 5432, dbname => 'netdisco', user => 'netdisco', password => 'Cisc0123'};

my $dbi = PDK::DBI::Pg->new($db_params);

my $sql = <<SQL;
select name, ip, os
from device
where os ~* 'cisco|ios'
  limit 1
SQL

my $devices = $dbi->execute($sql)->all;

my $nd = PDK::Device::Concern::Netdisco->new(dbi => $dbi);

$nd->exploreTopologyJob($devices);

use DDP;
p $cb;
