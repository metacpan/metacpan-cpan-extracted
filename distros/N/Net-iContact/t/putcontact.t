#!perl -T
use strict;

use Test::More tests => 2;
use Net::iContact;

SKIP: {
    skip 'no api login info found', 2 unless (open(FH, '< apiinfo') and $_=<FH>);
    skip 'will not create contacts', 2 unless (exists($ENV{TESTALL}));

    chomp;
    my ($user, $pass, $key, $secret) = split(/:/);
    my $api = Net::iContact->new($user,$pass,$key,$secret);
    my $ret = $api->login();

    my %contact = ( 'fname' => 'Stan', 'email' => 'lol@example.com' );

    my $contactid = $api->putcontact(\%contact);
    ok($contactid =~ /\d+/, 'contact created');

    $contact{'fname'} = 'Kenny';
    $contactid = $api->putcontact(\%contact, $contactid);

    my $contact = $api->contact($contactid);
    ok($contact->{'fname'} eq 'Kenny');
}

