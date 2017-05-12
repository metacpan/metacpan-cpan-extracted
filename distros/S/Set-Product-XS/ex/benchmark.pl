#!/usr/bin/env perl
use strict;
use warnings;

use Algorithm::Loops qw(NestedLoops);
use Benchmark::Dumb qw(:all);
use List::Gen ();
use Math::Cartesian::Product 1.009 ();
use Set::CrossProduct;
use Set::Product::PP ();
use Set::Product::XS ();
use Set::Scalar;

my @set = (
    [qw(one two three four)],
    [qw(a b c d e)],
    [qw(foo bar blah)],
    [1..5], [1..3], [1..4]
);

cmpthese 0, {
    'Set::CrossProduct' => sub {
        my $it = Set::CrossProduct->new(\@set);
        while (my @s = $it->get) {
            my $str = "@s";
        }
    },
    'List::Gen' => sub {
        my $it = List::Gen::cartesian { @_ } @set;
        while (my @s = $it->next) {
            my $str = "@s";
        }
    },
    'Set::Scalar' => sub {
        my $it = Set::Scalar->cartesian_product_iterator(
            map { Set::Scalar->new(@$_) } @set
        );
        while (my @s = $it->()) {
            my $str = "@s";
        }
    },
    'Algorithm::Loops' => sub {
        NestedLoops(\@set, sub {
            my $str = "@_";
        });
    },
    'Math::Cartesian::Product' => sub {
        Math::Cartesian::Product::cartesian {
            my $str = "@_";
        } @set;
    },
    'Set::Product::PP' => sub {
        Set::Product::PP::product {
            my $str = "@_";
        } @set;
    },
    'Set::Product::XS' => sub {
        Set::Product::XS::product {
            my $str = "@_";
        } @set;
    },
};

__END__

=head1 BENCHMARKS

                                        Rate Set::CrossProduct    List::Gen Algorithm::Loops Set::Scalar Math::Cartesian::Product Set::Product::PP Set::Product::XS
    Set::CrossProduct          45.06+-0.54/s                --       -27.2%           -35.8%      -53.3%                   -78.8%           -84.1%           -95.5%
    List::Gen                  61.94+-0.22/s        37.4+-1.7%           --           -11.8%      -35.8%                   -70.9%           -78.2%           -93.8%
    Algorithm::Loops           70.25+-0.55/s        55.9+-2.2% 13.41+-0.97%               --      -27.2%                   -66.9%           -75.2%           -93.0%
    Set::Scalar                  96.5+-1.7/s       114.2+-4.6%   55.8+-2.9%       37.4+-2.7%          --                   -54.6%           -66.0%           -90.4%
    Math::Cartesian::Product      212.5+-2/s       371.6+-7.1%  243.1+-3.4%      202.5+-3.7% 120.2+-4.5%                       --           -25.0%           -78.8%
    Set::Product::PP          283.52+-0.34/s       529.1+-7.5%  357.7+-1.7%      303.6+-3.2% 193.7+-5.3%               33.4+-1.2%               --           -71.7%
    Set::Product::XS         1003.05+-0.21/s         2126+-26% 1519.4+-5.8%        1328+-11%    939+-19%                372+-4.4%    253.79+-0.43%               --

=cut
