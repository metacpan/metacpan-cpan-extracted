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
            'Hello' => 'World',
            'World' => 'Hello',
        }
    );
    use Moose;

    package Bar;
    use Moose;

    extends 'Foo';
    
    # always add it *after* the extends
    __PACKAGE__->meta->description->{'Hello'} = 'Earth';
    
    package Baz;
    use Moose;

    extends 'Bar';
    
    package Gorch;
    use metaclass 'MooseX::MetaDescription::Meta::Class' => (
        description => {
            'Hello' => 'World'
        }
    );    
    use Moose;

    extends 'Baz';    
}

# check the meta-desc

my $foo_class = Foo->meta;
isa_ok($foo_class, 'MooseX::MetaDescription::Meta::Class');
isa_ok($foo_class->metadescription, 'MooseX::MetaDescription::Description');
is($foo_class->metadescription->descriptor, $foo_class, '... got the circular ref');

my $bar_class = Bar->meta;
isa_ok($bar_class, 'MooseX::MetaDescription::Meta::Class');
isa_ok($bar_class->metadescription, 'MooseX::MetaDescription::Description');
is($bar_class->metadescription->descriptor, $bar_class, '... got the circular ref');

my $baz_class = Baz->meta;
isa_ok($baz_class, 'MooseX::MetaDescription::Meta::Class');
isa_ok($baz_class->metadescription, 'MooseX::MetaDescription::Description');
is($baz_class->metadescription->descriptor, $baz_class, '... got the circular ref');

my $gorch_class = Gorch->meta;
isa_ok($gorch_class, 'MooseX::MetaDescription::Meta::Class');
isa_ok($gorch_class->metadescription, 'MooseX::MetaDescription::Description');
is($gorch_class->metadescription->descriptor, $gorch_class, '... got the circular ref');

foreach my $x ('Foo', Foo->new) {
    is_deeply(
        $x->meta->description,
        { 
            'Hello' => 'World',
            'World' => 'Hello'            
        },
        '... got the right class description'
    );
}

foreach my $x ('Bar', Bar->new) {
    is_deeply(
        $x->meta->description,
        { 
            'Hello' => 'Earth',
            'World' => 'Hello'            
        },
        '... got the right class description (inherited and changed)'
    );
}

foreach my $x ('Baz', Baz->new) {
    is_deeply(
        $x->meta->description,
        { 
            'Hello' => 'Earth',
            'World' => 'Hello'            
        },
        '... got the right class description (inherited with changes handles correctly)'
    );
}

foreach my $x ('Gorch', Gorch->new) {
    is_deeply(
        $x->meta->description,
        { 
            'Hello' => 'World',
        },
        '... got the right class description (with completely overriden desc)'
    );
}
