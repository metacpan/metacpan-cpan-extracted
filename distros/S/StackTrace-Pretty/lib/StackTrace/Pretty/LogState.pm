package StackTrace::Pretty::LogState;
use strict;
use warnings;
use utf8;

my $FIRST_LINE_ST_PATTERN = qr/^\S.* at \S+ line \d+\.?$/;
my $CHILD_LINE_ST_PATTERN = qr/\S+ called at \S+ line \d+\.?$/;

sub new {
    my ($class) = @_;

    return bless {
        _is_in_stack_trace => 0,
        _line_num => 0,
    }, $class;
}

sub read {
    my ($self, $line) = @_;

    if ($line =~ $FIRST_LINE_ST_PATTERN) {
        $self->{_is_in_stack_trace} = 1;
        $self->{_line_num} = 0; # Reset
    }
    elsif ($line =~ $CHILD_LINE_ST_PATTERN) {
        $self->{_is_in_stack_trace} = 1;    #  Unchanged
        $self->{_line_num}++;
    }
    else {  # Normal line
        $self->{_is_in_stack_trace} = 0;
        $self->{_line_num} = 0;
    }

}

sub is_in_stack_trace {
    my ($self) = @_;

    return $self->{_is_in_stack_trace};
}

sub line_num {
    my ($self) = @_;

    return $self->{_line_num};
}

1;
