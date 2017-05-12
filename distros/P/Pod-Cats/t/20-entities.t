#!/usr/bin/perl

use strict;
use warnings;

my $pc = Pod::Cats::Test->new();
chomp(my @lines = <DATA>);
$pc->parse_lines(@lines);

package Pod::Cats::Test;

use Test::More 'no_plan';

use parent 'Pod::Cats';

sub handle_entity {
    my $self = shift;

    my $entity = shift;
    my @content = @_;

    if ( $entity eq 'I' ) {
        is($content[0], 'simple', 'I entity contains "simple"');
        is(@content, 1, 'I entity contains 1 piece of content');
    }
    elsif ($entity eq 'C') {
        is($content[0], undef, 'C entity has undef content because Z<> is always empty.');
        is(@content, 1, 'C entity contains 1 piece of content (which was undef)');
    }
    elsif ($entity eq 'A') {
        is($content[0], 'nested ', 'A entity contains none of B in its first piece of content');
        is($content[1], 'B-entities-', 'A entity contains parsed result of B entity');
        is(@content, 2, 'A entity has 2 pieces of content');
    }
    elsif ($entity eq 'B') {
        is($content[0], 'entities', 'B entity discovered');
        is(@content, 1, 'B entity contains 1 piece of content');
        return 'B-'.$content[0].'-';
    }
    elsif ($entity eq 'D') {
        is($content[0], 'double ', 'D entity discovered');
        is($content[1], 'E-delimiters-', 'E entity parsed inside it');
        is(@content, 2, 'D entity has 2 pieces of content');
    }
    elsif ($entity eq 'E') {
        is($content[0], 'delimiters', 'E entity discovered');
        is(@content, 1, 'E entity has 1 piece of content');
        return 'E-'.$content[0].'-';
    }
    elsif ($entity eq 'X') {
        is($content[0], 'one Y<entity> ', 'X entity has escaped Y entity');
        is(@content, 1, 'X entity contains 1 piece of content');
    }
    elsif ($entity eq 'Y') {
        fail('Y entity should not be parsed');
    }
    elsif ($entity eq 'Z') {
        fail('Z entity should not be passed off for user handling');
    }
    else {
        fail('this is not I<>!') and return unless shift eq 'I';
    }

    return $self->SUPER::handle_entity($entity, @content);
}

1;

package main;

__DATA__
This paragraph contains a I<simple> entity.

This paragraph explains how C<Z<>> works.

This paragraph contains Z<>

This paragraph contains A<nested B<entities>>

This paragraph only parses X<<one Y<entity> >>

This paragraph uses D<<double E<<delimiters>> >>
