use v5.28;

use Test2::V0 -no_srand => 1;
use Test2::Tools::Subtest 'subtest_buffered';

use Scalar::ValueTags;
skip_all "Scalar::ValueTags is not enabled" unless value_tags_enabled;

subtest_buffered constants => sub {
    ok( value_tags_enabled, 'value_tags_enabled constant is true' );
    ok( defined SVTAGS_UNIQUE_REF_ARRAY, 'SVTAGS_UNIQUE_REF_ARRAY should be defined' );
    ok( defined SVTAGS_APPEND_ARRAY, 'SVTAGS_APPEND_ARRAY should be defined' );
    ok( defined SVTAGS_HASH_COUNT, 'SVTAGS_HASH_COUNT should be defined' );
};

subtest_buffered register_value_tags_type => sub {
    my $vt_type;
    like( dies { $vt_type = register_value_tags_type() }, qr/Usage:/, 'failure: missing behavior arg');
    like( dies { $vt_type = register_value_tags_type([]) }, qr/Expected an integer for behavior/, 'failure: ref as behavior arg');
    like( dies { $vt_type = register_value_tags_type(-1) }, qr/Unknown behavior/, 'failure: negative behavior arg');
    like( dies { $vt_type = register_value_tags_type(99) }, qr/Unknown behavior/, 'failure: too-large behavior arg');

    ok(lives { $vt_type = register_value_tags_type(SVTAGS_UNIQUE_REF_ARRAY) }, 'success: valid behavior arg' );
    ok( ref($vt_type), '  returns a ref' );
};

# use same Scalar::ValueTags type for all tests
my $vt_type = register_value_tags_type(SVTAGS_APPEND_ARRAY);

subtest_buffered add_value_tag_validation => sub {
    my $var = 123;
    my $tag = 'tag_one';

    like( dies { add_value_tag( 1, \$var, $tag ) }, qr/Invalid vt_type/,
        'error for invalid vt_type should be as expected' );
    like( dies { add_value_tag( $vt_type, [], $tag ) }, qr/Expected a SCALAR reference for target variable/,
        'error for invalid var should be as expected' );
};

subtest_buffered get_value_tags_validation => sub {
    my $var = 123;

    like( dies { get_value_tags( 1, \$var ) }, qr/Invalid vt_type/,
        'error for invalid vt_type should be as expected' );
    like( dies { get_value_tags( $vt_type, [] ) }, qr/Expected a SCALAR reference for target variable/,
        'error for invalid var should be as expected' );
};

subtest_buffered clear_value_tags_validation => sub {
    my $var = 123;

    like( dies { clear_value_tags( 1, \$var ) }, qr/Invalid vt_type/,
        'error for invalid vt_type should be as expected' );
    like( dies { clear_value_tags( $vt_type, [] ) }, qr/Expected a SCALAR reference for target variable/,
        'error for invalid var should be as expected' );
};

subtest_buffered get_value_tags => sub {
    my $var = 123;

    is( get_value_tags( $vt_type, \$var ), [],
        'get_value_tags on untagged variable should return empty array' );

    is( get_value_tags( $vt_type, \do{ 12 + 34 } ), [],
        'get_value_tags on empty intermediate expression should return empty array' );
};

subtest_buffered value_tags_handling => sub {
    my $var = 123;
    my $tag_one = 'tag_one';

    add_value_tag( $vt_type, \$var, $tag_one );
    is( get_value_tags( $vt_type, \$var ), [$tag_one],
        'get_value_tags should return added tag' );
    is( get_value_tags( $vt_type, \$var ), [$tag_one],
        'subsequent get_value_tags should return tag' );

    clear_value_tags( $vt_type, \$var );
    is( get_value_tags( $vt_type, \$var ), [],
        'get_value_tags should return empty array after tags are cleared' );

    $var = 456;
    my $tag_two = 'tag_two';
    add_value_tag( $vt_type, \$var, $tag_two );
    is( get_value_tags( $vt_type, \$var ), [$tag_two],
        'get_value_tags should return added tag' );
    $var = 42;
    is( get_value_tags( $vt_type, \$var ), [],
        'get_value_tags should return empty array after var is set to new value' );

    my $tag_three = 'tag_three';
    add_value_tag( $vt_type, \$var, $tag_three );
    is( get_value_tags( $vt_type, \$var ), [$tag_three],
        'get_value_tags should return added tag' );
    undef $var;
    is( get_value_tags( $vt_type, \$var ), [],
        'get_value_tags should return empty array after var is set to undef' );

    add_value_tag( $vt_type, \$var, $tag_one );
    is( get_value_tags( $vt_type, \$var ), [$tag_one],
        'get_value_tags on undefined variable should return added tag' );
};

done_testing;
1;
