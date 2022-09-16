#!/usr/bin/env perl

use strict;
use warnings;

package Foo;

use base qw(Tags::HTML);

sub new {
        my ($class, @params) = @_;

        # No CSS support.
        push @params, 'no_css', 1;

        my $self = $class->SUPER::new(@params);

        # Object.
        return $self;
}

sub _process {
        my ($self, $value) = @_;

        $self->{'tags'}->put(
                ['b', 'div'],
                ['d', $value],
                ['e', 'div'],
        );

        return;
}

package main;

use Tags::Output::Indent;

# Object.
my $tags = Tags::Output::Indent->new;
my $obj = Foo->new(
        'tags' => $tags,
);

# Process indicator.
$obj->process('value');

# Print out.
print "HTML\n";
print $tags->flush."\n";

# Output:
# HTML
# <div>
#   value
# </div>