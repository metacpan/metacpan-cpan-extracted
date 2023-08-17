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

        delete $self->{'_dynamic_data'};
        delete $self->{'_static_data'};

        return;
}

sub _init {
        my ($self, @variables) = @_;

        $self->{'_dynamic_data'} = \@variables;

        return;
}

sub _prepare {
        my ($self, @variables) = @_;

        $self->{'_static_data'} = \@variables;

        return;
}

sub _process {
        my $self = shift;

        $self->{'tags'}->put(
                ['b', 'div'],
        );
        foreach my $variable (@{$self->{'_static_data'}}) {
                $self->{'tags'}->put(
                        ['b', 'div'],
                        ['a', 'class', 'static'],
                        ['d', $variable],
                        ['e', 'div'],
                );
        }
        foreach my $variable (@{$self->{'_dynamic_data'}}) {
                $self->{'tags'}->put(
                        ['b', 'div'],
                        ['a', 'class', 'dynamic'],
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

# Init static data.
$obj->prepare('foo', 'bar');

# Init dynamic data.
$obj->init('baz', 'bax');

# Process.
$obj->process;

# Print out.
print "HTML\n";
print $tags->flush."\n";

# Output:
# HTML
# <div>
#   <div class="static">
#     foo
#   </div>
#   <div class="static">
#     bar
#   </div>
#   <div class="dynamic">
#     baz
#   </div>
#   <div class="dynamic">
#     bax
#   </div>
# </div>