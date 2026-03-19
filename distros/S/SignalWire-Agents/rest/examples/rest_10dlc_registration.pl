#!/usr/bin/env perl
# Example: 10DLC brand and campaign compliance registration.
#
# WARNING: This example interacts with the real 10DLC registration system.
# Brand and campaign registrations may have side effects and costs.
#
# Set these env vars:
#   SIGNALWIRE_PROJECT_ID   - your SignalWire project ID
#   SIGNALWIRE_API_TOKEN    - your SignalWire API token
#   SIGNALWIRE_SPACE        - your SignalWire space (e.g. example.signalwire.com)

use strict;
use warnings;
use lib 'lib';
use SignalWire::Agents::REST::SignalWireClient;

my $client = SignalWire::Agents::REST::SignalWireClient->new(
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

# 1. Register a brand
print "Registering 10DLC brand...\n";
my $brand = safe('Brand', sub {
    $client->registry->brands->create(
        company_name => 'Acme Corp',
        ein          => '12-3456789',
        entity_type  => 'PRIVATE_PROFIT',
        vertical     => 'TECHNOLOGY',
        website      => 'https://acme.example.com',
        country      => 'US',
    );
});
my $brand_id = $brand ? $brand->{id} : undef;

# 2. List brands
print "\nListing brands...\n";
my $brands = safe('List brands', sub { $client->registry->brands->list });
if ($brands) {
    for my $b (@{ $brands->{data} // [] }) {
        print "  - $b->{id}: " . ($b->{name} // 'unnamed') . "\n";
    }
    if (!$brand_id && $brands->{data} && @{ $brands->{data} }) {
        $brand_id = $brands->{data}[0]{id};
    }
}

# 3. Get brand details
if ($brand_id) {
    my $detail = safe('Brand detail', sub { $client->registry->brands->get($brand_id) });
    if ($detail) {
        print "\nBrand detail: " . ($detail->{name} // 'N/A')
            . " (" . ($detail->{state} // 'N/A') . ")\n";
    }
}

# 4. Create a campaign under the brand
my $campaign_id;
if ($brand_id) {
    print "\nCreating campaign...\n";
    my $campaign = safe('Campaign', sub {
        $client->registry->brands->create_campaign(
            $brand_id,
            use_case       => 'MIXED',
            description    => 'Customer notifications and support messages',
            sample_message => 'Your order #12345 has shipped.',
        );
    });
    $campaign_id = $campaign ? $campaign->{id} : undef;
}

# 5. List campaigns for the brand
if ($brand_id) {
    print "\nListing brand campaigns...\n";
    my $campaigns = safe('List campaigns', sub {
        $client->registry->brands->list_campaigns($brand_id);
    });
    if ($campaigns) {
        for my $c (@{ $campaigns->{data} // [] }) {
            print "  - $c->{id}: " . ($c->{name} // 'unknown') . "\n";
            $campaign_id //= $c->{id};
        }
    }
}

# 6. Get and update campaign
if ($campaign_id) {
    my $camp_detail = safe('Get campaign', sub {
        $client->registry->campaigns->get($campaign_id);
    });
    if ($camp_detail) {
        print "\nCampaign: " . ($camp_detail->{name} // 'N/A')
            . " (" . ($camp_detail->{state} // 'N/A') . ")\n";
    }
    safe('Update campaign', sub {
        $client->registry->campaigns->update(
            $campaign_id, description => 'Updated: customer notifications',
        );
    });
}

# 7. Create an order to assign numbers
my $order_id;
if ($campaign_id) {
    print "\nCreating number assignment order...\n";
    my $order = safe('Order', sub {
        $client->registry->campaigns->create_order(
            $campaign_id, phone_numbers => ['+15125551234'],
        );
    });
    $order_id = $order ? $order->{id} : undef;
}

# 8. Get order status
if ($order_id) {
    my $order_detail = safe('Order status', sub {
        $client->registry->orders->get($order_id);
    });
    if ($order_detail) {
        print "  Order status: " . ($order_detail->{status} // 'N/A') . "\n";
    }
}

# 9. List campaign numbers and orders
if ($campaign_id) {
    print "\nListing campaign numbers...\n";
    my $numbers = safe('List numbers', sub {
        $client->registry->campaigns->list_numbers($campaign_id);
    });
    if ($numbers) {
        for my $n (@{ $numbers->{data} // [] }) {
            print "  - " . ($n->{phone_number} // $n->{id} // 'unknown') . "\n";
        }
    }

    my $orders = safe('List orders', sub {
        $client->registry->campaigns->list_orders($campaign_id);
    });
    if ($orders) {
        for my $o (@{ $orders->{data} // [] }) {
            print "  - Order $o->{id}: " . ($o->{status} // 'unknown') . "\n";
        }
    }
}

# 10. Unassign numbers (clean up)
if ($campaign_id) {
    print "\nUnassigning numbers...\n";
    my $nums = safe('Get numbers', sub {
        $client->registry->campaigns->list_numbers($campaign_id);
    });
    if ($nums) {
        for my $n (@{ $nums->{data} // [] }) {
            safe("Unassign $n->{id}", sub {
                $client->registry->numbers->delete($n->{id});
            });
        }
    }
}
