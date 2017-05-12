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
    use metaclass 'MooseX::MetaDescription::Meta::Class' => (
        description => {
            'Hello' => 'World'
        }
    );
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
}

# check the meta-desc

my $foo_class = Foo->meta;
isa_ok($foo_class, 'MooseX::MetaDescription::Meta::Class');
isa_ok($foo_class->metadescription, 'MooseX::MetaDescription::Description');
is($foo_class->metadescription->descriptor, $foo_class, '... got the circular ref');

my $bar_attr = Foo->meta->get_attribute('bar');
isa_ok($bar_attr->metadescription, 'MooseX::MetaDescription::Description');
is($bar_attr->metadescription->descriptor, $bar_attr, '... got the circular ref');

my $baz_attr = Foo->meta->get_attribute('baz');
isa_ok($baz_attr->metadescription, 'MooseX::MetaDescription::Description');
is($baz_attr->metadescription->descriptor, $baz_attr, '... got the circular ref');

# check the actual descs

foreach my $foo ('Foo', Foo->new) {
    is_deeply(
        $foo->meta->description,
        { 'Hello' => 'World' },
        '... got the right class description'
    );

    is_deeply(
        $foo->meta->get_attribute('bar')->description,
        {
            baz   => 'Foo::bar::baz',
            gorch => 'Foo::bar::gorch',
        },
        '... got the right class description'
    );

    is_deeply(
        $foo->meta->get_attribute('baz')->description,
        {
            bar   => 'Foo::baz::bar',
            gorch => 'Foo::baz::gorch',
        },
        '... got the right class description'
    );
}

