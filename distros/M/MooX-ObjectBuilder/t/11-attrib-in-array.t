#!/usr/bin/perl

=pod

=encoding utf-8

=head1 PURPOSE

Test C<< make_builder($class, \@args) >>.

=head1 AUTHOR

Torbjørn Lindahl.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Torbjørn Lindahl.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;
use Test::Warnings;

use t::lib::TestUtils;

{
    package Author;
    use Moo;
    extends 'Person';
    has age => (is => 'ro');
}

{
    package Book;
    use Moo;
    use MooX::ObjectBuilder;
    has title => (is => 'rw');
    has author => (
        predicate => 1,
        clearer => 1,
        is => make_builder(
            Author => [qw/name age/]
        ),
    );

}

my $book = 'Book'->new(
    title      => 'Bobs Book',
    name       => 'Bob',
    age        => 42,
);

ok( ! $book->has_author, 'Lazy author' );

isa_ok( $book->author, 'Person' );
isa_ok( $book->author, 'Author' );

my $test_attr_objects = sub {
    is( $book->title, 'Bobs Book' );
    is( $book->author->name, 'Bob', 'author name' );
    is( $book->author->age, 42, 'author age' );
};

subtest 'attribute object properties' => sub {  $test_attr_objects->() };

$book->clear_author;

ok( ! $book->has_author, 'author cleared' );

subtest 'attribute object properties after recreation' => sub {  $test_attr_objects->() };

done_testing;