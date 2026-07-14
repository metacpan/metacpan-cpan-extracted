use v5.28;

use Test2::V0;

use Scalar::ValueTags;
skip_all "Scalar::ValueTags is not enabled" unless value_tags_enabled;

# use same ScalarValueTags type for all tests
my $vt_type;
{
    $vt_type = register_value_tags_type(SVTAGS_HASH_COUNT);
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

    is( $in_order, 123 + 456, 'new variable should have sum of others' );
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

    is( $combined, 123 + 456, 'new variable should have sum of others' );
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
        'after first tag_one added, get_value_tags should return one count of tag_one' );

    add_value_tag( $vt_type, \$var, $tag_one );

    is( get_value_tags( $vt_type, \$var ), {$tag_one => 2},
        'after second tag_one added, get_value_tags should return two counts of tag_one' );

    add_value_tag( $vt_type, \$var, $tag_two );

    # FIXME: is tag order deterministic in implementation?
    is( get_value_tags( $vt_type, \$var ), { $tag_one => 2, $tag_two => 1 },
        'after first tag_two added, get_value_tags should return two counts of tag_one and one of tag_two' );

    add_value_tag( $vt_type, \$var, $tag_two );

    is( get_value_tags( $vt_type, \$var ), { $tag_one => 2, $tag_two => 2 },
        'after second tag_two added, get_value_tags should return two counts of both tag_one and tag_two' );
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
    add_value_tag( $vt_type, \$var, $tag_two );
    add_value_tag( $vt_type, \$var, $tag_three );
    add_value_tag( $vt_type, \$var, $tag_three );
    add_value_tag( $vt_type, \$var, $tag_three );

    is( get_value_tags( $vt_type, \$var ), { $tag_one => 1, $tag_two => 2, $tag_three => 3 },
        'SETUP: get_value_tags should return correct counts for all three tags' );

    remove_value_tag( $vt_type, \$var, $tag_one );

    is( get_value_tags( $vt_type, \$var ), { $tag_two => 2, $tag_three => 3 },
        'after one tag_one removed, get_value_tags should return tag_two = 2 and tag_three = 3' );

    remove_value_tag( $vt_type, \$var, $tag_three );

    is( get_value_tags( $vt_type, \$var ), { $tag_two => 2, $tag_three => 2 },
        'after one tag_three removed, get_value_tags should return tag_two = 2 and tag_three = 2' );

    # remove all remaining tags
    remove_value_tag( $vt_type, \$var, $tag_two );
    remove_value_tag( $vt_type, \$var, $tag_two );
    remove_value_tag( $vt_type, \$var, $tag_three );
    remove_value_tag( $vt_type, \$var, $tag_three );

    is( get_value_tags( $vt_type, \$var ), {},
        'after all remaining tags removed, get_value_tags should return no tags' );

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
1;
