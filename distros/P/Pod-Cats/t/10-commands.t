#!/usr/bin/perl

use strict;
use warnings;

my $pc = Pod::Cats::Test->new();
chomp(my @lines = <DATA>);
$pc->parse_lines(@lines);

package Pod::Cats::Test;

use Data::Dump;
use Test::More 'no_plan';

use parent 'Pod::Cats';

my @expected_order = qw(
    command
    begin
    paragraph
    paragraph
    end
);

sub handle_begin {
    my $self = shift;

    fail('this is not +intro!') and return unless shift eq 'intro';

    pass('+intro dispatched to handle_begin');
    is(shift, 'Since there is no blank line, this is part of the begin command.',
        'Content of intro begin is OK');
}

sub handle_end {
    my $self = shift;

    fail('this is not -intro!') and return unless shift eq 'intro';

    pass('-intro dispatched to handle_end');
}

sub handle_paragraph {
    my $self = shift;

    pass('handed to handle_paragraph');

    $self->{i} //= 0;
    if ($self->{i} == 0) {
        is(shift,
'This is a basic paragraph in the "intro" paragraph. This line wraps at 80 characters but should be processed as a single line.',
        'Got first paragraph');
        $self->{i}++;
    }
    elsif ($self->{i} == 1) {
        is(shift, 'This is a second paragraph. The blank line is what determines that.',
        'Got second paragraph');
    }
    return join ' ', @_;
}

sub handle_command {
    my $self = shift;

    unless(shift eq 'head1')
    {
        diag dd \@_;
        fail('this is not =head1!');
        return
    }

    pass('head1 dispatched to handle_command');
    is(shift, 'TEST POD::CATS',
        'Content of head1 is OK');
}

1;

package main;

__DATA__
=head1 TEST POD::CATS

+intro
Since there is no blank line, this is part of the begin command.

This is a basic paragraph in the "intro" paragraph. This line wraps at 80
characters but should be processed as a single line.

This is a second paragraph. The blank line is what determines that.

-intro
