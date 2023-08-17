package Random::Skew;

#use 5.028001;
use strict;
use warnings;

our $VERSION = '0.09';

our $GRAIN = 72; # default
sub GRAIN {
    if ( @_ ) {
        my $grain = shift( @_ );
        if ( $grain =~ /\D/ ) {
            die "\$Random::Skew::GRAIN must be a positive integer >= 2";
        } elsif ( $grain >= 2 ) {
            $GRAIN = int( $grain );
        } else {
            die "\$Random::Skew::GRAIN must be >= 2";
        }
    }
    return $GRAIN;
}

our $ROUNDING = 0.5; # default
sub ROUNDING {
    if ( @_ ) {
        my $rounding = shift( @_ );
        if ( $rounding =~ /[^0-9.]/ ) {
            die "\$Random::Skew::ROUNDING must be decimal-point and digits only (floating point)";
        } elsif ( $rounding < 0.0 or $rounding > 1.0 ) {
            die "\$Random::Skew::ROUNDING must be between 0.0 and 1.0";
        } else {
            $ROUNDING = $rounding;
        }
    }
    return $ROUNDING;
}



sub new {
    my $class = shift;
    my %params = @_ or die "Random::Skew->new: No parameters?";

    my $tot = 0;
    my @bad;
    push @bad, "Random::Skew::GRAIN ($GRAIN) must be larger than 2" unless $GRAIN > 2;
    for ( keys %params ) {
        no warnings qw/numeric/;
        my $v = $params{ $_ } + 0.0;
        if ( $v >= 1 ) {
            $tot += $v;
        } else {
            push @bad,"Value '$params{$_}' for key '$_' must be a number >= 1";
        }
    }
    die @bad if @bad;

    my $self = bless {
        _set => [],
        _tot => $tot,
        _grain => $GRAIN,
        _params => { %params },
        _unique => scalar( keys %params ),
        _fraction => 0, # for when we have fine-grained details
    }, $class;

    my $small_skew;
    # Do we need to $scale our population down to fit $Random::Skew::GRAIN buckets?
    if ( $tot > $GRAIN ) {

        # Biggest to smallest
        my @ordered = sort { $params{ $b } <=> $params{ $a } or $a cmp $b } keys %params;

        # so that we fit in 1..GRAIN buckets
        my $scale = $GRAIN / $tot;
        my %big;
        my %small;
        my $running_tot = $tot * $scale;
#$DB::single = 1;
        foreach my $item ( @ordered ) {

            my $vec = $scale * $params{ $item };

            if ( $running_tot < 1.0 ) {

                # Remaining items are, all together, smaller than one bucket...
                # Small items get their own Random::Skew
                $small{ $item } = $params{ $item }; # original weighting
                if ( not $self->{ _fraction } ) {
                    $self->{ _fraction } = $running_tot;
                }

            } elsif ( $vec < 1.0 ) {

                # We are looking at contents smaller than one bucket at this scale...
                # (e.g. 30 items with a weight of 10 each, with GRAIN=20 f'rinstance)
                if ( %big ) {
                    $small{ $item } = $params{ $item }; # original weighting
                    if ( not $self->{ _fraction } ) {
                        $self->{ _fraction } = $running_tot;
                    }
                } else {
                    my $try = int( $GRAIN / $vec + 0.999999 );
                    # GRAIN=12
                    # POP=15 10s [10 10 10 10 10 10 10 10 10 10 10 10 10 10 10]
                    # grain needs to be 15, or 150(tot) / 10(biggest score)
                    # $tot / $params{ $item }
                    die "\$Random::Skew::GRAIN ($GRAIN) too small for this population (try >$try)";
                }

            } else {

                # Big items are $scale'd to 0..$GRAIN (+.5 for rounding)
                $big{ $item } = $vec + $ROUNDING; # scaled weighting

            }

            $running_tot -= $vec;

        }

        %params = %big;
        $small_skew = Random::Skew->new( %small ) if %small;

    }

    # Load up our set with items, one of which gets returned each ->item() call at random
    foreach my $item ( keys %params ) {
        my $bucket = int( $params{ $item } );
        push @{ $self->{_set} }, ( $item ) x $bucket;
    }

    if ( $small_skew ) {

        # In case the big items are numerous and similar, they may
        # not be very large related to the $tot, so pad extra items
        # to get us up to $GRAIN buckets
        my $fraction = int( $self->{_fraction} ) - 1; # leave room for $small_skew
        $fraction = 0 if $fraction < 0;
        my @blanks = ('') x $fraction;

        # Item [0] will be the zoom-in small set, for recursion
        unshift @{ $self->{_set} }, $small_skew, @blanks;

    }

    $self->{_pop} = scalar @{ $self->{_set} };

    return $self;

}



sub item {
    my $self = shift;

    my $fraction = $self->{_fraction} // 0;
    my $set = $self->{_set};
    my $pop = scalar @$set;

    RANDOMIZE: {

        # Pick a floating point random number from 0.0 up to $pop
        my $ix = rand( $pop );

        # Shortcut for when there's no smaller scale to recurse thru:
        return $set->[ $ix ] unless $fraction;

        if ( $ix <= $fraction ) {
            # Calls the smaller-set Random::Skew object
            return $set->[0]->item(); # RECURSION: zoom in, get an item from the smaller subset

        } elsif ( $ix >= 1.0 ) {
            return $set->[ $ix ];

        } else {
            # rand(0.0 .. _pop) is in the gap, > _fraction and < 1.0
            redo RANDOMIZE;
        }

    }

}



sub items {
    my $self = shift;
    my $ct   = shift || 1;

    my @v;
    push @v, $self->item # standard Random::Skew->item call
        while $ct -- > 0;

    return @v;
}



return $VERSION;

__END__

=head1 NAME

Random::Skew - Set up a pool of items to return one of, randomly -- with some more likely than others

=head1 SYNOPSIS

  use Random::Skew;
  Random::Skew::GRAIN( 127 );
  Random::Skew::ROUNDING( 0.5 );

  my $rs = Random::Skew->new(
    # Populations (taken from Wikipedia, July 2023)
    China  => 1_411_750_000, # China will show up most often
    India  => 1_392_329_000,
    USA    =>   335_016_000,
    Russia =>   146_424_729,
    UK     =>    67_026_292,
    Panama =>     4_278_500,
    Monaco =>        39_150, # rare, but still possible
  );

  # Now iterate a million times, generating a random country
  for ( my $ix = 1 ; $ix <= 1_000_000 ; $ix++  ) {
      my $ctry = $rs->item(); # probably China, but might be Monaco
      ...
  }

=head1 DESCRIPTION

For generating random data with a bit of skew to the proportions -- you
first set up a pool of weighted random items to choose from, and then
return one of those items at random. The relative weighting determines
how likely any particular item is returned.

Imagine this monstrous memory hog:

  my @setup = (('Dog') x 76_000_000,
               ('Cat') x 58_000_000,
               ('Parrot') x 500_000,
               ('Octopus') x    125);
  my $pet = $setup[ rand( @setup ) ];

Instead, we do this:

  # Household Pets:
  my $random_pet = Random::Skew->new(
    # item => weight,
    Dog    => 76_000_000,
    Cat    => 58_000_000,
    Parrot =>    500_000,
    Octopus=>        125,
  );
  my $pet = $random_pet->item; # Probably Dog, but could be Octopus

In the above example, "Dog" is waaay more likely to show up than "Octopus"
is. "Cat" is more likely than "Parrot" but less likely than "Dog". The
percentages actually returned during a million-iteration run, might deviate
a bit from the requested weightings, due to rounding, but not by much.

The higher the relative 'weight' the more likely that item will appear
in the result. The lower the relative 'weight' the less likely.

You can also generate a bunch in one go using the items() method:

  my @stuff = $rs->items( 200 );

For reasonably simple hierarchical data, one approach could be to
try complex hash keys:

  my $random_loc = Random::Skew->new(
    'CA:Los Angeles'   =>10000,
    'CA:San Diego'     => 6700,
    'CA:San Francisco' => 4150,
    'NY:New York'      => 8888,
    'NY:Albany'        =>  555,
    'IL:Chicago'       => 8100,
    'IL:Springfield'   =>  321,
  );

  while ( ... ) {
      my $loc = $random_loc->item;
      my ( $st, $city ) = split /:/,$loc;
      #...
  }

Check the examples directory for other ways to generate multi-level
random data.

=head2 METHODS

=over 4

=item $rs = Random::Skew->new( %weightings )

Sets up the L<Random::Skew> C<$rs> object. The C<%weightings> determine
how likely any particular item is going to be the value generated by
C<< $rs->item() >>.

  my %majors = (
    PSYCH => 2135,
    PHIL  => 1207,
    ENGR  =>  906,
    SOC   =>  214,
  );
  my $random_major = Random::Skew( %majors );
  #...
  my $major = $random_major->item();

=item $item = $rs->item()

Returns one item from your collection. Whatever has the highest
weighting in your collection is likely to be what shows up most often;
whatever has the lowest weighting will show up least often.

=item @items = $rs->items( $count )

Generates C<$count> items and returns them in a list/array.

=item Random::Skew::GRAIN( $int )

Sets up maximum number-of-buckets for simulating the randomness
you're shooting for, for the next C<< Random::Skew->new() >> object 
you create. It has no effect at all on existing L<Random::Skew> objects.

If your percentages (from generating a large number of items) are off a
bit, try different values here. Explore larger or smaller numbers;
sometimes prime numbers work well, other times an integer with lots
of factors can provide a better approximation.

See L<Random::Skew::Test> for how to explore C<GRAIN()> values.

Default C<Random::Skew::GRAIN> is 72.

=item Random::Skew::ROUNDING( $fraction )

When C<Random::Skew::GRAIN> isn't big enough to hold all your weights
at once, meaning that a scale multiplier is applied to reduce the number
of instances of each value to a "sane" number, the C<Random::Skew::ROUNDING>
value is added before truncating to an int.

Example: Weights 5, 4, 3 would all fit nicely into 12 buckets. If our
C<GRAIN> is 10, then we multiply them by 10/12 to get:

  5 => 5*10/12 => 4.16
  4 => 4*10/12 => 3.33
  3 => 3*10/12 => 2.5

With C<ROUNDING> of 0.0, we truncate to integers, so this would result in buckets
of size C<4, 3, 2>. With C<ROUNDING> of 0.5, we would get C<< 4.66=>4, 3.83=>3, 3.0=>3 >>.

=back

=head2 BACKGROUND

The sampling population of buckets backstage tries to be optimal.  If
you request weights 2,3,5 the sample population would only need 10
buckets (C<$tot=2+3+5>) for perfect fidelity.

You could request weights of 200, 300, 500 and with a
C<$Random::Skew::GRAIN> of 1000 it will create an array with 200, 300
and 500 instances of each item... which is wasteful. However, those
exact same weights with a C<$Random::Skew::GRAIN> of 10 would use the
exact same array as the smaller example above (2,3,5) since the
proportions are identical. To fit the 1000 items into the ten element
array (when C<$Random::Skew::GRAIN> is 10) it would calcualte a
C<$scale> of 0.01 and apply that C<$scale> to all weights.

If you tried a C<$Random::Skew::GRAIN> of 7 for these values, then your
weights would suffer a bit from rounding issues.  Instead of 5, 3, 2
you'd scale down to 3.5, 2.1, 1.4 (everything would be scaled by 7/10 to
squeeze the 10 requested into a 7 array) and these would round down to
3, 2, 1 yielding an actual array of only 6 items. So instead of the
requested proportions 50%, 30%, 20% you'd have 50% (3/6), 33.3% (2/6),
16.7% (1/6).  A larger C<$Random::Skew::GRAIN> would help in this case.

In any case if the C<$tot> population is more than
C<$Random::Skew::GRAIN> it'll calculate a multiplier C<$scale> to
squeeze the weighted elements to fit into the array, while trying to
keep your weighted ratios reasonably consistent.

Note: Set C<$Random::Skew::GRAIN> and C<$Random::Skew::ROUNDING> BEFORE
you call C<< Random::Skew->new() >>. Changing them after you already
have a C<Random::Skew> object won't affect it at all; it will alter the
next new object create.

You can have a wide range of samples and it tries hard to represent all
values, large and small, in a manageable footprint.

  my $rs = Random::Skew->new(
    Cornucopia  => 2_000_000,
    Overflowing => 173_492,
    Scarce      => 208,
    Unlikely    => 19,
  );

It probably won't represent your weightings with exact 100% fidelity,
   but it tries to get pretty close.

There's also C<$Random::Skew::ROUNDING> (a value between 0.0 and 1.0)
that affects fidelilty. In the case of squeezing 200, 300, 500 into a
C<$Random::Skew::GRAIN> of 7, instead of scaling down to 3.5, 2.1, 1.4
(which would truncate to 3 buckets, 2 buckets, and 1 bucket) if
C<$Random::Skew::ROUNDING=0.5> then you'd have 3.5+.5 (4.0), 2.1+.5
(2.6), 1.4+.5 (1.9) which truncate to 4 buckets, 2 buckets, and 1
bucket. The proportions are a bit off in both cases, it's up to you to
determine which C<$GRAIN> and which C<$ROUNDING> provide the
probabilities you require.

To ameliorate rounding issues, see L<Random::Skew::Test> for how to
explore different values of C<$Random::Skew::GRAIN> and
C<$Rounding::Skew::ROUNDING>.

=head2 METHODOLOGY

Representing weightings that don't have a lot of variation, is a
piece of cake.

    Some => 5,
    Thing=> 3,
    Other=> 2

Those can be represented by items in an array of ten buckets
which we build like so:

    Some, Some, Some, Some, Some, Thing, Thing, Thing, Other, Other

Returning one of those at random is trivial. That exact same
array would also work nicely for weightings of 500, 300 and 200,
or 5_000_000, 3_000_000, 2_000_000, since the relative
proportions are identical. (Note that fractional weightings of
0.5, 0.3, 0.2 won't work well since Perl can't populate a
fraction of an array element. Weightings are expected to be
positive integers for this reason.)

Weightings like the one below, though, are more challenging,
because of the range from large to small:

    huge => 1_000_000,
    mid  => 398_507,
    small=> 4_362,
    tiny => 1,

Having an array with a 1.4 million buckets to represent that
population, is NOT a good use of resources.

So we break it up into sections.

First, we sum all the weights (C<$tot>). If that can fit within an
array of C<$Random::Skew::GRAIN> elements (or smaller) then that's
what we do, and we're done.

If not, we conjure a scale C<$scale> as a multiplier so that the
entire weighted population will all fit within
C<$Random::Skew::GRAIN> elements.  And then, using the same
C<$scale> we drop items into buckets starting with the bigger
ones and moving to the smaller ones.

When the smaller ones are so small they would only fill a portion
of one bucket at the current scale (driven largely by
C<$Random::Skew::GRAIN>) that's when we go recursive.

The smaller items get a C<Random::Skew> object of their own (we
already handled the biggest objects) and the new object becomes
the smallest "bucket".

But wait, there's more.

Say we have a C<$Random::Skew::GRAIN> of 25 and the following weights:

    big1 => 500,
    big2 => 400,
    sm1  => 50,
    sm2  => 40,
    tiny => 10

Here, C<$tot = 1000>. To scale that down to 25 buckets, we calculate
C<$scale = 25/1000 = 0.025> and we multiply each item's weight by that same
C<$scale> to populate an array of 25 items and we get:

    big1  12x
    big2  10x
    sm1   1x
    sm2   1x

And C<tiny> is way too small for a bucket of its own at this
scale. In fact it would only need 0.25 of a bucket. That 0.25 is
the C<$fraction> we will use in a moment.

So we create a new C<< Random::Skew->new() >> object for the
smaller items (in this case it's just the one C<tiny> item that hasn't
been included in the array). We requested ten items for C<tiny> and
that's what we will get, in the second-layer object.

Later, when we ask for a C<< $rs->item() >> it starts with a
floating point random number C<$ix> between 0 and C<< @{
$rs->{_set} } >>.  If C<< $ix <= $fraction >> then it calls
the recursive object for a random item which would only be
'tiny' in this case. Otherwise, if that number represents one
of the buckets in the current C<< $rs->{_set} >> array it
returns that.

There can be a little gray area here -- a gap. If the random
C<$ix> is less than $fraction then we recurse thru the smaller
subset. If random C<$ix> is > 1.0 then it represents one of the
buckets in the current set and we return that.

When it's between C<$fraction> and 1.0... what then? This is the
portion of the "smallest bucket" that doesn't belong to the
smaller items.  We simply iterate again and try a new random
number.

For some skew-weightings, a SMALL value for
C<$Random::Skel::GRAIN> works best, and for others a LARGE value
does better. See L<Random::Skew::Test> for how to explore various
values of C<$Random::Skew::GRAIN> to best fit your data.

=head2 CAVEATS

The value of C<$Random::Skew::GRAIN> can have a significant
impact on how faithful the results are to your original weighting
proportions. See L<Random::Skew::Test> for how to explore varying
values of C<$Random::Skew::GRAIN>.

If you want twice as many A as B you can have a grain of 3: A, A,
B. A grain of 6 or 9 or 12 would work fine as well. On the other
hand, it would be difficult to represent that faithfully with a
grain of 4 or 5. You'd get rounding issues and some items would
return more often than expected, others less often than expected.

Sometimes a larger grain (2500 for example) works well, other times
a smaller grain (13 for example) does better, with recursion.

=head1 SEE ALSO

L<Random::Skew::Test> for exploring values of
C<$Random::Skew::GRAIN> and C<$Random::Skew::ROUNDING>.

L<Random::Set> was inspirational in getting this off the ground.

=head1 AUTHOR

Will Trillich <will@serensoft.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2022 by Will Trillich

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.28.1 or,
at your option, any later version of Perl 5 you may have available.

=cut

# vim:ft=perl tw=72 nowrap
