#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';
use Test::Exception;
use Test::Moose;

BEGIN {
    use_ok('MooseX::MetaDescription');
}

{
    package Foo::Description::Trait;
    use Moose::Role;
    
    has 'bar'   => (is => 'ro', isa => 'Str');
    has 'baz'   => (is => 'ro', isa => 'Str');    
    has 'gorch' => (is => 'ro', isa => 'Str');        

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
            traits => [qw[Foo::Description::Trait]],
            baz    => 'Foo::bar::baz',
            gorch  => 'Foo::bar::gorch',
        }
    );
    
    has 'baz' => (
        traits      => [ 'MooseX::MetaDescription::Meta::Trait' ],
        is          => 'ro',
        isa         => 'Str',   
        default     => sub { 'Foo::baz' },
        description => {
            traits => [qw[Foo::Description::Trait]],
            bar    => 'Foo::baz::bar',
            gorch  => 'Foo::baz::gorch',
        }
    );    
}

# check the meta-desc

my $bar_attr = Foo->meta->get_attribute('bar');
isa_ok($bar_attr->metadescription, 'MooseX::MetaDescription::Description');
does_ok($bar_attr->metadescription, 'Foo::Description::Trait');
is($bar_attr->metadescription->descriptor, $bar_attr, '... got the circular ref');

my $baz_attr = Foo->meta->get_attribute('baz');
isa_ok($baz_attr->metadescription, 'MooseX::MetaDescription::Description');
does_ok($baz_attr->metadescription, 'Foo::Description::Trait');
is($baz_attr->metadescription->descriptor, $baz_attr, '... got the circular ref');

# check the actual descs

foreach my $foo ('Foo', Foo->new) {

    is_deeply(
        $foo->meta->get_attribute('bar')->description,
        {
            baz   => 'Foo::bar::baz',
            gorch => 'Foo::bar::gorch',
        },
        '... got the right class description'
    );
    
    my $bar_meta_desc = $foo->meta->get_attribute('bar')->metadescription;
    is($bar_meta_desc->baz,   'Foo::bar::baz',   '... we have methods');
    is($bar_meta_desc->gorch, 'Foo::bar::gorch', '... we have methods');    

    is_deeply(
        $foo->meta->get_attribute('baz')->description,
        {
            bar   => 'Foo::baz::bar',
            gorch => 'Foo::baz::gorch',
        },
        '... got the right class description'
    );
    
    my $baz_meta_desc = $foo->meta->get_attribute('baz')->metadescription;
    is($baz_meta_desc->bar,   'Foo::baz::bar',   '... we have methods');
    is($baz_meta_desc->gorch, 'Foo::baz::gorch', '... we have methods');    
}

