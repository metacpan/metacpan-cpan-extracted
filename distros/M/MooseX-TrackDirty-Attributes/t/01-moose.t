=head1 DESCRIPTION

This test exercises the Moose bits (meta, role application, etc).

=cut

use strict;
use warnings;

{
    package TestClass;

    use Moose;
    use MooseX::TrackDirty::Attributes;
    use namespace::autoclean;

    has one => (
        traits     => [TrackDirty],
        is         => 'rw',

        original_value => 'original_value_of_one',
    );

    sub _build_one { 'sparkley!' }

    has lazy => (is => 'rw', lazy_build => 1);

}

use Test::More 0.92;
use Test::Moose;

with_immutable {
    meta_ok 'TestClass';
    has_attribute_ok 'TestClass', 'one';
    can_ok  'TestClass', 'one_is_dirty', 'original_value_of_one';

    my $one_att_meta = TestClass->meta->get_attribute('one');

    does_ok $one_att_meta, 'MooseX::TrackDirty::Attributes::Trait::Attribute';
    has_attribute_ok $one_att_meta, 'is_dirty';

    does_ok
        $one_att_meta->accessor_metaclass,
        'MooseX::TrackDirty::Attributes::Trait::Method::Accessor',
        ;

} 'TestClass';

done_testing;
