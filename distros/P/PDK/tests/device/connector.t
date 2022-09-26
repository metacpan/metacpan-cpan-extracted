#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use DDP;
use PDK::DBI::Pg;
use PDK::Device;

my $dbi = PDK::DBI::Pg->new(
  host     => '127.0.0.1',
  port     => 5432,
  dbname   => 'firewall',
  user     => 'postgres',
  password => 'Cisc0123'
);

my $c = PDK::Device->new(dbi => $dbi);
my $fwInfos = $c->getFwInfo;
p $fwInfos;
p $c->getConfById($fwInfos->{7});
p $c->update;

done_testing();

