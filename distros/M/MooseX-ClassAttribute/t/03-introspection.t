use strict;
use warnings;

use lib 't/lib';

use Test::More;

# We just want the class definitions in here.
use SharedTests;

ok(
    HasClassAttribute->meta()->has_class_attribute('ObjectCount'),
    q{has_class_attribute('ObjectCount') returns true}
);

ok(
    HasClassAttribute->meta()->get_class_attribute('ObjectCount')->meta()
        ->does_role('MooseX::ClassAttribute::Trait::Attribute'),
    'get_class_attribute_list returns an object which does the MooseX::ClassAttribute::Trait::Attribute role'
);

my @ca = qw( Delegatee
    LazyAttribute
    ManyNames
    Mapping
    ObjectCount
    ReadOnlyAttribute
    WeakAttribute
    Built
    LazyBuilt
    Triggerish
    TriggerRecord
);

is_deeply(
    [ sort HasClassAttribute->meta()->get_class_attribute_list() ],
    [ sort @ca ],
    'HasClassAttribute get_class_attribute_list gets all class attributes'
);

is_deeply(
    [
        sort map { $_->name() }
            HasClassAttribute->meta()->get_all_attributes()
    ],
    ['size'],
    'HasClassAttribute get_all_attributes only finds size attribute'
);

is_deeply(
    [
        sort map { $_->name() }
            HasClassAttribute->meta()->get_all_class_attributes()
    ],
    [ sort @ca ],
    'HasClassAttribute get_all_class_attributes gets all class attributes'
);

is_deeply(
    [ sort keys %{ HasClassAttribute->meta()->get_class_attribute_map() } ],
    [ sort @ca ],
    'HasClassAttribute get_class_attribute_map gets all class attributes'
);

is_deeply(
    [ sort map { $_->name() } Child->meta()->get_all_class_attributes() ],
    [ sort ( @ca, 'YetAnotherAttribute' ) ],
    'Child get_class_attribute_map gets all class attributes'
);

ok(
    !Child->meta()->has_class_attribute('ObjectCount'),
    q{has_class_attribute('ObjectCount') returns false for Child}
);

ok(
    Child->meta()->has_class_attribute('YetAnotherAttribute'),
    q{has_class_attribute('YetAnotherAttribute') returns true for Child}
);

ok(
    Child->can('YetAnotherAttribute'),
    'Child has accessor for YetAnotherAttribute'
);

ok(
    Child->meta()->has_class_attribute_value('YetAnotherAttribute'),
    'Child has class attribute value for YetAnotherAttribute'
);

Child->meta()->remove_class_attribute('YetAnotherAttribute');

ok(
    !Child->meta()->has_class_attribute('YetAnotherAttribute'),
    q{... has_class_attribute('YetAnotherAttribute') returns false after remove_class_attribute}
);

ok(
    !Child->can('YetAnotherAttribute'),
    'accessor for YetAnotherAttribute has been removed'
);

ok(
    !Child->meta()->has_class_attribute_value('YetAnotherAttribute'),
    'Child does not have a class attribute value for YetAnotherAttribute'
);

done_testing();
