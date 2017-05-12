#!perl
use strict;
use warnings;

use Test::More;
use Test::Fatal;

BEGIN {
    use_ok('PONAPI::Document::Builder::Document')
}

subtest '... single document builder' => sub {

    my $root = PONAPI::Document::Builder::Document->new( version => '1.0' );
    isa_ok($root, 'PONAPI::Document::Builder::Document');

    ok($root->is_root, '... this is the root');

    ok(!$root->has_resource, '... we do not have a resource builder yet');

    my $resource;
    is(
        exception {
            $resource = $root->add_resource( type => 'foo', id => 100 )
        },
        undef,
        '... set the resource sucessfully'
    );
    isa_ok($resource, 'PONAPI::Document::Builder::Resource');

    my $links = $root->links_builder;
    isa_ok($links, 'PONAPI::Document::Builder::Links');

    my $errors = $root->errors_builder;
    isa_ok($errors, 'PONAPI::Document::Builder::Errors');

    ok(!$resource->is_root, '... this is not the root');
    ok(!$links->is_root, '... this is not the root');
    ok(!$errors->is_root, '... this is not the root');

    is($resource->parent, $root, '... the parent of resource is our root builder');
    is($links->parent, $root, '... the parent of links is our root builder');
    is($errors->parent, $root, '... the parent of errors is our root builder');

    is($resource->find_root, $root, '... the parent of resource is our root builder (find_root)');
    is($links->find_root, $root, '... the parent of links is our root builder (find_root)');
    is($errors->find_root, $root, '... the parent of errors is our root builder (find_root)');

    subtest '... resource builder' => sub {

        my $relationship = $resource->add_relationship('foo' => { type => 'foo', id => 200 });
        isa_ok($relationship, 'PONAPI::Document::Builder::Relationship');

        my $links = $resource->links_builder;
        isa_ok($links, 'PONAPI::Document::Builder::Links');

        is($relationship->parent, $resource, '... the parent of relationship is the resource builder');
        is($relationship->parent->parent, $root, '... the grand-parent of relationship is the root builder');

        is($relationship->find_root, $root, '... the grand-parent of relationship is the root builder (find_root)');

        is($links->parent, $resource, '... the parent of links is the resource builder');
        is($links->parent->parent, $root, '... the grand-parent of links is the root builder');

        is($links->find_root, $root, '... the grand-parent of links is the root builder (find_root)');

        subtest '... relationship builder' => sub {
            my $links = $relationship->links_builder;
            isa_ok($links, 'PONAPI::Document::Builder::Links');

            is($links->parent, $relationship, '... the parent of links is the relationship builder');
            is($links->parent->parent, $resource, '... the grand-parent of links is the resource builder');
            is($links->parent->parent->parent, $root, '... the great-grand-parent of links is the root builder');

            is($links->find_root, $root, '... the great-grand-parent of links is the root builder (find_root)');
        };

    };

    subtest '... included' => sub {

        my $resource = $root->add_included( type => 'foo', id => 200 );
        isa_ok($resource, 'PONAPI::Document::Builder::Resource');

        is($resource->parent, $root, '... the parent of resource is the document builder');
        is($resource->find_root, $root, '... the parent of resource is the document builder (find_root)');

    };
};

done_testing;
