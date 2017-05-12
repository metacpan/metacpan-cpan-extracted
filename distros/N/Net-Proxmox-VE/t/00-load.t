#!/usr/bin/perl
use warnings;
use strict;
use Test::More tests => 1;

BEGIN { use_ok( 'Net::Proxmox::VE' ) or BAIL_OUT('unable to load module') }

diag( "Testing Net::Proxmox::VE $Net::Proxmox::VE::VERSION, Perl $], $^X" );
