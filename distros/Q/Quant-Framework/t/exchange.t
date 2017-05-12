#!/usr/bin/perl

use Test::Most;
use Test::MockModule;
use Test::FailWarnings;
use File::ShareDir ();
use JSON qw(decode_json);
use YAML::XS qw(LoadFile);

use Quant::Framework::Exchange;

# all the exchange in the yaml
my $exchanges = LoadFile(File::ShareDir::dist_file('Quant-Framework', 'exchange.yml'));

subtest 'exchange currency and OTC check' => sub {
    my %undef_currency_exchanges = (
        RANDOM          => 1,
        FOREX           => 1,
        METAL           => 1,
        RANDOM_NOCTURNE => 1
    );
    foreach my $exchange (keys %$exchanges) {
        my $qf_exchange = Quant::Framework::Exchange->new($exchange);

        if ($undef_currency_exchanges{$exchange}) {
            ok !$exchanges->{$exchange}->{currency}, "currency undef for $exchange";

            ok !$qf_exchange->currency, "currency undef for $exchange";
        } else {
            ok $exchanges->{$exchange}->{currency}, "currency defined for $exchange";

            ok $qf_exchange->currency, "currency defined for $exchange";
        }
    }
};

done_testing;

1;
