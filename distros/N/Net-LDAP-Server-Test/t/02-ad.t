use Test::More tests => 6;

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

#
#   TODO front-load real AD data with schema.
#
#
ok( my $server
        = Net::LDAP::Server::Test->new( $opts{port}, active_directory => 1, ),
    "spawn new server"
);

ok( my $ldap = Net::LDAP->new( $host, %opts, ), "new LDAP connection" );

unless ($ldap) {
    my $error = $@;
    diag("stop() server");
    $server->stop();
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

# quit
ok( $mesg = $ldap->unbind, "LDAP unbind()" );
