#!/usr/bin/perl

#####################################################
#
#    List all storages of the cluster
#
#####################################################

use strict;
use warnings;

use lib './lib';
use Net::Proxmox::VE;
use IO::Socket::SSL qw(SSL_VERIFY_NONE);
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
    'realm=s'    => \$realm,
);

my $pve = Net::Proxmox::VE->new(
    host     => $host,
    username => $username,
    password => $password,
    debug    => $debug,
    realm    => $realm,
    ssl_opts => {
        SSL_verify_mode => SSL_VERIFY_NONE,
        verify_hostname => 0
    },
);

die "login failed\n"          unless $pve->login;
die "invalid login ticket\n"  unless $pve->check_login_ticket;
die "unsupport api version\n" unless $pve->api_version_check;

# list nodes in cluster
my $resources = $pve->get('/cluster/resources');

for my $item( @$resources ) {
    next unless $item->{type} eq 'storage';

    print "id: " .      $item->{id} . "\n";
    print "disk: " .    $item->{disk} . "\n";
    print "maxdisk: " . $item->{maxdisk} . "\n";
    print "node: " .    $item->{node} . "\n";
    print "type: " .    $item->{type} . "\n";
    print "storage: ".  $item->{storage} . "\n";
    print "\n";
}
