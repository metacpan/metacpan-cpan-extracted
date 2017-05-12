#!perl -T
use strict;

use Test::More tests => 13;
use Net::iContact;

SKIP: {
    skip 'no api login info found', 13 unless (open(FH, '< apiinfo') and $_=<FH>);

    chomp;
    my ($user, $pass, $key, $secret) = split(/:/);
    my $api = Net::iContact->new($user,$pass,$key,$secret);
    $api->login or die("Failed to log in");
    my $seq = $api->seq;

### Test contacts()
    my $contacts = $api->contacts;
    ## That call should have incremented the sequence number..
    ok($api->seq == $seq+1);
    ## This contact exists in the test account
    ok(grep(775201, @$contacts));
    ## This contact does not.
    ok(grep(1, @$contacts));

    $contacts = $api->contacts('email' => '*@example.com');
    ## 695535 has an @example.com address
    ok(grep(695535, @$contacts));

    $contacts = $api->contacts('email' => 'aoeu@aoeu'); # Won't match a thing.
    my $f=1;
    for my $id (@$contacts) {
        $f=0;
        ok(0, 'returned a list with >0 elements');
    }
    ok($f, 'returned an empty list');


### contact()
    my $contact = $api->contact(695535);
    ok($api->seq == $seq+4);
    ok($contact->{fname} eq 'Test');

### subscriptions()
    my $subscriptions = $api->subscriptions(695535);
    ok($subscriptions->{1936} eq 'subscribed');

### custom_fields()
    my $custom_fields = $api->custom_fields(695535);
    ok($custom_fields->{hatsize}->{formal_name} eq 'Describe the dimensions of your head');
    ok($custom_fields->{hatsize}->{type} eq 'interest');
    ok($custom_fields->{hatsize}->{value} == 1);
    ok($custom_fields->{fishtype}->{value} eq '');
    ok($custom_fields->{fishtype}->{type} eq 'custom');
}
