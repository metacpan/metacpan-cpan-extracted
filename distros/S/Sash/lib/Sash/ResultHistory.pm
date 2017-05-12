package Sash::ResultHistory;
use strict;
use warnings;

use Carp;

# The Highlander Pattern

my @_result_history;
my @_redo_stack;

sub add {
    my $class = shift;
    my $result = shift;

    croak "result not of type Sash::Table" unless ref $result eq 'Sash::Table';

    unshift @_result_history, $result;

    return;
}

# For many of the methods below notice we return the current Sash::Table
# object as a convenience to the caller.  It is good form in that it
# indicates the requested operation was successful and also allows the
# caller to chain commands together which they might want to do.

sub undo {
    my $class = shift;

    unshift @_redo_stack, shift @_result_history;
    
    return $class->current;
}

sub current {
    my $class = shift;

    return $_result_history[0];
}

sub redo {
    my $class = shift;

    unshift @_result_history, shift @_redo_stack;

    return $class->current;
}

sub revert {
    my $class = shift;

    @_result_history = $_result_history[ scalar( @_result_history ) - 1 ];

    return $class->current;
}

sub all {
    my $class = shift;

    return @_result_history;
}

sub size {
    my $class = shift;

    return scalar @_result_history;
}

1;
