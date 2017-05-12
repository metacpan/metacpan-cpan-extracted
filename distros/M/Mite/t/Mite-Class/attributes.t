#!/usr/bin/perl

use lib 't/lib';
use Test::Mite;

tests "all_attributes" => sub {
    my $gparent = sim_class( name => "GP1" );
    my $parent  = sim_class( name => "P1" );
    my $child   = sim_class( name => "C1" );

    $parent->extends(["GP1"]);
    $child->extends(["P1"]);

    $gparent->add_attributes(
        sim_attribute( name => "from_gp" ),
        sim_attribute( name => "this" ),
    );
    $parent->add_attributes(
        sim_attribute( name => "from_p" ),
        sim_attribute( name => "in_p" ),
        sim_attribute( name => "that" )
    );
    $child->add_attributes(
        sim_attribute( name => "in_p" ),
        sim_attribute( name => "from_c" ),
    );

    cmp_deeply $gparent->all_attributes, $gparent->attributes;

    my %p_all_attrs_want = (
        from_gp         => $gparent->attributes->{from_gp},
        this            => $gparent->attributes->{this},
        from_p          => $parent->attributes->{from_p},
        in_p            => $parent->attributes->{in_p},
        that            => $parent->attributes->{that},
    );
    cmp_deeply $parent->all_attributes, \%p_all_attrs_want;

    my %c_all_attrs_want = (
        from_gp         => $gparent->attributes->{from_gp},
        this            => $gparent->attributes->{this},
        from_p          => $parent->attributes->{from_p},
        in_p            => $child->attributes->{in_p},
        that            => $parent->attributes->{that},
        from_c          => $child->attributes->{from_c},
    );
    cmp_deeply $child->all_attributes, \%c_all_attrs_want;

    cmp_deeply $child->parents_attributes,   \%p_all_attrs_want;
    cmp_deeply $parent->parents_attributes,  $gparent->all_attributes;
    cmp_deeply $gparent->parents_attributes, {};
};


tests "extend_attribute" => sub {
    my $gparent = sim_class( name => "GP1" );
    my $parent  = sim_class( name => "P1" );
    my $child   = sim_class( name => "C1" );

    $parent->extends(["GP1"]);
    $child->extends(["P1"]);

    $gparent->add_attributes(
        sim_attribute( name => "foo", is => "ro", default => 23 ),
    );
    $child->extend_attribute(
        name    => "foo",
        default => sub { 99 }
    );

    my $extended_attribute = $child->attributes->{foo};
    is $extended_attribute->name,       "foo";
    is $extended_attribute->is,         "ro";
    is $extended_attribute->default->(), 99;
};

done_testing;
