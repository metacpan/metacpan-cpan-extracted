use v5.28;

use Test2::V0;

use Scalar::ValueTags;
skip_all "Scalar::ValueTags is not enabled" unless value_tags_enabled;

# use same ScalarValueTags type for all tests
my $vt_type;
{
    $vt_type = register_value_tags_type(SVTAGS_UNIQUE_HASH);
    ok( $vt_type, 'register_value_tags_type');
}

# combining one tagged variable with one untagged variable
{
    my $var_one = 123;
    my $tag = 'test_tag';
    add_value_tag( $vt_type, \$var_one, $tag );

    is( get_value_tags( $vt_type, \$var_one ), {$tag => 1},
        'get_value_tags should return tags from tagged variable' );

    my $var_two = 456;

    is( get_value_tags( $vt_type, \$var_two ), {},
        'get_value_tags should return empty hash from untagged variable' );

    my $in_order = $var_one + $var_two;

    is( get_value_tags( $vt_type, \$in_order ), {$tag => 1},
        'get_value_tags should return initial tag when tag is on first variable' );

    my $out_of_order = $var_two + $var_one;
    is( get_value_tags( $vt_type, \$out_of_order ), {$tag => 1},
        'get_value_tags should return initial tag when tag is on second variable' );
}

# combining two tagged variables
{
    my $var_one = 123;
    my $tag_one = 'tag_one';
    add_value_tag( $vt_type, \$var_one, $tag_one );

    is( get_value_tags( $vt_type, \$var_one ), {$tag_one => 1},
        'get_value_tags on first variable should be correct' );

    my $var_two = 456;
    my $tag_two = 'tag_two';
    add_value_tag( $vt_type, \$var_two, $tag_two );

    is( get_value_tags( $vt_type, \$var_two ), {$tag_two => 1},
        'get_value_tags on second variable should be correct' );

    my $combined = $var_one + $var_two;

    is( get_value_tags( $vt_type, \$combined ), {$tag_one => 1, $tag_two => 1},
        'get_value_tags should return both tags' );
}

# combining duplicate tags
{
    my $tag_one = 'tag_one';
    my $tag_two = 'tag_two';

    my $var = 123;
    add_value_tag( $vt_type, \$var, $tag_one );

    is( get_value_tags( $vt_type, \$var ), {$tag_one => 1},
        'after first tag_one added, get_value_tags should return tag_one' );

    add_value_tag( $vt_type, \$var, $tag_one );

    is( get_value_tags( $vt_type, \$var ), {$tag_one => 1},
        'after second tag_one added, get_value_tags should return tag_one' );

    add_value_tag( $vt_type, \$var, $tag_two );

    # FIXME: is tag order deterministic in implementation?
    is( get_value_tags( $vt_type, \$var ), { $tag_one => 1, $tag_two => 1 },
        'after first tag_two added, get_value_tags should return tag_one and tag_two' );

    add_value_tag( $vt_type, \$var, $tag_two );

    is( get_value_tags( $vt_type, \$var ), { $tag_one => 1, $tag_two => 1 },
        'after second tag_two added, get_value_tags should return tag_one and tag_two' );
}

# removing value tags
{
    my $tag_one   = 'one';
    my $tag_two   = 'two';
    my $tag_three = 'three';

    # add each tag that number of times
    my $var = 123;
    add_value_tag( $vt_type, \$var, $tag_one );
    add_value_tag( $vt_type, \$var, $tag_two );
    add_value_tag( $vt_type, \$var, $tag_three );

    is( get_value_tags( $vt_type, \$var ), { $tag_one => 1, $tag_two => 1, $tag_three => 1 },
        'SETUP: get_value_tags should return all three tags' );

    remove_value_tag( $vt_type, \$var, $tag_one );

    is( get_value_tags( $vt_type, \$var ), { $tag_two => 1, $tag_three => 1 },
        'after tag_one removed, get_value_tags should return tag_two and tag_three' );

    remove_value_tag( $vt_type, \$var, $tag_three );

    is( get_value_tags( $vt_type, \$var ), { $tag_two => 1 },
        'after tag_three removed, get_value_tags should return tag_two' );

    # remove all remaining tags
    remove_value_tag( $vt_type, \$var, $tag_two );

    is( get_value_tags( $vt_type, \$var ), {},
        'after final tag_two removed, get_value_tags should return no tags' );

    # remove nonexistent tag
    remove_value_tag( $vt_type, \$var, $tag_one );

    is( get_value_tags( $vt_type, \$var ), {},
        'after nonexistent tag removed, get_value_tags should return empty hash' );

    # remove tag from untagged var
    my $untagged_var = 9;
    remove_value_tag( $vt_type, \$untagged_var, $tag_one );

    is( get_value_tags( $vt_type, \$untagged_var ), {},
        'after tag removed from untagged variable, get_value_tags should return empty hash' );
}

done_testing;
