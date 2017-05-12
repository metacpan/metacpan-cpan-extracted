#!/usr/bin/env perl

use strict;
use warnings;
use Carp;
use Test::More tests => 14;
use Net::LDAP::Server::Test;
use Net::LDAP;
use Net::LDAP::LDIF;
use File::Temp qw(tempfile);
use Net::LDAP::Constant qw(
    LDAP_SUCCESS
    LDAP_NO_SUCH_OBJECT
    LDAP_CONTROL_PAGED
    LDAP_OPERATIONS_ERROR
    LDAP_UNWILLING_TO_PERFORM
    LDAP_ALREADY_EXISTS
    LDAP_TYPE_OR_VALUE_EXISTS
    LDAP_NO_SUCH_ATTRIBUTE
);

# dev help only
for my $const (
    qw(
    LDAP_SUCCESS
    LDAP_NO_SUCH_OBJECT
    LDAP_CONTROL_PAGED
    LDAP_OPERATIONS_ERROR
    LDAP_UNWILLING_TO_PERFORM
    LDAP_ALREADY_EXISTS
    LDAP_TYPE_OR_VALUE_EXISTS
    LDAP_NO_SUCH_ATTRIBUTE
    )
    )
{
    diag( "$const==" . Net::LDAP::Constant->$const );
}

# Create ldif
my $ldif_entries = <<EOL;
dn: app=test
app: test
objectClass: top
objectClass: application

dn: msisdn=34610123123,app=test
objectClass: msisdn
msisdn: 34610123123

dn: msisdn=34699123456,app=test
objectClass: msisdn
msisdn: 34699123456

EOL

my ( $fh, $filename ) = tempfile();
print $fh $ldif_entries;
close $fh;

my $port = '12389';
my $host = 'ldap://localhost:' . $port;

# Create and connect to server
ok( my $server = Net::LDAP::Server::Test->new( $port, auto_schema => 1 ),
    "test LDAP server spawned" );
ok( my $ldap = Net::LDAP->new($host), "new LDAP connection" );

unless ($ldap) {
    my $error = $@;
    diag("stop() server");
    $server->stop();
    croak "Unable to connect to LDAP server $host: $error";
}

# Load ldif
my $ldif = Net::LDAP::LDIF->new(
    $filename, 'r',
    onerror   => 'die',
    lowercase => 1
);
while ( not $ldif->eof ) {
    my $entry = $ldif->read_entry or die "Unable to parse entry";
    my $mesg = $ldap->add($entry);
    $mesg->code
        and die sprintf "Error adding entry [%s]: [%s]", $entry->dn,
        $mesg->error;
}
$ldif->done;

# Add an existing entry should return 68
my $mesg = $ldap->add( 'msisdn=34610123123,app=test',
    attr => [ objectClass => ['msisdn'], msisdn => 34610123123 ] );
is( $mesg->code, LDAP_ALREADY_EXISTS, 'add error' );

# Base search ok
$mesg = $ldap->search(
    base   => 'msisdn=34610123123,app=test',
    scope  => 'base',
    filter => 'objectClass=*'
);
is( $mesg->code, LDAP_SUCCESS, 'msisdn found' );

# A base search to a non-existing entry should return 32
$mesg = $ldap->search(
    base   => 'msisdn=123456789,app=test',
    scope  => 'base',
    filter => 'objectClass=*'
);
is( $mesg->code, LDAP_NO_SUCH_OBJECT, 'msisdn not found' );
is( scalar( $mesg->entries ), 0, 'number of entries equals zero' );

# Modify a non-existing entry should return 32
$mesg = $ldap->modify( 'msisdn=123456789,app=test',
    add => { newattr => 'lala' } );
is( $mesg->code, LDAP_NO_SUCH_OBJECT, 'cannot modify a not existing entry' );

# Modify ok to an existing entry
$mesg = $ldap->modify( 'msisdn=34610123123,app=test',
    add => { newattr => 'lala' } );
is( $mesg->code, LDAP_SUCCESS, 'mod done' );

# Modify-add to an existing attribute should return 20
$mesg = $ldap->modify( 'msisdn=34610123123,app=test',
    add => { newattr => 'lala' } );
is( $mesg->code, LDAP_TYPE_OR_VALUE_EXISTS, 'mod fails' );

# Modify-delete ok
$mesg = $ldap->modify( 'msisdn=34610123123,app=test', delete => ['newattr'] );
is( $mesg->code, LDAP_SUCCESS, 'mod ok' );

# Modify-delete to a non-existing attribute should return 16
$mesg = $ldap->modify( 'msisdn=34610123123,app=test', delete => ['newattr'] );
is( $mesg->code, LDAP_NO_SUCH_ATTRIBUTE, 'mod fails' );

# Moddn ok
$mesg = $ldap->moddn(
    'msisdn=34699123456,app=test',
    newrdn       => 'msisdn=34699000111',
    deleteoldrdn => 1
);
is( $mesg->code, LDAP_SUCCESS, 'moddn ok' );

# Moddn on a non-existing entry should return 32
$mesg = $ldap->moddn( 'msisdn=34699123456,app=test',
    newrdn => 'msisdn=34699000111' );
is( $mesg->code, LDAP_NO_SUCH_OBJECT, 'moddn ok' );

# Moddn to an existing dn should return 68
$mesg = $ldap->moddn(
    'msisdn=34699000111,app=test',
    newrdn       => 'msisdn=34610123123',
    deleteoldrdn => 1
);
is( $mesg->code, LDAP_ALREADY_EXISTS, 'moddn fails' );
