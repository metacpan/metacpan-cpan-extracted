#!perl
use warnings;
use strict;
use Test::More tests => 26;
use Test::Exception;

BEGIN {
    require_ok 'MooseX::AttributeInflate';
}

{
    package MyClass::Document;
    use Moose;

    has 'text' => (is => 'ro', isa => 'Str', default => 'O Hai');

    package MyClass;
    use Moose;
    use MooseX::AttributeInflate;

    has 'document' => (
        is => 'ro', isa => 'MyClass::Document',
        traits => [qw/Inflated/],
    );
}

happy_path: {
    my $o = MyClass->new();
    my $doc;
    lives_ok {
        $doc = $o->document;
    } 'got doc';
    isa_ok $doc => 'MyClass::Document';
    is $doc->text, 'O Hai';
}

{
    package MyClass2;
    use Moose;
    use MooseX::AttributeInflate;
    extends 'MyClass';

    has '+document' => (
        inflate_args => [text => 'Yup']
    );
}

construct_args: {
    my $o = MyClass2->new;
    my $doc;
    lives_ok {
        $doc = $o->document;
    } 'got doc';
    isa_ok $doc => 'MyClass::Document';
    is $doc->text, 'Yup';
}

{
    package NonMoose;
    use strict;

    sub buildit {
        my $class = shift;
        return bless [@_], $class;
    }

    package MyClass3;
    use Moose;
    use MooseX::AttributeInflate;
    extends 'MyClass';

    has '+document' => (
        isa => 'NonMoose',
        inflate_method => 'buildit',
        inflate_args => [qw(here it is)]
    );
}

construct_method: {
    my $o = MyClass3->new;
    my $doc;
    lives_ok {
        $doc = $o->document;
    } 'got doc';
    isa_ok $doc => 'NonMoose';
    is_deeply $doc, [qw(here it is)];
}

non_object: throws_ok {
    package WTF;
    use Moose;
    use MooseX::AttributeInflate;

    has 'name' => (
        is => 'rw', isa => 'Str',
        traits => [qw/Inflated/],
    );
} qr/subtype of Object/, "can't inflate a non-Object";

is_object: throws_ok {
    package WTF;
    use Moose;
    use MooseX::AttributeInflate;

    has 'name' => (
        is => 'rw', isa => 'Object',
        traits => [qw/Inflated/],
    );
} qr/subtype of Object/, "can't inflate a direct Object";


{
    package MyLazyClass;
    use Moose;
    use MooseX::AttributeInflate;

    has 'doc1' => (
        is => 'ro', isa => 'MyClass::Document',
        traits => [qw/Inflated/],
        lazy_build => 1,
        default => sub { die 'should be overriden' },
    );
    has 'doc2' => (
        is => 'ro', isa => 'MyClass::Document',
        traits => [qw/Inflated/],
        lazy_build => 1,
        predicate => 'gots_doc2',
        clearer => 'scrub_doc2',
    );
}

lazy_build: {
    my $o = MyLazyClass->new;

    isa_ok $o => 'MyLazyClass', 'created MyLazyClass';
    ok $o->can('has_doc1'), 'standard predicate installed';
    ok $o->can('clear_doc1'), 'standard clearer installed';
    ok !$o->has_doc1;
    lives_ok { $o->doc1 } 'overrode the default';
    ok $o->doc1;
    ok $o->has_doc1;
    $o->clear_doc1;
    ok !$o->has_doc1, 'std clearer/predicate work';

    ok $o->can('gots_doc2'), 'alt predicate installed';
    ok $o->can('scrub_doc2'), 'alt clearer installed';
    ok !$o->gots_doc2;
    ok $o->doc2->text;
    ok $o->gots_doc2;
    $o->scrub_doc2;
    ok !$o->gots_doc2, 'alt clearer/predicate work';
}
