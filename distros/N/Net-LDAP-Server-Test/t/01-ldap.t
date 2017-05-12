#!/usr/bin/env perl

use Test::More tests => 12;

use strict;
use warnings;
use Carp;

use Net::LDAP;
use Net::LDAP::Server::Test;
use Net::LDAP::Entry;

#
# these tests pulled nearly verbatim from the Net::LDAP synopsis
#

my %opts = (
    port  => '10636',
    dnc   => 'ou=internal,dc=foo',
    debug => $ENV{PERL_DEBUG} || 0,
);

my $host = 'ldap://localhost:' . $opts{port};

ok( my $server = Net::LDAP::Server::Test->new( $opts{port} ),
    "spawn new server" );

ok( my $ldap = Net::LDAP->new( $host, %opts, ), "new LDAP connection" );

unless ($ldap) {
    my $error = $@;
    if ($server) {
        diag("stop() server");
        $server->stop();
    }
    croak "Unable to connect to LDAP server $host: $error";
}

ok( my $rc = $ldap->bind(), "LDAP bind()" );

ok( my $mesg = $ldap->search(    # perform a search
        base   => "c=US",
        filter => "(&(sn=Barr) (o=Texas Instruments))"
    ),
    "LDAP search()"
);

$mesg->code && croak $mesg->error;

my $count = 0;
foreach my $entry ( $mesg->entries ) {

    #$entry->dump;
    $count++;
}

is( $count, 13, "$count entries found in search" );

ok( $mesg = $ldap->unbind, "LDAP unbind()" );

#warn "unbind done";

my @mydata;
my $entry = Net::LDAP::Entry->new;
$entry->dn('ou=foobar');
$entry->add(
    dn => 'ou=foobar',
    sn => 'value1',
    cn => [qw(value1 value2)]
);
push @mydata, $entry;

# RT 69615
diag("stop() server");
$server->stop();

ok( $server = Net::LDAP::Server::Test->new( $opts{port}, data => \@mydata ),
    "spawn new server with our own data" );

ok( $ldap = Net::LDAP->new( $host, %opts, ), "new LDAP connection" );

unless ($ldap) {
    croak "Unable to connect to LDAP server $host: $@";
}

ok( $rc = $ldap->bind(), "LDAP bind()" );

ok( $mesg = $ldap->search(    # perform a search
        base   => "c=US",
        filter => "(&(sn=Barr) (o=Texas Instruments))"
    ),
    "LDAP search()"
);

$mesg->code && croak $mesg->error;

$count = 0;
foreach my $entry ( $mesg->entries ) {

    #$entry->dump;
    $count++;
}

is( $count, 1, "$count entries found in search" );

ok( $mesg = $ldap->unbind, "LDAP unbind()" );

