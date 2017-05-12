#!/usr/bin/perl

########################################################
#
#    List all openvz virtual machines on the cluster
#
########################################################

use strict;
use warnings;

use lib './lib';
use Net::Proxmox::VE;
use Data::Dumper;
use Getopt::Long;

my $host     = 'host';
my $username = 'user';
my $password = 'pass';
my $debug    =  undef;
my $realm    = 'pve'; # 'pve' or 'pam'

GetOptions (
    'host=s'     => \$host,
    'username=s' => \$username,
    'password=s' => \$password,
    'debug'      => \$debug,
    'realm'      => \$realm,
);

my $pve = Net::Proxmox::VE->new(
    host     => $host,
    username => $username,
    password => $password,
    debug    => $debug,
    realm    => $realm,
);

die "login failed\n"          unless $pve->login;
die "invalid login ticket\n"  unless $pve->check_login_ticket;
die "unsupport api version\n" unless $pve->api_version_check;

# list openvz virtual machines by requesting
my $resources = $pve->get("/cluster/resources");

# openvz and qemu objects are exactly the same.
# only the item->{type} value differs (openvz or qemu)
foreach my $item( @$resources ) {
    next unless $item->{type} eq 'qemu';

    print "id: " .        $item->{id} . "\n"; 
    print "cpu: " .       $item->{cpu} . "\n";
    print "disk: " .      $item->{disk} . "\n";
    print "maxcpu: " .    $item->{maxcpu} . "\n";
    print "maxdisk: " .   $item->{maxdisk} . "\n";
    print "maxmem: " .    $item->{maxmem} . "\n";
    print "mem: " .       $item->{mem} . "\n";
    print "node: " .      $item->{node} . "\n";
    print "type: " .      $item->{type} . "\n";
    print "uptime: " .    $item->{uptime} . "\n";
    print "diskread: " .  $item->{diskread} . "\n";
    print "diskwrite: " . $item->{diskwrite} . "\n";
    print "name: " .      $item->{name} . "\n";
    print "netin: " .     $item->{netin} . "\n";
    print "netout: " .    $item->{netout} . "\n";
    print "status: " .    $item->{status} . "\n";
    print "template: " .  $item->{template} . "\n";
    print "vmid: " .      $item->{vmid} . "\n";
    print "\n";
}
