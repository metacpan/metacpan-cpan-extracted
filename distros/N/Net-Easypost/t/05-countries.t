#!/usr/bin/env perl

use strict;
use warnings;

use Net::Easypost;
use Net::Easypost::Address;
use Net::Easypost::Parcel;
use Net::Easypost::Rate;
use Test::More tests => 9;

$ENV{EASYPOST_API_KEY} = 'Ao0vbSp2P0cbEhQd8HjEZQ';

if (!eval { require Socket; Socket::inet_aton('www.easypost.com') }) {
    plan skip_all => "Cannot connect to the API server";
}

# 60 second connection timeout
$ENV{MOJO_CONNECT_TIMEOUT} = 60;

my $easypost = Net::Easypost->new;

my @us_rates = get_rates('US', 22902, 100);
my @it_rates = get_rates('IT', 22902, 100);

# the first cheaper can't have the same price
my $us_cheapest = shift(@us_rates);
my $it_cheapest = shift(@it_rates);

isnt($us_cheapest->rate, $it_cheapest->rate,
     describe_rate($us_cheapest) . " can't be equal to " .
     describe_rate($it_cheapest));


my $verified = $easypost->verify_address(
   { street1 => '388 Townsend St',
     street2 => 'Apt 20',
     city    => 'San Francisco',
     zip     => '94107',
     name    => 'Zaphod',
   }
);

is($verified->country, 'US', 'Verified country is US');
ok($verified, 'US address verified ok');

$verified->country('IT');
is($verified->country, 'IT', 'Verified country is IT');
ok($easypost->verify_address($verified), 'IT address verified ok');


sub get_rates {
    my ($country, $zip, $ounces) = @_;

    my $from = $easypost->verify_address(
        { street1 => '388 Townsend St',
          street2 => 'Apt 20',
          city    => 'San Francisco',
          zip     => '94107',
          name    => 'Zaphod',
        }
    );

    # default to US
    is($from->country, 'US');
    my $to = Net::Easypost::Address->new(
        zip     => $zip,
        country => $country,
    );
    is($to->country, $country, "Country is $country");

    my $parcel = Net::Easypost::Parcel->new(
        weight => $ounces,
    );

    my $rates = $easypost->get_rates(
        { to     => $to,
          from   => $from,
          parcel => $parcel
        }
    );

    return sort { $a->rate <=> $b->rate } @$rates;
}

sub describe_rate {
    my $rate = shift;
    return join(" ", $rate->carrier, $rate->service, $rate->rate);
}


