#!/usr/bin/env perl
# Example: Full phone number inventory lifecycle.
#
# Set these env vars:
#   SIGNALWIRE_PROJECT_ID   - your SignalWire project ID
#   SIGNALWIRE_API_TOKEN    - your SignalWire API token
#   SIGNALWIRE_SPACE        - your SignalWire space

use strict;
use warnings;
use lib 'lib';
use SignalWire::REST::RestClient;

my $client = SignalWire::REST::RestClient->new(
    project => $ENV{SIGNALWIRE_PROJECT_ID} // die("Set SIGNALWIRE_PROJECT_ID\n"),
    token   => $ENV{SIGNALWIRE_API_TOKEN}  // die("Set SIGNALWIRE_API_TOKEN\n"),
    host    => $ENV{SIGNALWIRE_SPACE}      // die("Set SIGNALWIRE_SPACE\n"),
);

sub safe {
    my ($label, $fn) = @_;
    my $result = eval { $fn->() };
    if ($@) {
        print "  $label: failed ($@)\n";
        return undef;
    }
    print "  $label: OK\n";
    return $result;
}

# 1. Search for available phone numbers
print "Searching available numbers...\n";
my $available = safe('Search', sub {
    $client->phone_numbers->search(area_code => '512', max_results => 3);
});
if ($available) {
    for my $num (@{ $available->{data} // [] }) {
        print "  - " . ($num->{e164} // $num->{number} // 'unknown') . "\n";
    }
}

# 2. Purchase a number
print "\nPurchasing a phone number...\n";
my $num_id;
my $number = safe('Purchase', sub {
    my $first = ($available->{data} // [{}])->[0] // {};
    $client->phone_numbers->create(number => ($first->{e164} // '+15125551234'));
});
$num_id = $number ? $number->{id} : undef;

# 3. List and get owned numbers
print "\nListing owned numbers...\n";
my $owned = safe('List', sub { $client->phone_numbers->list });
if ($owned) {
    my @data = @{ $owned->{data} // [] };
    for my $n (@data[0 .. ($#data < 4 ? $#data : 4)]) {
        print "  - " . ($n->{number} // 'unknown') . " ($n->{id})\n";
    }
}
if ($num_id) {
    my $detail = safe('Get', sub { $client->phone_numbers->get($num_id) });
    print "  Detail: " . ($detail->{number} // 'N/A') . "\n" if $detail;
}

# 4. Update a number
if ($num_id) {
    print "\nUpdating number $num_id...\n";
    safe('Update', sub { $client->phone_numbers->update($num_id, name => 'Main Line') });
}

# 5. Create a number group
print "\nCreating number group...\n";
my $group_id;
my $group = safe('Create group', sub { $client->number_groups->create(name => 'Sales Pool') });
$group_id = $group ? $group->{id} : undef;

# 6. Add a membership
if ($group_id && $num_id) {
    print "\nAdding number to group...\n";
    my $mem_id;
    safe('Add membership', sub {
        my $membership = $client->number_groups->add_membership(
            $group_id, phone_number_id => $num_id,
        );
        $mem_id = $membership->{id};
        print "  Membership: $mem_id\n" if $mem_id;

        my $memberships = $client->number_groups->list_memberships($group_id);
        for my $m (@{ $memberships->{data} // [] }) {
            print "  - Member: " . ($m->{id} // 'unknown') . "\n";
        }
    });
}

# 7. Lookup carrier info
print "\nLooking up carrier info...\n";
safe('Lookup', sub {
    my $info = $client->lookup->phone_number('+15125551234');
    print "  Carrier: " . (($info->{carrier} // {})->{name} // 'unknown') . "\n";
});

# 8. Create a verified caller
print "\nCreating verified caller...\n";
my $caller_id;
safe('Verified caller', sub {
    my $caller = $client->verified_callers->create(phone_number => '+15125559999');
    $caller_id = $caller->{id};
    print "  Created verified caller: $caller_id\n";
    $client->verified_callers->submit_verification($caller_id, verification_code => '123456');
    print "  Verification code submitted\n";
});

# 9. Get and update SIP profile
print "\nGetting SIP profile...\n";
safe('SIP profile', sub {
    my $profile = $client->sip_profile->get;
    print "  SIP profile: " . (ref $profile ? 'OK' : $profile) . "\n";
    $client->sip_profile->update(default_codecs => ['PCMU', 'PCMA']);
    print "  Updated SIP codecs\n";
});

# 10. List short codes
print "\nListing short codes...\n";
safe('Short codes', sub {
    my $codes = $client->short_codes->list;
    for my $sc (@{ $codes->{data} // [] }) {
        print "  - " . ($sc->{short_code} // 'unknown') . "\n";
    }
});

# 11. Create an address
print "\nCreating address...\n";
my $addr_id;
safe('Address', sub {
    my $addr = $client->addresses->create(
        friendly_name => 'HQ Address',
        street        => '123 Main St',
        city          => 'Austin',
        region        => 'TX',
        postal_code   => '78701',
        iso_country   => 'US',
    );
    $addr_id = $addr->{id};
    print "  Created address: $addr_id\n";
});

# 12. Clean up
print "\nCleaning up...\n";
safe('Delete address',         sub { $client->addresses->delete($addr_id) })          if $addr_id;
safe('Delete verified caller', sub { $client->verified_callers->delete($caller_id) }) if $caller_id;
safe('Delete number group',    sub { $client->number_groups->delete($group_id) })     if $group_id;
safe('Release number',         sub { $client->phone_numbers->delete($num_id) })       if $num_id;
