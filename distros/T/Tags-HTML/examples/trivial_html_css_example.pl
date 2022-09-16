#!/usr/bin/env perl

use strict;
use warnings;

package Foo;

use base qw(Tags::HTML);

sub _process {
        my ($self, $value) = @_;

        $self->{'tags'}->put(
                ['b', 'div'],
                ['d', $value],
                ['e', 'div'],
        );

        return;
}

sub _process_css {
        my ($self, $color) = @_;

        $self->{'css'}->put(
                ['s', 'div'],
                ['d', 'background-color', $color],
                ['e'],
        );

        return;
}

package main;

use CSS::Struct::Output::Indent;
use Tags::Output::Indent;

# Object.
my $css = CSS::Struct::Output::Indent->new;
my $tags = Tags::Output::Indent->new;
my $obj = Foo->new(
        'css' => $css,
        'tags' => $tags,
);

# Process indicator.
$obj->process_css('red');
$obj->process('value');

# Print out.
print "CSS\n";
print $css->flush."\n\n";
print "HTML\n";
print $tags->flush."\n";

# Output:
# CSS
# div {
# 	background-color: red;
# }
#
# HTML
# <div>
#   value
# </div>