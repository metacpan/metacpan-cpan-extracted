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
    package Foo::MetaDescription::Attribute;
    use Moose;
    
    extends 'MooseX::MetaDescription::Meta::Attribute';
    
    sub prepare_traits_for_application {
        my ($self, $traits) = @_;
        [ map { "${_}::Description::Trait" } @$traits ]
    }
}

{
    package Foo;
    use Moose;
    
    has 'baz' => (
        metaclass   => 'Foo::MetaDescription::Attribute',
        is          => 'ro',
        isa         => 'Str',   
        default     => sub { 'Foo::baz' },
        description => {
            traits => [qw[Foo]],
            bar    => 'Foo::baz::bar',
            gorch  => 'Foo::baz::gorch',
        }
    );    
}

# check the meta-desc

my $baz_attr = Foo->meta->get_attribute('baz');
isa_ok($baz_attr->metadescription, 'MooseX::MetaDescription::Description');
does_ok($baz_attr->metadescription, 'Foo::Description::Trait');
is($baz_attr->metadescription->descriptor, $baz_attr, '... got the circular ref');

# check the actual descs

foreach my $foo ('Foo', Foo->new) {

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

