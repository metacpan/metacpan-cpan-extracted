#!perl

use strict;
use warnings;
use POE::Component::TFTPd;
use POE;
use Test::More tests => 1;

POE::Kernel->run;

my $port   = 9753;
my $server = POE::Component::TFTPd->create(
                localaddr => 127.0.0.1,
                port      => $port,
            );

isa_ok($server, 'POE::Component::TFTPd');

