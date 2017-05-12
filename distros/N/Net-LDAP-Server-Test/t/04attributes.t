use Test::More tests => 11;

use strict;
use warnings;
use Carp;

use Net::LDAP;
use Net::LDAP::Server::Test;
use Net::LDAP::Entry;

#
# these tests pulled nearly verbatim from the Net::LDAP synopsis
#

my %opts = (port => '10636');

my $host = 'ldap://localhost:' . $opts{port};

ok( my $server = Net::LDAP::Server::Test->new( $opts{port}, auto_schema => 1 ),
    "spawn new server" );

ok( my $ldap = Net::LDAP->new( $host, %opts, ), "new LDAP connection" );

unless ($ldap) {
    my $error = $@;
    diag("stop() server");
    $server->stop();
    croak "Unable to connect to LDAP server $host: $error";
}

ok( my $rc = $ldap->bind(), "LDAP bind()" );

$ldap->add(
    dn => 'ou=test,dc=test,dc=example',
    attrs => [
        id => 'test',
        cn => [qw(cn1 cn2)],
    ],
);

sub fetch_entry {
    my $mesg;
    ok( $mesg = $ldap->search(    # perform a search
            base  => "ou=test,dc=test,dc=example",
            scope => 'base',
            filter => "id=test"
        ),
        "LDAP search()"
    );

    $mesg->code && croak $mesg->error;
    return ($mesg->entries)[0];
}

# test deleting of attribute cns
my $entry = fetch_entry;
$entry->delete(cn => ['cn2']);
$entry->update($ldap);

$entry = fetch_entry;
is_deeply([ $entry->get_value('cn') ], ['cn1']);

# test adding of attribute cns
$entry->add(cn => ['cn2']);
$entry->update($ldap);

$entry = fetch_entry;
is_deeply([ $entry->get_value('cn') ], [qw(cn1 cn2)]);

# test replacing of attribute cns
$entry->replace(cn => [qw(cn3 cn4)]);
$entry->update($ldap);

$entry = fetch_entry;
is_deeply([ $entry->get_value('cn') ], [qw(cn3 cn4)]);

ok( $ldap->unbind, "LDAP unbind()" );

