#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';
use Test::Exception;

BEGIN {
    use_ok('MooseX::MetaDescription');
}

{
    package Foo;
    use Moose;

    has 'bar' => (
        metaclass   => 'MooseX::MetaDescription::Meta::Attribute',
        is          => 'ro',
        isa         => 'Str',
        default     => sub { 'Foo::bar' },
        description => {
            baz   => 'Foo::bar::baz',
            gorch => 'Foo::bar::gorch',
        }
    );

    has 'baz' => (
        traits      => [ 'MooseX::MetaDescription::Meta::Trait' ],
        is          => 'ro',
        isa         => 'Str',
        default     => sub { 'Foo::baz' },
        description => {
            bar   => 'Foo::baz::bar',
            gorch => 'Foo::baz::gorch',
        }
    );

    package Bar;
    use Moose;

    extends 'Foo';
}

# check the meta-desc

my $bar_attr = Foo->meta->find_attribute_by_name('bar');
isa_ok($bar_attr->metadescription, 'MooseX::MetaDescription::Description');
is($bar_attr->metadescription->descriptor, $bar_attr, '... got the circular ref');

my $baz_attr = Foo->meta->find_attribute_by_name('baz');
isa_ok($baz_attr->metadescription, 'MooseX::MetaDescription::Description');
is($baz_attr->metadescription->descriptor, $baz_attr, '... got the circular ref');

{

    my $bar_attr = Bar->meta->find_attribute_by_name('bar');

    can_ok($bar_attr, 'description');
    isa_ok($bar_attr->metadescription, 'MooseX::MetaDescription::Description');
    is($bar_attr->metadescription->descriptor, $bar_attr, '... got the circular ref');

    my $baz_attr = Bar->meta->find_attribute_by_name('baz');

    can_ok($baz_attr, 'description');
    isa_ok($baz_attr->metadescription, 'MooseX::MetaDescription::Description');
    is($baz_attr->metadescription->descriptor, $baz_attr, '... got the circular ref');

    my ($bar_attr_2, $baz_attr_2) = sort { $a->name cmp $b->name } Bar->meta->get_all_attributes;
    is($bar_attr, $bar_attr_2, '... got the same attribute');
    is($baz_attr, $baz_attr_2, '... got the same attribute');
}

# check the actual descs

foreach my $foo ('Foo', Foo->new, 'Bar', Bar->new) {

    is_deeply(
        $foo->meta->find_attribute_by_name('bar')->description,
        {
            baz   => 'Foo::bar::baz',
            gorch => 'Foo::bar::gorch',
        },
        '... got the right class description'
    );

    is_deeply(
        $foo->meta->find_attribute_by_name('baz')->description,
        {
            bar   => 'Foo::baz::bar',
            gorch => 'Foo::baz::gorch',
        },
        '... got the right class description'
    );
}
