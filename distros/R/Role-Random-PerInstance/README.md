# NAME

Role::Random::PerInstance - A role for dealing with random values, per instance

# SYNOPSIS

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

# DESCRIPTION

This role allows you to use random numbers, maintaining separate random
numbers for each instance.

# METHODS

## `attempt($chance)`

    if ($self->attempt(0.6)) {
        # 60% chance of success
    }

Perform a random test which has a chance of success based on the $chance value,
where $chance is a value between 0 and 1.  A $chance value of 0 will always
return false, and a $chance value of 1 or more will always return true.

## `random($min, $max, $step)`

    my $gain = $self->random(0.1, 0.5, 0.1 );
    # $gain will contain one of 0.1, 0.2, 0.3, 0.4 or 0.5

    my $even = $self->random(100, 200, 2 );

Generate a random number from $min to $max inclusive, where the resulting
random number increments by a value of $step starting from $min. If `step` is
not supplied, this method behaves like `rand`, but from `$min` to `$max`.

By default (if no arguments are passed), this method will work the same as the
built in 'rand' function, which is to return a value from 0 to 1, but not
including 1. The number includes seven digits after the decimal point (e.g.,
`0.5273486`).

## `random_seed`

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
`deterministic_rand()` method instead of the built in `rand()` function.

In other words, if `random_seed` is not supplied to the constructor, the
random numbers will _not_ be repeatable.

## `deterministic_rand`

    my $rand = $object->deterministic_rand;
    $rand = $object->deterministic_rand;
    $rand = $object->deterministic_rand;
    $rand = $object->deterministic_rand;

This method returns pseudo-random numbers from 0 to 1, with up to seven digits
past the decimal point (e.g., "0.1417026"), but is deterministic. This is not
cryptographically secure, but the numbers are evenly distributed.

`$self->random_seed` must be set in the object constructor to ensure
deterministic randomness.

The algorithm is the [Linear Congruential
Generator](https://en.wikipedia.org/wiki/Linear_congruential_generator).

We've tried merely calling `srand(seed)`, but it turned out to not be as
deterministic as promised and also doesn't allow us fine-grained "per instance"
control.

## `random_int($min, $max)`

    my @items = qw(one two three four five);
    my $item = $items[ $self->random_int(0, $#items) ];

Generate a random integer from $min to $max inclusive.

## `weighted_pick`

    my %weights = (
        foo  => 1,     # 5% chance of being chosen
        bar  => 17,    # 85% chance of being chosen
        baz  => 2,     # 10% chance of being chosen
        quux => 0,     # will never be chosen
    );
    my $choice = $self->weighted_pick( \%weights );    # will usually return 'bar'

This function accepts a hash reference whose keys are the values you wish to
choose from and whose values are the _relative_ weights assigned to those
values. A single value from the hash will be returned. The higher its "key"
value, the more likely it is to be returned. Note that if you wanted an even
chance of all values, ensure that all keys have the same value (but at that
point, a straight `rand()` would be more efficient.

# BACKGROUND

The narrative sci-fi game, [Tau Station](https://taustation.space/), needed a
way to have _repeatable_ random numbers, with different instances of objects
creating their own series of random numbers. Perl's
[rand](https://perldoc.perl.org/functions/rand.html) function is global, and
seeding it with [srand](https://perldoc.perl.org/functions/srand.html) turns
out to not be as deterministic as we had hoped.
[Math::Random](https://metacpan.org/pod/Math::Random) is also global. Hence,
our own module.

Not only does this give you repeatable (via `random_seed`) random numbers, it
gives you non-repeatable random numbers (just don't provide a seed) and many
useful random utilities.

We implemented a [Linear Congruential
Generator](https://en.wikipedia.org/wiki/Linear_congruential_generator) and you
get seven digits after the decimal point, so each number has a 1 in ten
million chance of occuring. That is perfect for our needs. It may not be
perfect for yours.

Also, while the Linear Congruential Generator is fairly efficient and random,
it's not cryptographically secure.

# AUTHOR

Curtis "Ovid" Poe, `<curtis.poe at gmail.com>`

# BUGS

Please report any bugs or feature requests via the Web interface at
[https://github.com/Ovid/role-random-perinstance/issues](https://github.com/Ovid/role-random-perinstance/issues).  I will be
notified, and then you'll automatically be notified of progress on your bug as
I make changes.

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Role::Random::PerInstance

You can also look for information at:

- Bug Tracker

    [https://github.com/Ovid/role-random-perinstance/issues](https://github.com/Ovid/role-random-perinstance/issues)

- Search CPAN

    [https://metacpan.org/release/Role-Random-PerInstance](https://metacpan.org/release/Role-Random-PerInstance)

# SEE ALSO

`Role::Random::PerInstance` was developed for the narrative sci-fi game [Tau
Station](https://taustation.space). We like it because the syntax is simple,
clear, and intuitive (to us). However, there are a few alternatives on the
CPAN that you might find useful:

- [Class::Delegation](https://metacpan.org/pod/Class::Delegation)
- [Class::Delegation::Simple](https://metacpan.org/pod/Class::Delegation::Simple)
- [Class::Delegate](https://metacpan.org/pod/Class::Delegate)
- [Class::Method::Delegate](https://metacpan.org/pod/Class::Method::Delegate)

# ACKNOWLEDGEMENTS

This code was written to help reduce the complexity of the narrative sci-fi
adventure, [Tau Station](https://taustation.space). As of this writing, it's
around 1/3 of a million lines of code (counting front-end, back-end, tests,
etc.), and anything to reduce that complexity is a huge win.

# LICENSE AND COPYRIGHT

This software is Copyright (c) 2019 by Curtis "Ovid" Poe.

This is free software, licensed under:

    The Artistic License 2.0 (GPL Compatible)
