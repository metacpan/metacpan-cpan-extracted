#!/usr/bin/env perl

=head1 DESCRIPTION

Ensure that C<silo> methods defined in different modules do not interfere.

=cut

use strict;
use warnings;
use Test::More;
use Test::Exception;

{
    package My::One;
    use Resource::Silo;

    resource foo => sub { 42 };
};

{
    package My::Two;
    use Resource::Silo;

    resource bar => sub { 137 };
};

lives_and {
    is My::One::silo->foo, 42, 'resource 1 available in 1';
};

throws_ok {
    My::One::silo->bar;
} qr/Can't locate object method "bar"/, 'resource 2 unavailable in 1';

throws_ok {
    My::Two::silo->foo;
} qr/Can't locate object method "foo"/, 'resource 1 unavailable in 2';

lives_and {
    is My::Two::silo->bar, 137, 'resource 2 available in 2';
};


done_testing;
