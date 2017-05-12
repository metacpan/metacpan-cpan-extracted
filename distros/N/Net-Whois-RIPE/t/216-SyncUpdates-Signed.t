use strict;
use warnings;
use Test::More;
use Net::Whois::RIPE;
use Net::Whois::Object;

our $LWP;
BEGIN {
    $LWP = do {
        eval {
            require LWP::UserAgent;
        };
        ($@) ? 0 : 1;
    };
}

unless ( $ENV{TEST_MNTNER} && $ENV{TEST_MNTNER_PGPKEY} ) {
    warn(<<'WARNING');

Set TEST_MNTNER, TEST_MNTNER_PGPKEY environment vars for live testing
    TEST_MNTNER being a maintener's nic-hdl in the RIPE test database
    TEST_MNTNER_PGPKEY being the key ID of an key-cert associated with
    the maintainer object
WARNING
    plan skip_all => ' Set environment vars for server testing';
}

unless ($LWP) {
    plan skip_all => 'LWP::UserAgent installation required for update';
}

plan tests => 5;

my $MNTNER = $ENV{TEST_MNTNER};
my $PGPKEY = $ENV{TEST_MNTNER_PGPKEY};

my @lines = <DATA>;
map {s/MNTNER/$MNTNER/} @lines;

my @o      = Net::Whois::Object->new(@lines);
my $person = shift @o;
my $mntner = shift @o;

my $email_before = $person->e_mail()->[0];

my $person_id = $person->syncupdates_create( { pgpkey => $PGPKEY } );
ok($person_id);

my $whois = Net::Whois::RIPE->new( hostname => 'whois-test.ripe.net' );
my $iterator = $whois->query($person_id);

($person) = grep { ( $_->class() eq 'Person' ) and ( $_->nic_hdl eq $person_id ) } Net::Whois::Object->new($iterator);

is_deeply( $person->e_mail(), [$email_before], "Same name from previous" );
my $email_after = $person->e_mail('arhuman2@gmail.com');

$person->syncupdates_update( { pgpkey => $PGPKEY } );

$iterator = $whois->query($person_id);
($person) = grep { ( $_->class() eq 'Person' ) and ( $_->nic_hdl eq $person_id ) } Net::Whois::Object->new($iterator);

is_deeply( $person->e_mail(), $email_after, "Same as set name" );

isa_ok( $person, 'Net::Whois::Object::Person', 'Found a Person' );

$person->syncupdates_delete( { pgpkey => $PGPKEY } );

$whois = Net::Whois::RIPE->new( hostname => 'whois-test.ripe.net' );
$iterator = $whois->query($person_id);

($person) = grep { $_->class() eq 'Response' } Net::Whois::Object->new($iterator);

like( $person->response, qr/ERROR:101:/, 'Deleted Person not found' );

__DATA__
person: Joh Doe
address: 1 Avenue de la Gare
address: 75001 Paris
phone: +33 1 01 01 01 01
e-mail: arhuman@gmail.com
nic-hdl: AUTO-1
mnt-by: MNTNER
changed: arhuman@gmail.com 
source: TEST

