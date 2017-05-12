#!/usr/bin/perl

#####################################################
#
#    List all nodes
#
#####################################################

use strict;
use warnings;

use lib './lib';
use Net::Proxmox::VE;
use Data::Dumper;
use Getopt::Long;

my $host     = 'host';
my $username = 'user';
my $password = 'pass';
my $debug    = undef;
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

my $nodes = $pve->get('/nodes');

foreach my $item( @$nodes ) {
    print "id: " .      $item->{id} . "\n"; 
    print "cpu: " .     $item->{cpu} . "\n";
    print "disk: " .    $item->{disk} . "\n";
    print "level: " .   $item->{level} . "\n";
    print "maxcpu: " .  $item->{maxcpu} . "\n";
    print "maxdisk: " . $item->{maxdisk} . "\n";
    print "maxmem: " .  $item->{maxmem} . "\n";
    print "mem: " .     $item->{mem} . "\n";
    print "node: " .    $item->{node} . "\n";
    print "type: " .    $item->{type} . "\n";
    print "uptime: " .  $item->{uptime} . "\n";
}
