#!/usr/bin/perl

use strict;
use warnings;
use 5.010;

package Pod::Cats::Test {
    use Test::More 'no_plan';
    use parent qw(Pod::Cats);

    my @expected = (
        ['paragraph', "This is normal text 1."],
        ['verbatim', "This is verbatim."],
        ['paragraph', "This is normal text 2."],
        ['verbatim', 'This is the first line.
  This is indented 2 spaces.'],
        ['paragraph', "This is normal text 3."],
        ['verbatim', 'This is one line.

This is a second line.'],
        ['paragraph', "This is normal text 4."],
        ['verbatim', 'This is one line.

This is a second line.

  This is indented.'],
        ['paragraph', ""],
        ['verbatim', 'This is a new paragraph.

This is not.'],
        ['paragraph', "This is normal text 5."],
    );

    sub handle_paragraph {
        my $self = shift;
        my $para = $self->SUPER::handle_paragraph(@_);

        my $expected = shift @expected;

        is($expected->[0], 'paragraph');
        is($para, $expected->[1]);
    }

    sub handle_verbatim {
        my $self = shift;
        my $para = $self->SUPER::handle_verbatim(@_);

        my $expected = shift @expected;

        is($expected->[0], 'verbatim');
        is($para, $expected->[1]);
    }
}

my $pc = Pod::Cats::Test->new();
chomp(my @lines = <DATA>);
$pc->parse_lines(@lines);

__DATA__

This is normal text 1.

  This is verbatim.

This is normal text 2.

  This is the first line.
    This is indented 2 spaces.

This is normal text 3.

  This is one line.

  This is a second line.

This is normal text 4.

  This is one line.

  This is a second line.

    This is indented.

Z<>

  This is a new paragraph.

  This is not.

This is normal text 5.
