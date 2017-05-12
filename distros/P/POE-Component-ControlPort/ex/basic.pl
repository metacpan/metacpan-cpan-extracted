#!/usr/bin/perl

use warnings;
use strict;

use POE;
use POE::Component::ControlPort;


POE::Component::ControlPort->create(
    local_address => '127.0.0.1',
    local_port => '31337',
);

POE::Kernel->run();
