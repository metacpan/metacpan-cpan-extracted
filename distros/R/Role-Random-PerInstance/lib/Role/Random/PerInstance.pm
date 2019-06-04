package Role::Random::PerInstance;

use Moose::Role;
use Carp;
use feature 'state';

our $VERSION = '0.01';

use List::Util qw(sum reduce);
use Math::Round qw(nlowmult);

has random_seed => (
    is      => 'rw',
    isa     => 'Int',
    lazy    => 1,
    builder => '_build_random_seed',
);

sub _build_random_seed { 0 }

# this is only used internally in deterministic_rand() to reset the seed for
# the next call to deterministic_rand().
has _seed => (
    is        => 'rw',
    isa       => 'Int',
    predicate => '_seed_is_set',
);

sub deterministic_rand {
    my $self = shift;
    state $modulus      = 2**31 - 1;
    state $multiplier_a = 1_103_515_245;
    state $increment_c  = 12_345;

    if ( !$self->random_seed && !$self->_seed_is_set ) {
        croak("You must provide a random_seed to the constructor");
    }

    # only set this once via random_seed. After that, this algorithm will set
    # it.
    $self->_seed( $self->random_seed ) unless $self->_seed_is_set;
    my $xn_new = ( $multiplier_a * $self->_seed + $increment_c ) % $modulus;
    $self->_seed($xn_new);
    return 0 + sprintf "%0.9f" => substr( $xn_new, -7 ) / 10_000_000;
}

sub attempt {
    my ( $self, $base_chance ) = @_;
    my $chance = _constrain( 0, $base_chance, 1 );

    my $rand = $self->random;
    return $rand < $chance ? 1 : 0;
}

sub random {
    my ( $self, $min, $max, $step ) = @_;
    $min  //= 0;
    $max  //= 1;
    $step //= 0;

    # We add $step to ensure that $max is inclusive in our random set.
    # If $step is set to 0, then $max will be exclusive of the result set.
    my $maxrand = $max - $min + $step;
    $maxrand = nlowmult( $step, $maxrand ) if $step;
    my $rand =
        $self->random_seed
      ? $self->deterministic_rand
      : rand();
    $rand *= $maxrand;
    $rand = nlowmult( $step, $rand ) if $step;
    $rand += $min;

    return $rand;
}

sub random_int {
    my ( $self, $min, $max ) = @_;
    return $self->random( $min, $max, 1 );
}

sub weighted_pick {
    my ( $self, $weight_for ) = @_;
    my ( @weights, @choices );
    my $total = 0;

    # Use foreach with a sort to ensure that the order of items in weights and
    # choices is always the same
    foreach my $choice ( sort keys $weight_for->%* ) {
        my $weight = $weight_for->{$choice};
        next unless $weight;    # don't include weights of 0
        $total += $weight;
        push @weights => $total;
        push @choices => $choice;
    }
    return
      $choices[ $self->_binary_range( $self->random( 0, $weights[-1] ),
          \@weights ) ];
}

sub _binary_range {
    my ( $self, $elem, $list ) = @_;
    my $max = $#$list;
    my $min = 0;

    while ( $max >= $min ) {
        my $index = int( ( $max + $min ) / 2 );
        my $curr  = $list->[$index];
        my $prev  = 0 == $index ? 0 : $list->[ $index - 1 ];
        if ( $prev < $elem && $curr >= $elem ) { return $index }
        elsif ( $curr > $elem ) { $max = $index - 1 }
        else                    { $min = $index + 1; }
    }
}

sub _constrain {
    my ( $min, $num, $max ) = @_;
    $max //= $num;
    return
        $num < $min ? $min
      : $num > $max ? $max
      :               $num;
}

1;

__END__

=head1 NAME

Role::Random::PerInstance - A role for dealing with random values, per instance

=head1 SYNOPSIS

    package Some::Class;
    use Moose;
    with 'Role::Random::PerInstance';

    # later , with an instance of Some::Class
    if ( $self->random < .65 ) {
        ...
    }

    # same thing ...

    if ( $self->attempt(.65) ) {
        ...
    }

=head1 DESCRIPTION

This role allows you to use random numbers, maintaining separate random
numbers for each instance.

=head1 METHODS

=head2 C<attempt($chance)>

    if ($self->attempt(0.6)) {
        # 60% chance of success
    }

Perform a random test which has a chance of success based on the $chance value,
where $chance is a value between 0 and 1.  A $chance value of 0 will always
return false, and a $chance value of 1 or more will always return true.

=head2 C<random($min, $max, $step)>

    my $gain = $self->random(0.1, 0.5, 0.1 );
    # $gain will contain one of 0.1, 0.2, 0.3, 0.4 or 0.5

    my $even = $self->random(100, 200, 2 );

Generate a random number from $min to $max inclusive, where the resulting
random number increments by a value of $step starting from $min. If C<step> is
not supplied, this method behaves like C<rand>, but from C<$min> to C<$max>.

By default (if no arguments are passed), this method will work the same as the
built in 'rand' function, which is to return a value from 0 to 1, but not
including 1. The number includes seven digits after the decimal point (e.g.,
C<0.5273486>).

=cut

=head2 C<random_seed>

    package Some::Package {
        use Moose;
        with 'Role::Random::PerInstance';
        ...
    }
    my $object = Some::Package->new(
        random_seed => $integer_seed
    );

If an object consuming this role passes in an integer random seed to the
constructor, all "random" methods in this role will use the
C<deterministic_rand()> method instead of the built in C<rand()> function.

In other words, if C<random_seed> is not supplied to the constructor, the
random numbers will I<not> be repeatable.

=head2 C<deterministic_rand>

    my $rand = $object->deterministic_rand;
    $rand = $object->deterministic_rand;
    $rand = $object->deterministic_rand;
    $rand = $object->deterministic_rand;

This method returns pseudo-random numbers from 0 to 1, with up to seven digits
past the decimal point (e.g., "0.1417026"), but is deterministic. This is not
cryptographically secure, but the numbers are evenly distributed.

C<< $self->random_seed >> must be set in the object constructor to ensure
deterministic randomness.

The algorithm is the L<Linear Congruential
Generator|https://en.wikipedia.org/wiki/Linear_congruential_generator>.

We've tried merely calling C<srand(seed)>, but it turned out to not be as
deterministic as promised and also doesn't allow us fine-grained "per instance"
control.

=head2 C<random_int($min, $max)>

    my @items = qw(one two three four five);
    my $item = $items[ $self->random_int(0, $#items) ];

Generate a random integer from $min to $max inclusive.

=head2 C<weighted_pick>

    my %weights = (
        foo  => 1,     # 5% chance of being chosen
        bar  => 17,    # 85% chance of being chosen
        baz  => 2,     # 10% chance of being chosen
        quux => 0,     # will never be chosen
    );
    my $choice = $self->weighted_pick( \%weights );    # will usually return 'bar'

This function accepts a hash reference whose keys are the values you wish to
choose from and whose values are the I<relative> weights assigned to those
values. A single value from the hash will be returned. The higher its "key"
value, the more likely it is to be returned. Note that if you wanted an even
chance of all values, ensure that all keys have the same value (but at that
point, a straight C<rand()> would be more efficient.

=head1 BACKGROUND

The narrative sci-fi game, L<Tau Station|https://taustation.space/>, needed a
way to have I<repeatable> random numbers, with different instances of objects
creating their own series of random numbers. Perl's
L<rand|https://perldoc.perl.org/functions/rand.html> function is global, and
seeding it with L<srand|https://perldoc.perl.org/functions/srand.html> turns
out to not be as deterministic as we had hoped.
L<Math::Random|https://metacpan.org/pod/Math::Random> is also global. Hence,
our own module.

Not only does this give you repeatable (via C<random_seed>) random numbers, it
gives you non-repeatable random numbers (just don't provide a seed) and many
useful random utilities.

We implemented a L<Linear Congruential
Generator|https://en.wikipedia.org/wiki/Linear_congruential_generator> and you
get seven digits after the decimal point, so each number has a 1 in ten
million chance of occuring. That is perfect for our needs. It may not be
perfect for yours.

Also, while the Linear Congruential Generator is fairly efficient and random,
it's not cryptographically secure.

=head1 AUTHOR

Curtis "Ovid" Poe, C<< <curtis.poe at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests via the Web interface at
L<https://github.com/Ovid/role-random-perinstance/issues>.  I will be
notified, and then you'll automatically be notified of progress on your bug as
I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Role::Random::PerInstance

You can also look for information at:

=over 4

=item * Bug Tracker

L<https://github.com/Ovid/role-random-perinstance/issues>

=item * Search CPAN

L<https://metacpan.org/release/Role-Random-PerInstance>

=back

=head1 SEE ALSO

C<Role::Random::PerInstance> was developed for the narrative sci-fi game L<Tau
Station|https://taustation.space>. We like it because the syntax is simple,
clear, and intuitive (to us). However, there are a few alternatives on the
CPAN that you might find useful:

=over 4

=item * L<Class::Delegation|https://metacpan.org/pod/Class::Delegation>

=item * L<Class::Delegation::Simple|https://metacpan.org/pod/Class::Delegation::Simple>

=item * L<Class::Delegate|https://metacpan.org/pod/Class::Delegate>

=item * L<Class::Method::Delegate|https://metacpan.org/pod/Class::Method::Delegate>

=back


=head1 ACKNOWLEDGEMENTS

This code was written to help reduce the complexity of the narrative sci-fi
adventure, L<Tau Station|https://taustation.space>. As of this writing, it's
around 1/3 of a million lines of code (counting front-end, back-end, tests,
etc.), and anything to reduce that complexity is a huge win.

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2019 by Curtis "Ovid" Poe.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

1;
