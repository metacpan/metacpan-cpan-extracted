#!perl
use strict;
use warnings;

use Data::Dumper;

use Test::More;
use Test::Fatal;
use Test::Moose;

BEGIN {
    use_ok('PONAPI::Document::Builder::Resource');
}

subtest '... testing constructor' => sub {

    my $builder = PONAPI::Document::Builder::Resource->new(
        id   => '1',
        type => 'articles',
    );
    isa_ok( $builder, 'PONAPI::Document::Builder::Resource');
    does_ok($builder, 'PONAPI::Document::Builder');
    does_ok($builder, 'PONAPI::Document::Builder::Role::HasLinksBuilder');
    does_ok($builder, 'PONAPI::Document::Builder::Role::HasMeta');

    is($builder->id, '1', '... got the expected id');
    is($builder->type, 'articles', '... got the expected type');

    can_ok( $builder, $_ ) foreach qw[
        add_attribute
        add_attributes
        has_attributes
        has_attribute_for

        add_relationship
        has_relationships
        has_relationship_for

        links_builder
        add_link
        add_links
        add_meta

        build
    ];

};

subtest '... testing constructor errors' => sub {

    like(
        exception { PONAPI::Document::Builder::Resource->new },
        qr/^Attribute \(.+\) is required at /,
        '... got the error we expected'
    );

    like(
        exception { PONAPI::Document::Builder::Resource->new( id => '1' ) },
        qr/^Attribute \(type\) is required at /,
        '... got the error we expected'
    );

    like(
        exception { PONAPI::Document::Builder::Resource->new( type => 'articles' ) },
        qr/^Attribute \(id\) is required at /,
        '... got the error we expected'
    );

};

subtest '... attributes with zero values are preserved' => sub {
    my $resource = PONAPI::Document::Builder::Resource->new( type => 'foo', id => 1 );
    my %values = (
        true       => "i am true!",
        undef      => undef,
        zero       => 0,
        empty_str  => '',
        zero_str   => '0',
        zero_float => 0E0,
        zero_but_true => '0 but true',
        bool_neg   => !!0,
    );
    $resource->add_attributes(%values);
    my $built = $resource->build;
    is_deeply(
        $built->{attributes},
        \%values,
        "false values are passed and preserved",
    ) or diag(Dumper($built));
};

done_testing;
