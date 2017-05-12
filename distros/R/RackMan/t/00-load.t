#!perl -T
use strict;
use Test::More;
use lib ".";

my @modules = qw<
    RackMan
    RackMan::Config
    RackMan::Device
    RackMan::Device::PDU
    RackMan::Device::PDU::APC_RackPDU
    RackMan::Device::Server
    RackMan::Device::Server::HP_ProLiant
    RackMan::Device::Switch
    RackMan::Device::Switch::Cisco_Catalyst
    RackMan::Device::VM
    RackMan::File
    RackMan::Format::Bacula
    RackMan::Format::Cacti
    RackMan::Format::DHCP
    RackMan::Format::Generic
    RackMan::Format::Kickstart
    RackMan::Format::LDAP
    RackMan::Format::Nagios
    RackMan::Format::PXE
    RackMan::SCM
    RackMan::Tasks
    RackMan::Template
    RackMan::Types
    RackMan::Utils
    RackTables::Schema
    RackTables::Types
>;

my @commands = qw<
    cfengine-tags
    cisco-status
    rack
    racktables-check
>;

plan tests => @modules + @commands;

use_ok($_) or print "Bail out!\n" for @modules;

for my $command (@commands) {
    my $path = "bin/$command";
    (my $name = $command) =~ s/\W/_/g;
    ok eval "package $name; require '$path'; 1", "check $path" or diag $@;
}

diag( "Testing RackMan $RackMan::VERSION, Perl $], $^X" );
