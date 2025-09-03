#!/usr/bin/perl

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

sub totp {
    my %args = @_;
    # Use these to look up or prompt
    for my $k (qw/ username realm host /) {
        printf("%s: %s\n", $k, $args{$k})
    }
    # Don't do this, its just an example
    my $code = `echo password|keepassxc-cli show -q -t ~/vault.kdbx "Testing/pve"`;
    chomp $code;
    return $code
}

my $pve = Net::Proxmox::VE->new(
    host     => $host,
    username => $username,
    password => $password,
    debug    => $debug,
    realm    => $realm,
    totp     => \&totp,
    ssl_opts => {
        SSL_verify_mode => SSL_VERIFY_NONE,
        verify_hostname => 0
    },
);

die "login failed\n"          unless $pve->login;
die "invalid login ticket\n"  unless $pve->check_login_ticket;
die "unsupport api version\n" unless $pve->api_version_check;

# list nodes in cluster
print $pve->get('/nodes')
    ? "INFO: List Nodes Successful\n"
    : "WARNING: List Nodes Failed\n";
