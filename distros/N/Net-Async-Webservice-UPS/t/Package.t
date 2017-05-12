#!perl
use strict;
use warnings;
use 5.010;
use lib 't/lib';
use Test::Most;
use Net::Async::Webservice::UPS::Package;

my @data = (
    # english / imperial

    { width => 10, length => 20, height => 30, weight => 40,
      measurement_system => 'english',
      oversized => 0, comment => 'ok' },

    { width => 10, length => 20, height => 30, weight => 180,
      measurement_system => 'english',
      fail => 1, comment => 'too heavy' },
    { width => 100, length => 20, height => 20, weight => 40,
      measurement_system => 'english',
      fail => 1, comment => 'excessive girth' },
    { width => 110, length => 10, height => 10, weight => 40,
      measurement_system => 'english',
      fail => 1, comment => 'excessive length' },

    { width => 20, length => 15, height => 20, weight => 20,
      measurement_system => 'english',
      oversized => 1, comment => 'OS1' },
    { width => 20, length => 25, height => 24, weight => 40,
      measurement_system => 'english',
      oversized => 2, comment => 'OS2' },
    { width => 30, length => 30, height => 25, weight => 40,
      measurement_system => 'english',
      oversized => 3, comment => 'OS3' },

    { width => 20, length => 15, height => 20, weight => 40,
      measurement_system => 'english',
      oversized => 0, comment => 'not OS1 due to weight' },
    { width => 20, length => 25, height => 24, weight => 80,
      measurement_system => 'english',
      oversized => 0, comment => 'not OS2 due to weight' },
    { width => 30, length => 30, height => 25, weight => 100,
      measurement_system => 'english',
      oversized => 0, comment => 'not OS3 due to weight' },

    { width => 1, length => 2, height => 100, weight => 20,
      measurement_system => 'english',
      oversized => 1, comment => 'check for size sorting' },

    # metric

    { width => 25, length => 50, height => 75, weight => 18,
      measurement_system => 'metric',
      oversized => 0, comment => 'ok' },

    { width => 25, length => 50, height => 75, weight => 81,
      measurement_system => 'metric',
      fail => 1, comment => 'too heavy' },
    { width => 250, length => 50, height => 50, weight => 18,
      measurement_system => 'metric',
      fail => 1, comment => 'excessive girth' },
    { width => 280, length => 25, height => 25, weight => 18,
      measurement_system => 'metric',
      fail => 1, comment => 'excessive length' },

    { width => 50, length => 38, height => 50, weight => 9,
      measurement_system => 'metric',
      oversized => 1, comment => 'OS1' },
    { width => 50, length => 63, height => 61, weight => 18,
      measurement_system => 'metric',
      oversized => 2, comment => 'OS2' },
    { width => 75, length => 75, height => 63, weight => 18,
      measurement_system => 'metric',
      oversized => 3, comment => 'OS3' },

    { width => 50, length => 38, height => 50, weight => 18,
      measurement_system => 'metric',
      oversized => 0, comment => 'not OS1 due to weight' },
    { width => 50, length => 63, height => 61, weight => 36,
      measurement_system => 'metric',
      oversized => 0, comment => 'not OS2 due to weight' },
    { width => 75, length => 75, height => 63, weight => 45,
      measurement_system => 'metric',
      oversized => 0, comment => 'not OS3 due to weight' },

    { width => 2, length => 5, height => 250, weight => 9,
      measurement_system => 'metric',
      oversized => 1, comment => 'check for size sorting' },

    # mixed

    { width => 10, length => 20, height => 30, weight => 18,
      weight_unit => 'KGS', linear_unit => 'IN',
      oversized => 0, comment => 'ok' },

    { width => 25, length => 50, height => 75, weight => 180,
      weight_unit => 'LBS', linear_unit => 'CM',
      fail => 1, comment => 'too heavy' },
    { width => 100, length => 20, height => 20, weight => 18,
      weight_unit => 'KGS', linear_unit => 'IN',
      fail => 1, comment => 'excessive girth' },
    { width => 280, length => 25, height => 25, weight => 40,
      weight_unit => 'LBS', linear_unit => 'CM',
      fail => 1, comment => 'excessive length' },

    { width => 20, length => 15, height => 20, weight => 9,
      weight_unit => 'KGS', linear_unit => 'IN',
      oversized => 1, comment => 'OS1' },
    { width => 50, length => 63, height => 61, weight => 40,
      weight_unit => 'LBS', linear_unit => 'CM',
      oversized => 2, comment => 'OS2' },
    { width => 30, length => 30, height => 25, weight => 18,
      weight_unit => 'KGS', linear_unit => 'IN',
      oversized => 3, comment => 'OS3' },

    { width => 50, length => 38, height => 50, weight => 40,
      weight_unit => 'LBS', linear_unit => 'CM',
      oversized => 0, comment => 'not OS1 due to weight' },
    { width => 20, length => 25, height => 24, weight => 36,
      weight_unit => 'KGS', linear_unit => 'IN',
      oversized => 0, comment => 'not OS2 due to weight' },
    { width => 75, length => 75, height => 63, weight => 100,
      weight_unit => 'LBS', linear_unit => 'CM',
      oversized => 0, comment => 'not OS3 due to weight' },

    { width => 1, length => 2, height => 100, weight => 9,
      weight_unit => 'KGS', linear_unit => 'IN',
      oversized => 1, comment => 'check for size sorting' },
);

for my $d (@data) {
    my ($oversized,$fail,$comment) =
        (delete @$d{qw(oversized fail comment)});

    my $p = Net::Async::Webservice::UPS::Package->new($d);

    if ($fail) {
        throws_ok {
            $p->is_oversized;
        } 'Net::Async::Webservice::UPS::Exception::BadPackage',
            "$comment - expected failure";
    }
    else {
        is($p->is_oversized,$oversized,
           "$comment - expected oversized class");
    }
}

done_testing();
