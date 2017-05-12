#!/usr/bin/env perl

use strict;
use warnings;
use Carp;
use Test::More;

use Net::LDAP;
use Net::LDAP::Server::Test;

my $port = 1024 + int rand(10000) + $$ % 1024;
my $host = 'ldap://localhost:' . $port;

ok( my $server = Net::LDAP::Server::Test->new( $port, auto_schema => 1 ),
    "spawn new server" );
ok( my $ldap = Net::LDAP->new($host), "new LDAP connection" );

unless ($ldap) {
    my $error = $@;
    diag("stop() server");
    $server->stop();
    croak "Unable to connect to LDAP server $host: $error";
}

ok( my $rc = $ldap->bind(), "LDAP bind()" );

my @scopes = qw(base one sub);

# Add our nested DNs
my $dn = my $base = "dc=example,dc=com";
for my $level (@scopes) {
    $dn = "cn=$level group,$dn";
    my $result = $ldap->add(
        $dn,
        attr => [
            cn          => "$level group",
            objectClass => 'Group',
        ],
    );
    ok !$result->code, "added $dn: " . $result->error;
}

# Do scopes work?
my %expected = (
    'base' => [qw(base)],
    'one'  => [qw(one)],
    'sub'  => [qw(base one sub)],
);

for my $scope (@scopes) {
    my $cns   = $expected{$scope};
    my $count = scalar @$cns;
    my $msg   = $ldap->search(
        base   => "cn=base group,$base",
        scope  => $scope,
        filter => '(objectClass=group)',
    );
    ok $msg, "searched with scope $scope";
    is $msg->count, $count, "found $count";

    my %want  = map { ( "$_ group"          => 1 ) } @$cns;
    my %found = map { ( $_->get_value('cn') => 1 ) } $msg->entries;
    is( ( scalar grep { !$found{$_} } keys %want ),
        0, "found all expected CNs" );
    is( ( scalar grep { !$want{$_} } keys %found ),
        0, "expected all found CNs" );

    # test that filters apply correctly on all scopes
    $msg = $ldap->search(
        base   => "cn=base group,$base",
        scope  => $scope,
        filter => '(objectClass=404)',
    );
    ok $msg, "searched with scope $scope with a non-matching filter";
    is $msg->count, 0, "found no entries";
}

ok $ldap->unbind, "unbound";
done_testing;
