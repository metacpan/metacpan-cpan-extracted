#!/usr/bin/env perl
use strict;
use warnings;

use Algorithm::Loops qw(NestedLoops);
use Benchmark::Dumb qw(:all);
# use List::Gen ();
use List::MapMulti ();
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
    # 'List::Gen' => sub {
    #     my $it = List::Gen::cartesian { @_ } @set;
    #     while (my @s = $it->next) {
    #         my $str = "@s";
    #     }
    # },
    'List::MapMulti' => sub {
        List::MapMulti::mapm {
            my $str = "@_";
        } @set;
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

                                        Rate Set::CrossProduct List::MapMulti Algorithm::Loops Set::Scalar Math::Cartesian::Product Set::Product::PP Set::Product::XS
    Set::CrossProduct           31.17+-0.2/s                --          -8.8%           -63.9%      -77.4%                   -87.2%           -89.8%           -97.1%
    List::MapMulti             34.16+-0.21/s        9.6+-0.99%             --           -60.4%      -75.3%                   -86.0%           -88.8%           -96.8%
    Algorithm::Loops             86.3+-1.5/s         176.8+-5%    152.6+-4.5%               --      -37.5%                   -64.6%           -71.8%           -91.9%
    Set::Scalar               138.15+-0.56/s       343.3+-3.4%      304.4+-3%       60.1+-2.8%          --                   -43.4%           -54.9%           -87.0%
    Math::Cartesian::Product      244+-1.8/s         683+-7.7%    614.4+-6.9%      182.8+-5.2%  76.6+-1.5%                       --           -20.3%           -77.1%
    Set::Product::PP              306+-3.6/s          882+-13%       796+-12%      254.7+-7.3% 121.5+-2.7%               25.4+-1.7%               --           -71.3%
    Set::Product::XS         1066.58+-0.24/s         3322+-22%      3023+-20%        1136+-21% 672.1+-3.1%              337.1+-3.2%      248.5+-4.1%

=cut
