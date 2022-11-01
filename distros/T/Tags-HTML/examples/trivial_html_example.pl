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

sub _cleanup {
        my $self = shift;

        delete $self->{'_data'};

        return;
}

sub _init {
        my ($self, @variables) = @_;

        $self->{'_data'} = \@variables;

        return;
}

sub _process {
        my $self = shift;

        $self->{'tags'}->put(
                ['b', 'div'],
        );
        foreach my $variable (@{$self->{'_data'}}) {
                $self->{'tags'}->put(
                        ['b', 'div'],
                        ['d', $variable],
                        ['e', 'div'],
                );
        }
        $self->{'tags'}->put(
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

# Init data.
$obj->init('foo', 'bar', 'baz');

# Process.
$obj->process;

# Print out.
print "HTML\n";
print $tags->flush."\n";

# Output:
# HTML
# <div>
#   <div>
#     foo
#   </div>
#   <div>
#     bar
#   </div>
#   <div>
#     baz
#   </div>
# </div>