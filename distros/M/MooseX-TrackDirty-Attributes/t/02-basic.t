
use strict;
use warnings;

{
    package TestClass;

    use Moose;
    use MooseX::TrackDirty::Attributes;
    use MooseX::AttributeShortcuts;
    use namespace::autoclean;

    has one => (
        traits     => [TrackDirty],
        is         => 'rw',

        clearer        => 1,
        cleaner        => 'mark_one_clean',
        predicate      => 1,
        original_value => 'original_value_of_one',
    );

    sub _build_one { 'sparkley!' }

    has lazy => (is => 'rw', lazy_build => 1);

}

use Test::More 0.92;
use Test::Moose::More 0.009;

with_immutable {

    validate_class 'TestClass' => (
        attributes => [ qw{ one lazy } ],
        methods    => [ qw{
            _build_one
            clear_one has_one
            mark_one_clean
            one
            one_is_dirty
            original_value_of_one
        } ],
    );

    my $one = TestClass->new();

    ok !$one->one_is_dirty, 'one is not dirty yet';
    is $one->original_value_of_one, undef, 'no original value yet';

    $one->one('Set!');

    ok !$one->one_is_dirty, 'one is not dirty yet';
    is $one->original_value_of_one, undef, 'no original value yet';

    $one->one('And again!');

    ok $one->one_is_dirty, 'one is dirty';
    is $one->original_value_of_one, 'Set!', 'original value is correct';

    $one->clear_one;
    ok !$one->one_is_dirty, 'one is not dirty after clearing';
    is $one->original_value_of_one, undef, 'no original value after clearing';

    $one->one('whee!');
    $one->one('whee!!!');
    ok $one->one_is_dirty, 'one is dirty';
    $one->mark_one_clean;
    ok !$one->one_is_dirty, 'one is not dirty after marking clean';
    is $one->original_value_of_one, undef, 'no original value after marking clean';
    is $one->one, 'whee!!!', 'value is correct after marking clean';

} 'TestClass';

done_testing;
