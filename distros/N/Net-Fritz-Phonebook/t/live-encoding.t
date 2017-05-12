#!perl -w
use strict;
use Test::More tests => 11;
use Net::Fritz::Box;
use Net::Fritz::Phonebook;
use Data::Dumper;
 # we are dealing with UTF-8 here, so we want Dumper
 # to escape everything
$Data::Dumper::Useqq = 1;
use charnames ':full';

# Round trip test to see whether we can create, find and delete an entry
# with umlauts in its name

if( -f './fritzbox.credentials' ) {
    do './fritzbox.credentials';
};

if(! $ENV{FRITZ_HOST}) {
    SKIP: {
        skip "Live tests not run", 11;
    };
    exit
};

my $name = "Hans M\N{LATIN SMALL LETTER U WITH DIAERESIS}ller";
my $phonebookname = 'Testtelefonbuch';

binmode STDOUT, ':encoding(UTF-8)';
if( $^O =~ /mswin/i ) {
    `chcp 65001 2>&1`;
};

my $fb = Net::Fritz::Box->new(
    username => $ENV{FRITZ_USER},
    password => $ENV{FRITZ_PASS},
    upnp_url => $ENV{FRITZ_HOST},
);

my $device = $fb->discover;
if( my $error = $device->error ) {
    die $error
};

my $phonebook = Net::Fritz::Phonebook->by_name(
    device => $device,
    name => $phonebookname
);

if(! $phonebook) {
    SKIP: {
        skip "Phonebook '$phonebookname' not found", 1;
        exit
    };
};

# First, check the contact manually entered in the web UI
my $manual_number = '555-667';
my $contact = Net::Fritz::PhonebookEntry->new(
    name => "Fritz M\x{fc}ller",
);
is $contact->name, "Fritz M\x{fc}ller", "We store and retrieve the name immediately";

(my $existing) = grep { my $c = $_;
                        grep { $_->{content} eq $manual_number } @{$c->numbers}
                      } @{ $phonebook->entries };
if( isn't $existing, undef, "The manually entered contact does exist" ) {
    if( !is $existing->name, $contact->name, "The name (and encoding) match") {
        diag Dumper( $existing->name );
        diag Dumper $existing->numbers;
    };
} else {
    fail "No contact, no match on name encoding";
};

my $number = '555-666-6666-qwe';
$contact = Net::Fritz::PhonebookEntry->new(
    name => $name,
);
is $contact->name, $name, "We store and retrieve the name immediately";
$contact->add_number($number);

($existing) = grep { my $c = $_;
                        grep { $_->{content} eq $number } @{$c->numbers}
                      } @{ $phonebook->entries };
if( ! is $existing, undef, "Our contact does not yet exist" ) {
    diag "Contact already/still exists as", $existing->uniqueid;
    use Data::Dumper;
    diag Dumper( $existing->name );
    diag Dumper $existing->numbers;
};

my $error;
my $res;
if( ! eval {
    $res = $phonebook->add_entry( $contact );
    1;
}) {
    $error = $@;
};
$error ||= $res->error;
is $error, '', "We can add an entry with an umlaut";

{
# These two tests don't pass currently. It seems that entires added via TR-064
# get double-encoded on the Fritz!Box :-/
local $TODO = "Fritz!Box umlaut/UTF-8 handling for TR-064 contacts is wonky";

$phonebook->reload;
($existing) = grep { my $c = $_;
                        grep { $_->{content} eq $number } @{$c->numbers}
                      } @{ $phonebook->entries };
isn't $existing, undef, "Our contract exists now";
if(! is $existing->{name}, $name, "We retrieve the same name we wrote") {
    diag 'Got:      ' . Dumper $existing->{name};
    diag 'Expected: ' . Dumper $name;
    #print '# ' . $existing->{name}, "\n";
    #print '# ' . $name, "\n";
};

my $existing2;
my $ok = eval {
    $existing2 = $phonebook->get_entry_by_uniqueid( $existing->uniqueid );
    1
};

SKIP: {
    if( ! $ok ) {
        diag $@ if $@;
        fail "Our contact exists now";
        skip "No contact, no name to check", 2;
    } else {
        isn't $existing2, undef, "Our contact exists now";
        if(! is $existing2->{name}, $name, "We retrieve the same name we wrote") {
            diag 'Got:      ' . Dumper $existing2->{name};
            diag 'Expected: ' . Dumper $name;
        };
        ok $existing->delete, "We can delete the entry";
    };
};

}

# Now, clean up any left-over entries
$phonebook->reload;
for my $entry (reverse @{ $phonebook->entries }) {
    NUMBER: for my $num (@{ $entry->numbers }) {
        if( $num->content eq $number ) {
            $entry->delete;
            last NUMBER;
        };
    };
};
