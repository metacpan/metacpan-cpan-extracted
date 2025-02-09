# BORROWED FROM THE match::smart DISTRIBUTION...
use v5.36;

use strict;
use warnings;
use Test::More;

use Switch::Back;

plan tests => 33;

sub does_match {
        my ($a, $b, $name) = @_;
        my ($as, $bs) = map do {
                no if ($] >= 5.010001), 'overloading';
                ref($_) ? qq[$_] : defined($_) ? qq["$_"] : q[undef];
        }, @_;
        $name ||= "$as matches $bs";
        ok(
                smartmatch($a, $b),
                "$name at line " . (caller)[2],
        );
}

sub doesnt_match {
        my ($a, $b, $name) = @_;
        my ($as, $bs) = map do {
                no if ($] >= 5.010001), 'overloading';
                ref($_) ? qq[$_] : defined($_) ? qq["$_"] : q[undef];
        }, @_;
        $name ||= "$as NOT matches $bs";
        ok(
                !(smartmatch($a, $b)),
                "$name at line " . (caller)[2],
        );
}

# If the right hand side is "undef", then there is only a match if
# the left hand side is also "undef".
does_match(undef, undef);
doesnt_match($_, undef)
        for 0, 1, q(), q(XXX), [], {}, sub {};

# If the right hand side is a non-reference, then the match is a
# simple string match.
does_match(q(xxx), q(xxx));
doesnt_match($_, q(xxx))
        for 0, 1, q(), q(XXX), [], {}, sub {};

# If the right hand side is a reference to a regexp, then the left
# hand is evaluated.
does_match(q(xxx), qr(xxx), 'q(xxx), qr(xxx)');
does_match(q(wwwxxxyyyzzz), qr(xxx), 'q(wwwxxxyyyzzz), qr(xxx)');
doesnt_match($_, qr(xxx))
        for 0, 1, q(), q(XXX), [], {}, sub {};
doesnt_match(qr(xxx), q(xxx));

# If the right hand side is a code reference, then it is called in a
# boolean context with the left hand side being passed as an
# argument.
does_match(1, sub {$_[0]});
doesnt_match(0, sub {$_[0]});
does_match(1, sub {1});
does_match(0, sub {1});

# If the right hand side is an arrayref, then the operator recurses
# into the array, with the match succeeding if the left hand side
# matches any array element.
does_match(q(x), [qw(x y z)], 'q(x), [qw(x y z)]');

doesnt_match("Foo", { foo => 1 });
doesnt_match("Foo", \*STDOUT);


done_testing();

