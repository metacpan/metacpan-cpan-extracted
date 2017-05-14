$tested {common_loaded} = 1;

can_ok $class,

    # Constructor
    qw( new ),

    # OO Support
    qw( attributes attribute_is filtered_attributes clone displayed_attributes dump
    syncupdates_update syncupdates_delete syncupdates_create _object_factory
    _single_attribute_setget _multiple_attribute_setget _syncupdates_submit );

ok( !$object->can('bogusmethod'), "No AUTOLOAD interference with $class tests" );

for my $a ( $object->attributes('mandatory') ) {
    ok( $object->attribute_is( $a, 'mandatory' ), "Attribute $a is mandatory" );
    ok( !$object->attribute_is( $a, 'optional' ), "Attribute $a is not optional");
}

for my $a ( $object->attributes('optional') ) {
    ok( !$object->attribute_is( $a, 'mandatory' ), "Attribute $a is not mandatory" );
    ok( $object->attribute_is( $a, 'optional' ), "Attribute $a is optional");
}

for my $a ( $object->attributes('single') ) {
    ok( $object->attribute_is( $a, 'single' ), "Attribute $a is single valued" );
    ok( !$object->attribute_is( $a, 'multiple', "Attribute $a is multi valued" ) );
}

for my $a ( $object->attributes('multiple') ) {
    ok( !$object->attribute_is( $a, 'single' ), "Attribute $a is single valued" );
    ok( $object->attribute_is( $a, 'multiple', "Attribute $a is multi valued" ) );
}

# Check that all attributes have been tested

for my $a ( $object->attributes('all') ) {
    # Check that each attribute is set either to 'single' or 'multiple'
    ok ($object->attribute_is($a, 'single') or $object->attribute_is($a, 'multiple'), "$a is either single or multiple");
    ok ($object->attribute_is($a, 'single') != $object->attribute_is($a, 'multiple'), "$a can't be both single".$object->attribute_is($a,'single')." and multi".$object->attribute_is($a,'multiple'));
}

# check that the object can be dumped
# this catches spelling errors in attribute accessors
ok $object->dump, 'can dump object';
