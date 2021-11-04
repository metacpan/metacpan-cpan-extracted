#!/usr/bin/env perl

use Mojo::Util qw/dumper/;
use Netstack::Connector::H3c;
use DDP;
$h3c = Netstack::Connector::H3c->new(
  host     => '10.250.8.138',
  username => 'wenwu.yan',
  password => 'Cisc0!@#',
  proto    => 'ssh'
);
say dumper p $h3c->execCommands( 'dis v', 'dis version' );

use Mojo::Util qw/dumper/;
use Netstack::Connector::Nxos;
use DDP;
$nxos = Netstack::Connector::Nxos->new(
  host     => '10.155.193.134',
  username => 'wenwu.yan',
  password => 'Cisc0!@#',
  proto    => 'ssh'
);
say dumper p $nxos->execCommands( 'dis v', 'dis version' );

use Mojo::Util qw/dumper/;
use Netstack::Connector::PaloAlto;
use DDP;
$pa = Netstack::Connector::PaloAlto->new(
  host     => '10.250.8.211',
  username => 'wenwu.yan',
  password => 'Cisc0!@#',
  proto    => 'ssh'
);
say dumper p $pa->getConfig;

use Mojo::Util qw/dumper/;
use Netstack::Connector::Radware;
use DDP;
$rd = Netstack::Connector::Radware->new(
  host     => '10.240.202.1',
  username => 'wenwu.yan',
  password => 'Cisc0!@#',
  proto    => 'ssh'
);
say dumper p $rd->getConfig;

use Mojo::Util qw/dumper/;
use Netstack::Connector::Juniper;
use DDP;
$j = Netstack::Connector::Juniper->new(
  host     => '10.248.17.1',
  username => 'wenwu.yan',
  password => 'Cisc0!@#',
  proto    => 'ssh'
);
say dumper p $j->getConfig;
