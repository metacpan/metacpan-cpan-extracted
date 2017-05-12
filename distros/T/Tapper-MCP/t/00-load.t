#! /usr/bin/env perl

use strict;
use warnings;


# get rid of warnings
use Class::C3;
use MRO::Compat;

use Test::More;
use Tapper::Schema::TestTools;

my @modules = ('Tapper::MCP',
               'Tapper::MCP::Child',
               'Tapper::MCP::Control',
               'Tapper::MCP::Config',
               'Tapper::MCP::Master',
               'Tapper::MCP::Net',
               'Tapper::MCP::Net::TAP',
               'Tapper::MCP::Scheduler::Algorithm',
               'Tapper::MCP::Scheduler::Algorithm::WFQ',
               'Tapper::MCP::Scheduler::Algorithm::DummyAlgorithm',
               'Tapper::MCP::Scheduler::Builder',
               'Tapper::MCP::Scheduler::Controller',
               'Tapper::MCP::Scheduler::PrioQueue',
              );

plan tests => $#modules+1;

foreach my $module(@modules) {
        require_ok($module);
}
