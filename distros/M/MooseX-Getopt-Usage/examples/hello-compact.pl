#!/usr/bin/env perl
package Hello;
use 5.010;
use Moose;

with 'MooseX::Getopt::Usage';

has verbose => ( is => 'ro', isa => 'Bool',
    documentation => qq{Say lots about what we do} );

has greet => ( is => 'ro', isa => 'Str', default => "World",
    documentation => qq{Who to say hello to.} );

has times => ( is => 'rw', isa => 'Int', required => 1,
    documentation => qq{How many times to say hello} );

sub getopt_usage_config {
    return ( 
        attr_sort => sub { $_[0]->name cmp $_[1]->name },
        format => "Usage: %c [OPTIONS]",
        headings => 0,
    );
}

sub run {
    my $self = shift;
    say "Printing message..." if $self->verbose;
    say "Hello " . $self->greet for (1..$self->times);
}

package main;
Hello->new_with_options->run;
