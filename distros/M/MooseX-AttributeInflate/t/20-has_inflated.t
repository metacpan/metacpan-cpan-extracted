#!perl
use warnings;
use strict;
use Test::More tests => 6;
use Test::Exception;

lives_ok {
    package Book;
    use Moose;
    has 'text' => (is => 'ro', isa => 'Str', default => 'Shakespeare');

    package ShrinkWrap;
    use MooseX::AttributeInflate;

    has_inflated 'book' => (
        is => 'ro',
        isa => 'Book',
        inflate_args => [text => "There's Waldo!"],
    );

    has 'label' => (is => 'rw', isa => 'Str');

} 'can use "has_inflated"';

happy_path: {
    my $o = ShrinkWrap->new(label => 'Good Book');
    isa_ok $o, 'ShrinkWrap';
    isa_ok $o->book, 'Book';
    is $o->book->text, "There's Waldo!";
    is $o->label, 'Good Book';
}

invalid_type: dies_ok {
    package Blearg;
    use MooseX::AttributeInflate;
    has_inflated 'not_really' => (is => 'ro', isa => 'Int');
} "can't use has_inflated on a non-object";
