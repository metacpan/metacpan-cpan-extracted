#!/usr/bin/env perl

use strict;
use warnings;

use constant {
    BAR         => { bar => sub { 'Bar' } },
    BAZ         => { baz => sub { 'Baz' } },
    NO_RECYCLED => "Can't get a recycled reference",
    ROUNDS      => 1000,
};

use Object::Extend qw(extend SINGLETON);
use Scalar::Util qw(refaddr);
use Test::More tests => 31;

sub foo { 'Foo' }

# try to trigger the reuse of a refaddr (i.e. C pointer)
# and return the first object that uses a recycled refaddr
sub recycle(;%) {
    my %options = @_;
    my ($original_methods, $recycled_methods) = @options{qw(original recycled)};
    my ($recycled, %seen);

    for (1 .. ROUNDS) {
        my $object = bless {};
        my $refaddr = refaddr($object);

        if ($seen{$refaddr}) {
            $recycled = $object;

            if ($recycled_methods) {
                extend $recycled => $recycled_methods;
            }

            last;
        } else {
            if ($original_methods) {
                extend $object => $original_methods;
            }

            $seen{$refaddr} = 1;
            undef $object;
        }
    }

    return $recycled;
}

# sanity check the base case: neither the original nor
# the recycled are extended
SKIP: {
    my $recycled = recycle();
    skip NO_RECYCLED, 5 unless ($recycled);
    isa_ok $recycled, __PACKAGE__;
    can_ok $recycled, 'foo';
    ok !$recycled->isa(SINGLETON);
    ok !$recycled->can('bar');
    ok !$recycled->can('baz');
};

# make sure the unextended recycled isn't contaminated by
# the extended original
SKIP: {
    my $recycled = recycle(original => BAR);
    skip NO_RECYCLED, 5 unless ($recycled);
    isa_ok $recycled, __PACKAGE__;
    can_ok $recycled, 'foo';
    ok !$recycled->isa(SINGLETON);
    ok !$recycled->can('bar');
    ok !$recycled->can('baz');
};

# for completeness, make sure the recycled is sane if the
# original wasn't extended
SKIP: {
    my $recycled = recycle(recycled => BAR);
    skip NO_RECYCLED, 5 unless ($recycled);
    isa_ok $recycled, __PACKAGE__;
    isa_ok $recycled, SINGLETON;
    can_ok $recycled, 'foo';
    can_ok $recycled, 'bar';
    ok !$recycled->can('baz');
};

# make sure there are no surprises if we extend the recycled
# in the same way that we've extended the original
SKIP: {
    my $recycled = recycle(original => BAR, recycled => BAR);
    skip NO_RECYCLED, 5 unless ($recycled);
    isa_ok $recycled, __PACKAGE__;
    isa_ok $recycled, SINGLETON;
    can_ok $recycled, 'foo';
    can_ok $recycled, 'bar';
    ok !$recycled->can('baz');
};

# define bar in the original and redefine it to return a different value
# in recycled. make sure $recycled->bar returns the overridden value
SKIP: {
    my $recycled = recycle(original => BAR, recycled => { bar => sub { 'Bar 2' } });
    skip NO_RECYCLED, 6 unless ($recycled);
    isa_ok $recycled, __PACKAGE__;
    isa_ok $recycled, SINGLETON;
    can_ok $recycled, 'foo';
    can_ok $recycled, 'bar';
    ok !$recycled->can('baz');
    is $recycled->bar, 'Bar 2';
};

# extend the original with bar and the recycled with baz
# and make sure the recycled isn't contaminated by bar
SKIP: {
    my $recycled = recycle(original => BAR, recycled => BAZ);
    skip NO_RECYCLED, 5 unless ($recycled);
    isa_ok $recycled, __PACKAGE__;
    isa_ok $recycled, SINGLETON;
    can_ok $recycled, 'foo';
    can_ok $recycled, 'baz';
    ok !$recycled->can('bar');
};
