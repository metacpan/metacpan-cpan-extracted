package TAEB::Test;
use strict;
use warnings;
use TAEB;
use parent 'Test::More';
use List::Util 'sum';

our @EXPORT = qw/test_items test_monsters degrade_ok degrade_nok degrade_progression plan_tests/;

sub import_extra {
    Test::More->export_to_level(2);
    strict->import;
    warnings->import;
}

=head2 test_items ITEM_LIST

Takes a list of two item arrayrefs, where the first item is a string of the item's description and the second item is a hashref containing property/value pairs for the item. For example,
    test_items(["x - 100 gold pieces",                  {class => "gold"}],
               ["a - a +1 long sword (weapon in hand)", {class => "weapon"}]);

=cut

sub test_items {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    test_generic(sub { TAEB->new_item(shift) }, @_);
}

=head2 test_monsters MONSTER_LIST

Identical to test_items in style, except for monsters.

=cut

sub test_monsters {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    test_generic(sub { TAEB->new_monster(shift) }, @_);
}

sub test_generic {
    my $code = shift;
    for my $test (@_) {
        my $name = shift @$test;
        my %expected = @$test == 1 ? %{ $test->[0] } : @$test;

        my $obj = eval { $code->($name) };
        warn $@ if $@;

        for my $attr (keys %expected) {
            my $attr_expected = $expected{$attr};
            if (defined $obj) {
                Test::More::is($obj->$attr, $attr_expected,
                         "parsed $attr of $name");
            }
            else {
                Test::More::fail("parsed $attr of $name");
                Test::More::diag("$name produced an undef object");
            }
        }
    }
}

=head2 degrade_ok original, current

Tests whether the original string could possibly degrade to the current string.

=cut

sub degrade_ok {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my $exp = shift;
    my $got = shift;

    Test::More::ok(TAEB::Spoilers::Engravings->is_degradation($exp, $got), "$exp degrades to $got");
}

=head2 degrade_nok original, current

Tests whether the original string could NOT possibly degrade to the current
string.

=cut

sub degrade_nok {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my $exp = shift;
    my $got = shift;

    Test::More::ok(!TAEB::Spoilers::Engravings->is_degradation($exp, $got), "$exp does not degrade to $got");
}

=head2 degrade_progression Str, Str, Str, [...]

Test whether a progression is possible. This will not only test adjacent
engravings, but also an engraving to all of its children.

=cut

sub degrade_progression {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    for (my $i = 0; $i < @_; ++$i) {
        for (my $j = $i; $j < @_; ++$j) {
            degrade_ok($_[$i] => $_[$j]);
            degrade_nok($_[$j] => $_[$i]) unless $_[$i] eq $_[$j];
        }
    }
}

=head2 plan_tests ITEM_LIST

This will take the test list and count the number of tests that would be run.
If called in void context, the plan will be set for you. If called in nonvoid
context, the number of tests will be returned.

=cut

sub plan_tests {
    my $tests = sum map {
        ref $_->[1] eq 'HASH'
        ? scalar keys %{ $_->[1] }
        : (@$_ - 1) / 2
    } @_;

    return $tests if defined wantarray;

    Test::More::plan tests => $tests;
}

1;

