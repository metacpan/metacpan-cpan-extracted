#! perl
#
# Testing basic functions of iterator.

use strict;
use warnings;
use Test::More tests => 4;

use Template::Flute::Iterator;

subtest "Initialisation with a cart of items" => sub {
    plan tests => 3;

    my $cart = [
        {
            isbn => '978-0-2016-1622-4',
            title => 'The Pragmatic Programmer',
            quantity => 1
        },
        {
            isbn => '978-1-4302-1833-3',
            title => 'Pro Git',
            quantity => 1
        },
    ];

    my $iter = Template::Flute::Iterator->new($cart);
    isa_ok($iter, 'Template::Flute::Iterator');

    ok($iter->count == 2, "Item count is correct");

    isa_ok($iter->next, 'HASH', "Next item is a hash reference");
};

subtest "Initialisation with a seed item" => sub {
    plan tests => 1;

    my $iter = Template::Flute::Iterator->new;
    $iter->seed(
        {
            isbn => '978-0-9779201-5-0',
            title => 'Modern Perl',
            quantity => 10
        }
    );

    ok($iter->count == 1, "Item count is correct");
};

subtest "Sort an iterator" => sub {
    plan tests => 4;

    my $cart = [
        {
            isbn => '978-0-2016-1622-4',
            title => 'The Pragmatic Programmer',
            quantity => 1
        },
        {
            isbn => '978-1-4302-1833-3',
            title => 'Pro Git',
            quantity => 1
        },
        {
            isbn => '978-0-9779201-5-0',
            title => 'Modern Perl',
            quantity => 10
        }
    ];

    my $iter = Template::Flute::Iterator->new($cart);
    ok($iter->count == 3, "Item count is correct");

    $iter->sort('title');
    my $item = $iter->next;
    is $item->{'title'}, "Modern Perl",
        "Expected item title from sorted iterator";
    $item = $iter->next;
    is $item->{'title'}, "Pro Git",
        "Expected item title from sorted iterator";
    $item = $iter->next;
    is $item->{'title'}, "The Pragmatic Programmer",
        "Expected item title from sorted iterator";
};

subtest "Sort in iterator; uniquely" => sub {
    plan tests => 5;

    my $cart = [
        {
            isbn => '978-0-2016-1622-4',
            title => 'The Pragmatic Programmer',
            quantity => 1
        },
        {
            isbn => '978-1-4302-1833-3',
            title => 'Pro Git',
            quantity => 1
        },
        {
            isbn => '978-0-9779201-5-0',
            title => 'Modern Perl',
            quantity => 10
        },
        {
            isbn => '978-1-4302-1833-3',
            title => 'Pro Git',
            quantity => 5
        },
    ];

    my $iter = Template::Flute::Iterator->new($cart);
    ok($iter->count == 4, "Item count is correct");

    $iter->sort('title', unique => 1);

    my $item = $iter->next;
    is $item->{'title'}, "Modern Perl",
        "Expected item title from sorted iterator";
    $item = $iter->next;
    is $item->{'title'}, "Pro Git",
        "Expected item title from sorted iterator";
    $item = $iter->next;
    is $item->{'title'}, "The Pragmatic Programmer",
        "Expected item title from sorted iterator";

    is $iter->next, undef, "No further items in iterator";
};
