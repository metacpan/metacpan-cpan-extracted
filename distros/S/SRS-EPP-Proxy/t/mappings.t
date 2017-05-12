#!/usr/bin/perl

# Test script for checking the mappings of the XML Mappings to/from SRS <-> EPP
# messages.

#
# See:
# RFC5730 - EPP
# RFC5731 - Domain Name Mapping
# RFC5732 - Host Mapping
# RFC5733 - Contact Mapping

use strict;
use warnings;

use Test::More qw(no_plan);

use FindBin qw($Bin);
use lib $Bin;
use Mock;
use XMLMappingTests qw(:all);
use Log4test;

use SRS::EPP::Command;

use Scriptalicious;
getopt;

my @files = map { s|^t/||; $_ } @ARGV;

our @testfiles = @files ? @files : find_tests;

# create an SRS::EPP::Session
my $proxy = Mock::Proxy->new();
$proxy->rfc_compliant_ssl(1);

use XML::EPP;
XML::EPP::register_ext_uri('urn:ietf:params:xml:ns:secDNS-1.1' => 'dns_sec');

run_unit_tests(
	sub {
		SRS::EPP::Session->new(
			event => Mock::Event->new,
			proxy => $proxy,
			backend_url => '',
			user => 11,
			peerhost => '192.168.1.1',
			peer_cn => 'peer_cn',
		);
	},
	@testfiles,
);

# Copyright (C) 2010  NZ Registry Services
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the Artistic License 2.0 or later.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# Artistic License 2.0 for more details.
#
# You should have received a copy of the Artistic License the file
# COPYING.txt.  If not, see
# <http://www.perlfoundation.org/artistic_license_2_0>
