package Random::Skew::Test;

use strict;
use warnings;

our $VERSION = '0.02';

use Random::Skew;

sub sample {

    my $self = shift;
    my %params = @_;

    my @bad;

    my $iter = $params{iter} or push @bad,"Random::Skew::sample(iter=>?) parameter missing";
    my $skew = $params{skew} or push @bad,"Random::Skew::sample(skew=>{}) parameter missing";
    my $grain= $params{grain} // [ qw/25 250 1000/ ];
    my $round= $params{round} // [ qw/0 .5/ ];

    die @bad if @bad;

    my @output;

    my $rs;

    my @grain = @$grain;
    my @round = @$round;

    foreach $grain ( @grain ) {

        $Random::Skew::GRAIN = $grain;
        my @r = @round;

        while ( @r ) {
            $round = shift @r;

            $Random::Skew::ROUNDING = $round;

            $rs = Random::Skew->new( %$skew );
            my $pop = $rs->{_pop};

            if ( $rs->{_tot} < $rs->{_grain} ) {
                $round = '[moot at this grain]';
                @r = ();
            }

            push @output, "Grain=$Random::Skew::GRAIN (Rounding=+$round): -=-=-=-=-=-=-=-=-=-\n",
                &show( $rs ),
                &run( $rs, $iter );

        }

    }

    return @output,
        "Typically you want the Ratio column to be close to 1.0 (0.9ish to 1.1ish).\n",
        "However, more iterations (>$iter) might smooth out the results.\n\n";

}



# To see the structure of a Random::Skew object
sub show {
    my $set = shift;
    my $indent = shift || '';

    my @output;

    my %v;
    my $v;
    foreach $v ( @{ $set->{_set} } ) {
        $v{ $v }++ unless ref $v;
    }
    foreach $v ( sort {$v{$b} <=> $v{$a} or $a cmp $b} keys %v ) {
        push @output, "$indent$v\t$v{$v}\n"
             if $v; # no need to show empties, _fraction handles those anyway
    }

    if ( $set->{_fraction} ) {
        push @output,
            "$indent...and smaller (when rand(0..$set->{_pop}) < $set->{_fraction}):\n",
            &show( $set->{_set}[0], "$indent  " );
    }

    return @output;
}



sub run {
    my $rs = shift;
    my $ct = shift // 1_000_000;

    my @output;

    push @output, "--${ct}x:\n",
        "Bucket\tReturned(%)\tRequested(%)\tRatio\n",
        "======\t========\t=========\t=====\n";

    my %result;
    while ( $ct-- > 0 ) {

        # _/_/_/_/  _/_/_/_/    _/_/_/_/  _/_/_/_/
        #   _/     _/         _/            _/
        #  _/     _/_/_/      _/_/_/       _/
        # _/     _/               _/      _/
        #_/     _/_/_/_/  _/_/_/_/       _/

        $result{ $rs->item }++; # Here's where we iterate thru the tests

    }

    my $overall_prd = 1.0;
    my $is_zero = 0;
    my $overall_avg = 0.0;

    my $p = $rs->{_params};
    my $p_tot = 0;
    my $r_tot = 0;
    foreach my $item ( keys %$p ) {
        $p_tot += $p->{ $item }    // 0;
        $r_tot += $result{ $item } // 0;
    }
    foreach my $item ( sort {$p->{$b} <=> $p->{$a} or $a cmp $b } keys %$p ) {
        my $p_pct = 100 *     $p->{ $item }       / $p_tot;
        my $r_pct = 100 * ($result{ $item } // 0) / $r_tot;
        my $ratio = $r_pct / $p_pct;
        $is_zero ++ unless defined( $result{ $item } );

        my $ratio_alert = '';
           $ratio_alert = ' <-- low?'  if $ratio < 9/10;
           $ratio_alert = ' <-- LOW?'  if $ratio < 8/10;
           $ratio_alert = ' <-- high?' if $ratio > 10/9;
           $ratio_alert = ' <-- HIGH?' if $ratio > 10/8;
        push @output, sprintf "%s:\t%s (%3.3g)\t%s (%3.3g)\t%.4f%s\n",
            $item,
            &h( $result{$item} // 0 ), $r_pct,
            &h( $p->{$item} ),         $p_pct,
            $ratio, $ratio_alert,
            ;
        $overall_prd *= $ratio;
        $overall_avg += $ratio;
    }
    $overall_avg /= scalar keys %$p;
    if ( $is_zero > 1 ) {
        push @output, "Note: there are $is_zero buckets not represented (which causes zero product).\n";
    } elsif ( $is_zero > 0 ) {
        push @output, "Note: there is a bucket not represented (which causes zero product).\n";
    }
    push @output, sprintf "Overall ratio product: %5.5g\nOverall ratio average: %5.5g\n\n",
         $overall_prd,
         $overall_avg;

    return @output;
}



sub h {
    my $v = shift;
    my $unit = '';
    my $div = 1;
    my $fmt = '%.0f'; # %f rounds, %d truncates
    if ( $v > 2_000_000_000 ) {
        $div = 1000 * 1000 * 1000;
        $unit = 'g';
    } elsif ( $v > 9_999_999 ) {
        $div = 1000 * 1000;
        $unit = 'm';
    } elsif ( $v > 2_000_000 ) {
        $div = 1000 * 1000;
        $unit = 'm';
        $fmt = '%.1f';
    } elsif ( $v > 9_999 ) {
        $div = 1000;
        $unit = 'k';
    } elsif ( $v > 2_000 ) {
        $div = 1000;
        $unit = 'k';
        $fmt = '%.1f';
    }
    return sprintf "$fmt%s", $v/$div, $unit;
}



1;
__END__

=head1 NAME

Random::Skew::Test - Handy means for testing (and fine tuning) Random::Skew.

=head1 SYNOPSIS

  use Random::Skew::Test;
  my @results = Random::Skew::Test->sample(
    iter => 2_500_000,
    skew => {
        huge  => 5000,
        mid   => 121,
        teeny => 3,
    },
    grain => [ qw/10 27 293/ ],
    round => [ qw/0 .5/ ],
  );
  print @results;

=head1 DESCRIPTION

Tests Random::Skew algorithm and generates printable results.
Can be useful for learning which granularity values
(C<$Random::Skew::GRAIN>) and what rounding values
(C<$Random::Skew::ROUNDING>) are best for your uses.

The sample() method takes these parameters:

=over 4

=item iter

    iter => 5_000_000,

This integer is how many iterations to run for the test, where
L<$Random::Skew> returns this many weighted-random items.  It's
quite fast, you can do 10_000_000 iterations of many
configurations in just a few seconds.

=item skew

This hashref represents your weighted scale of items to return.
The values in the skew hash represent how likely the keys are to
be returned randomly.

    skew => {
        Ubiquitous => 39_999,
        Mucho      => 1962,
        Sometimes  => 19,
        Unusual   => 4,
    }

=item grain

This arrayref sets the max size (how many buckets) of the sampling
set, which determines how much 'rounding' you might experience.
It runs a separate test for each 'grain'.

    grain => [ qw/24 75 159 890/ ]

The idea is, C<$GRAIN> establishes how coarse the buckets are for
your set of items. Example: If you have skew values of 40, 30, 20, 10
you can scale those down with perfect fidelity with a grain of 10
buckets (4 tens, 3 tens, 2 tens, 1 ten is exactly represented,
proportionally, by 4, 3, 2, 1).  If you have C<$GRAIN=8> buckets
you'd have these ten items squeezed into 3, 2, 1 with a smaller
subset for the tiny item, whereas with C<$GRAIN=13>  buckets
you'd have 5, 3, 2, 1. In these cases some items will be slightly
over-represented and others will be slightly under-represented
due to rounding.

Astonishingly, for C<$Random::Skel::GRAIN>, small values (13, 28,
41 etc) work amazingly well in many cases, but you could use a
ridiculously high number (2500? 50_000?) if you have the RAM and
want to give it a try. Take it out for a spin.

You can't have a C<$GRAIN> less than 2, and 2 won't be too useful
in most cases. You'll likely want to use values 10 or more.
Experiment.

Note that if you have C<$Random::Skew::ROUNDING> greater than
zero (should only be between zero and one) then it's possible you
actually wind up with a few more buckets than C<$GRAIN>.

=item round

    round => [ qw/0.25 0.5 0.75/ ]

This arrayref specifies various values to try for
C<$Random::Skew::ROUNDING>. They can be between 0.0 and 1.0.

=back

For each setting of C<$Random::Skew::GRAIN> it runs C<$iter>
tests and generates output. Each test has two sections: structure
and results.

=head1 EXAMPLE

For the example below, we are using these C<< skew=>{} >> weights:

    skew => {
        bigone => 500,
        bigtwo => 400,
        smone  => 50,
        smtwo  => 40,
        tiny1  => 5,
        tiny2  => 4,
        nano   => 1,
    }

Here, the total population C<$tot> requested is 500+400+50+40+5+4+1, or 1000.

=over 4

=item Data Structure

With the sample output below, it is showing three levels of
Random::Skew. The large items are 'bigone', 'bigtwo' and 'smone'.
For the middle set the items are 'smtwo', 'tiny1' and 'tiny2'.
For the third and smallest set, there's only 'nano'.

	Grain=20 (Rounding=+0): -=-=-=-=-=-=-=-=-=-
	bigone  10
	bigtwo  8
	smone   1
	...and smaller (rand(0..20) < 1):
	  smtwo    16
	  tiny1    2
	  tiny2    1
	  ...and smaller (rand(0..20) < 0.4):
		nano      1

Here we see C<$Random::Skew::GRAIN> is 20 and
C<$Random::Skew::ROUNDING> is zero. The top set includes
'bigone', 'bigtwo' and 'smone'. Then the indentation indicates
there's a smaller set for 'smtwo', 'tiny1' and 'tiny2'.  And
finally a third set for the smallest items, containing only
'nano'.

Given that the C<$tot> total population is 1000, we C<$scale>
everything down by multiplying by 20/1000 or 0.02. In the
top-level set, we have 'bigone' with a weight of 500, scaled down
to 10 buckets; 'bigtwo' with a weight of 400 scaled down to 8
buckets, 'smone' with a weight of 50 scaled down to 1 bucket --
and the remaining items have weights that are so miniscule, none
of them are big enough to be represented by a whole bucket at
this scale. The smaller items are represented by recursion into a
"sub-set" of their own with a different, appropriate C<$scale>.
When picking a random item, we grab a random floating point
number (between 0.0 and 20.0). When that number is < 1.0 it will
call on the middle set, via recursion. Otherwise we quickly
return whichever item is in the array at that offset ('bigone' or
'bigtwo' or 'smone').

The middle set is similar, and has its own scale. The items we
are working with now are 'smtwo' (40), 'tiny1' (5), 'tiny2' (4)
and 'nano' (1) since 'bigone' and 'bigtwo' and 'smone' are
already handled by the top-level set. For this smaller set, our
C<$tot> is 50 instead of 1000, which we C<$scale> down to 20
using a multiplier of 20/50 or 0.4.  Item 'smtwo' with a weight
of 40 is scaled down to 16 buckets; 'tiny1' with a weight of 5
gets 2 buckets, and 'tiny2' with a weight of 4 gets 1 bucket. At
this scale, 'nano' would only be 4/10 of a bucket, which is
represented by the C<< "(rand(0..20) < 0.4)" >> in the output.
That is, when the random number (between 0.0 and 20.0) is < 0.4
it calls upon the third level for a random item; when it is
between 1.0 to 20.0 it returns 'smtwo' (16 times out of 19), or
'tiny1' (2 times out of 19), or 'tiny2' (1 time out of 19). Did
you notice the gap?  There's a gap, between 0.4 and 1.0. If the
random number is between 0.4 and 1.0 it picks another random
number between 0.0 to 20.0 and tries again.

The third set has the tiniest bits from our original population.
In this case it's only 'nano' with a weight of 1. The whole set
is just one item 'nano' with no further recursion needed (there's
nothing smaller than 'nano' in our weighted items). So when we
get to this point we pick an item at random, which is always
'nano' all day, every day, since there's only one. Note that to
get here, the top-level (big pieces) set needs a random number <
1.0 out of 20.0 to get to the middle set, and then the
middle-level set needs a random number < 0.4 out of 20.0.  That
comes to a likelihood of 1/20 x 0.4/20 = 0.01 which exactly
matches the weighted proportions of 'nano' from our original
population.

If you have a large, varied population and a small
C<$Random::Skew::GRAIN> then you could have a structure that's
pretty deep. If you have a large C<$Random::Skew::GRAIN> or a
small variance in a small population you might have a very
shallow structure.

=item Test Results

The columns displayed show actual random-skew count generated,
random-skew scale requested, and ratio.

	--1000000x:
			Returned        Requested       Ratio
			========        =========       =====
	bigone: 500k (50.025)   500 (   50)     1.0005
	bigtwo: 399k (39.978)   400 (   40)     0.9995
	smone:  50k (5.0166)    50 (    5)      1.0033
	smtwo:  41k (4.1194)    40 (    4)      1.0298
	tiny1:  4982 (0.4982)   5 (  0.5)       0.9964
	tiny2:  2587 (0.2587)   4 (  0.4)       0.6467 <-- low
	nano:   1041 (0.1041)   1 (  0.1)       1.0410

This test ran a million iterations (as shown by "1000000x").

Let's start with the middle column first.

Middle column: Weights REQUESTED. In this example they are 500,
400, 50, 40, 5, 4, 1 (which makes the total population
C<$tot=1000> in this case).  500 is 50% of the total, 400 is 40%,
and so on down to 1 being 0.1% of the total.

Left column: Weights RETURNED from actually requesting the
randomized items. In this example of 1000000 iterations, we saw
'bigone' returned 50.025% of the time, which is really close to
the 50% requested. 

Right column: RATIO (returned % / requested %). So in this case,
'bigone' showed up 50.025% of the time; in our specification we
requested it 50% of the time, and the ratio of the two is 1.0005
which is close to spot-on.

Here's the output with the actual counts omitted, only showing
the percents:

	bigone: (50.025)   (   50)     1.0005
	bigtwo: (39.978)   (   40)     0.9995
	smone:  (5.0166)   (    5)     1.0033
	smtwo:  (4.1194)   (    4)     1.0298
	tiny1:  (0.4982)   (  0.5)     0.9964
	tiny2:  (0.2587)   (  0.4)     0.6467 <-- low
	nano:   (0.1041)   (  0.1)     1.0410

If the rand() function returns a homogenous spread of values, we
expect the values in the third column to be close to 1.0...
closer and closer, the more items we request.

For large values of C<$Random::Skel::GRAIN> the items on the big
side of any one set will typically be very close to the
proportions requested, and the items on the small side can be
over-represented a bit, or under-represented a bit. You typically
want a small tolerance for variation in the third column -- say,
from 0.9 to 1.1 (your tolerance will depend on your
requirements).

In our illustration above, 'tiny2' showed up only 0.2587% of the
time and we were hoping for 0.4% of the time, which brings the
comparison/ratio column to 0.6467. This might be adequate for
your requirements, or it may not. If it's critical to make sure
each segment of a set is spot-on, it's worth tinkering with
C<$Random::Skel::GRAIN> (perhaps SMALLER! no, really! recursion
often nails it when a large-grain set won't) and/or
C<$Random::Skel::ROUNDING> to get your third-column results
closer to 1.0.

=head1 SEE ALSO

C<Random::Skew>

=head1 AUTHOR

If you find this library useful, I'd like to hear about it. :)

will@serensoft.com

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2022 by Will Trillich

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.28.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
