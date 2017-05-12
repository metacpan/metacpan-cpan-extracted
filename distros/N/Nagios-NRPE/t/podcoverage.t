#!/usr/bin/perl

use Test::Pod::Coverage tests=>3;
pod_coverage_ok( "Nagios::NRPE::Client", "Nagios::NRPE::Client is covered" );
pod_coverage_ok( "Nagios::NRPE::Daemon", "Nagios::NRPE::Daemon is covered" );
pod_coverage_ok( "Nagios::NRPE::Packet", "Nagios::NRPE::Packet is covered" );
