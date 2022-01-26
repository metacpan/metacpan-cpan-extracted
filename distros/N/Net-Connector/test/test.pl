
#!/usr/bin/perl
use strict;
use warnings FATAL => 'all';

use Net::Connector::Cisco::Nxos;
use Data::Printer;
use Data::Dumper;

$device = Net::Connector::Cisco::Nxos->new( host => '127.0.0.1' );
say Dumper $device->getConfig;
