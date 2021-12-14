#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 14;
use Test::Differences qw( eq_or_diff );

use Set::CSS ();

{
    my $set = Set::CSS->new( "class1", );
    $set->insert("blast");

    # Avoiding duplicates
    $set->insert("class1");

    # TEST
    eq_or_diff(
        $set->html_attrs(),
        {
            class => "blast class1"
        },
        "html_attrs on full"
    );

    # TEST
    eq_or_diff( $set->as_html(), ' class="blast class1"', "as_html on full" );
}

{
    my $set = Set::CSS->new();

    # TEST
    eq_or_diff( $set->html_attrs(), +{}, "html_attrs on empty" );

    # TEST
    eq_or_diff( $set->as_html(), q##, "as_html on empty" );

    # TEST
    eq_or_diff(
        $set->html_attrs( { on_empty => 1, } ),
        {
            class => ""
        },
        "html_attrs on on_empty"
    );

    # TEST
    eq_or_diff( $set->as_html( { on_empty => 1, } ),
        ' class=""', "as_html on on_empty" );
}

{
    my $set = Set::CSS->new();

    # TEST
    eq_or_diff( [ $set->addClass("foo") ], [], "addClass returns empty" );

    # TEST
    eq_or_diff( $set->as_html( { on_empty => 0, } ),
        ' class="foo"', "foo is there" );

    # TEST
    eq_or_diff( [ $set->removeClass("foo") ], [], "removeClass returns empty" );

    # TEST
    eq_or_diff( $set->as_html( { on_empty => 0, } ), '', "foo is there" );
}

{
    my $set = Set::CSS->new();

    # TEST
    eq_or_diff( [ $set->toggleClass("foo") ], [], "toggleClass returns empty" );

    # TEST
    eq_or_diff( $set->as_html( { on_empty => 0, } ),
        ' class="foo"', "foo is there" );

    # TEST
    eq_or_diff( [ $set->toggleClass("foo") ], [], "toggleClass returns empty" );

    # TEST
    eq_or_diff( $set->as_html( { on_empty => 0, } ), '', "foo is there" );
}
