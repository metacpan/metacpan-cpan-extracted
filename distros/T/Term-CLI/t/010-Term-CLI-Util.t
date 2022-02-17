#!/usr/bin/perl -T
#
# Copyright (c) 2018-2022, Steven Bakker.
#
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl 5.14.0. For more details, see the full text
# of the licenses in the directory LICENSES.
#

use 5.014_001;
use warnings;
use Test::More 1.001002;

my $TEST_NAME = 'UTIL';

sub Main() {
    if ( ($::ENV{SKIP_ALL} || $::ENV{"SKIP_$TEST_NAME"}) && !$::ENV{"TEST_$TEST_NAME"} ) {
       plan skip_all => 'skipped because of environment'
    }
    Term_CLI_Util_test->runtests();
    exit 0;
}

package TestObj {
    use Moo;
    has name => ( is => 'rw' );
}

package Term_CLI_Util_test {

use parent 0.225 qw( Test::Class );

use Test::More 1.001002;
use Term::CLI::Util qw( :all );

my $SEARCH_STR   = 'foo';
my @WORD_MATCHES = qw( foo foobar foobarbaz );

sub startup : Test(startup) {
    my ($self) = @_;

    my @word_list;
    for my $letter1 ('a'..'z') {
        for my $letter2 ('a'..'z') {
            push @word_list, $letter1 x 4 . $letter2 x 4;
        }
    }

    my @obj_list = map { TestObj->new(name => $_) } @word_list;
    $self->{word_list} = \@word_list;
    $self->{obj_list}  = \@obj_list;
}

sub check_is_prefix_str: Test(3) {
    my $str = 'foobarbaz';

    ok( is_prefix_str('foo',   $str), "'foo' is a prefix of '$str'" );
    ok( is_prefix_str('fooba', $str), "'fooba' is a prefix of '$str'" );
    ok( !is_prefix_str('bar',  $str), "'foo' is not a prefix of '$str'" );
    return;
}

sub check_is_find_text_matches: Test(10) {
    my ($self) = @_;

    my @zero_list   = ();
    my @long_list   = sort (@{$self->{word_list}}, @WORD_MATCHES,        'fon');
    my @medium_list = sort (@{$self->{word_list}}[0..99], @WORD_MATCHES, 'fon');
    my @short_list  = sort (@{$self->{word_list}}[0..20], @WORD_MATCHES, 'fon');


    my @got;

    @got = find_text_matches( $SEARCH_STR, undef );
    is_deeply(\@got, [ ], "find_text_matches(undef, not exact) returns correct results");

    @got = find_text_matches( $SEARCH_STR, undef, exact => 1 );
    is_deeply(\@got, [ ], "find_text_matches(undef, exact) returns correct results");

    @got = find_text_matches( $SEARCH_STR, \@zero_list );
    is_deeply(\@got, [ ], "find_text_matches(empty, not exact) returns correct results");

    @got = find_text_matches( $SEARCH_STR, \@zero_list, exact => 1 );
    is_deeply(\@got, [ ], "find_text_matches(empty, exact) returns correct results");

    @got = find_text_matches( $SEARCH_STR, \@long_list );
    is_deeply(\@got, [ @WORD_MATCHES ], "find_text_matches(long, not exact) returns correct results");

    @got = find_text_matches( $SEARCH_STR, \@long_list, exact => 1 );
    is_deeply(\@got, [ $SEARCH_STR ], "find_text_matches(long, exact) returns correct result");

    @got = find_text_matches( $SEARCH_STR, \@medium_list );
    is_deeply(\@got, [ @WORD_MATCHES ], "find_text_matches(medium, not exact) returns correct results");

    @got = find_text_matches( $SEARCH_STR, \@medium_list, exact => 1 );
    is_deeply(\@got, [ $SEARCH_STR ], "find_text_matches(medium, exact) returns correct result");

    @got = find_text_matches( $SEARCH_STR, \@short_list );
    is_deeply(\@got, [ @WORD_MATCHES ], "find_text_matches(short, not exact) returns correct results");

    @got = find_text_matches( $SEARCH_STR, \@short_list, exact => 1 );
    is_deeply(\@got, [ $SEARCH_STR ], "find_text_matches(short, exact) returns correct result");

    return;
}

sub check_is_find_obj_name_matches: Test(10) {
    my ($self) = @_;

    my @add_obj     = map { TestObj->new(name => $_) } (@WORD_MATCHES, 'fon');
    my @zero_list   = ();
    my @long_list   = sort { $a->name cmp $b->name } (@{$self->{obj_list}},        @add_obj);
    my @medium_list = sort { $a->name cmp $b->name } (@{$self->{obj_list}}[0..20], @add_obj);
    my @short_list  = sort { $a->name cmp $b->name } (@{$self->{obj_list}}[0..3],  @add_obj);

    my @got;

    @got = map { $_->name } find_obj_name_matches( $SEARCH_STR, undef );
    is_deeply(\@got, [ ], "find_text_matches(undef, not exact) returns correct results");

    @got = map { $_->name } find_obj_name_matches( $SEARCH_STR, undef, exact => 1 );
    is_deeply(\@got, [ ], "find_text_matches(undef, exact) returns correct results");

    @got = map { $_->name } find_obj_name_matches( $SEARCH_STR, \@zero_list );
    is_deeply(\@got, [ ], "find_text_matches(empty, not exact) returns correct results");

    @got = map { $_->name } find_obj_name_matches( $SEARCH_STR, \@zero_list, exact => 1 );
    is_deeply(\@got, [ ], "find_text_matches(empty, exact) returns correct results");

    @got = map { $_->name } find_obj_name_matches( $SEARCH_STR, \@long_list );
    is_deeply(\@got, [ @WORD_MATCHES ], "find_text_matches(long, not exact) returns correct results");

    @got = map { $_->name } find_obj_name_matches( $SEARCH_STR, \@long_list, exact => 1 );
    is_deeply(\@got, [ $SEARCH_STR ], "find_text_matches(long, exact) returns correct result");

    @got = map { $_->name } find_obj_name_matches( $SEARCH_STR, \@medium_list );
    is_deeply(\@got, [ @WORD_MATCHES ], "find_text_matches(medium, not exact) returns correct results");

    @got = map { $_->name } find_obj_name_matches( $SEARCH_STR, \@medium_list, exact => 1 );
    is_deeply(\@got, [ $SEARCH_STR ], "find_text_matches(medium, exact) returns correct result");

    @got = map { $_->name } find_obj_name_matches( $SEARCH_STR, \@short_list );
    is_deeply(\@got, [ @WORD_MATCHES ], "find_text_matches(short, not exact) returns correct results");

    @got = map { $_->name } find_obj_name_matches( $SEARCH_STR, \@short_list, exact => 1 );
    is_deeply(\@got, [ $SEARCH_STR ], "find_text_matches(short, exact) returns correct result");

    return;
}

}

Main();
