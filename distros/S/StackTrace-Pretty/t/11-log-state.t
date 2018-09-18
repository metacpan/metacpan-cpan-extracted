use strict;
use warnings;
use utf8;
use lib qw(lib .);

use Test::More;
use t::Util;

BEGIN {
    use_ok 'StackTrace::Pretty::LogState';
}

subtest 'not in stack trace' => sub {
    subtest 'Previous is in stack trace' => sub {
        my $ls = StackTrace::Pretty::LogState->new();

        $ls->{_is_in_stack_trace} = 0;

        $ls->read('Normal Text');
        is $ls->is_in_stack_trace, 0, 'is_in_stack_trace';
    };

    subtest 'Previous is in another stack trace' => sub {
        my $ls = StackTrace::Pretty::LogState->new();

        $ls->{_is_in_stack_trace} = 1;

        $ls->read('Normal Text');
        is $ls->is_in_stack_trace, 0, 'is_in_stack_trace';
    };
};

subtest 'Start a stack trace' => sub {
    subtest 'Previous is not in stack trace' => sub {
        my $ls = StackTrace::Pretty::LogState->new();

        $ls->{_is_in_stack_trace} = 0;

        $ls->read(first_line_st());
        is $ls->is_in_stack_trace, 1, 'is_in_stack_trace';
    };

    subtest 'Previous is in another stack trace' => sub {
        my $ls = StackTrace::Pretty::LogState->new();

        $ls->{_is_in_stack_trace} = 1;

        $ls->read(first_line_st());
        is $ls->is_in_stack_trace, 1, 'is_in_stack_trace';
    };
};

subtest 'Child stack trace' => sub {
    subtest 'Previous is not in stack trace (abnormal case)' => sub {
        my $ls = StackTrace::Pretty::LogState->new();

        $ls->{_is_in_stack_trace} = 0;

        $ls->read(child_line_st());

        # If previous line is not in stack trace,
        # this line shouldn't be considered as child line of stack trace.
        is $ls->is_in_stack_trace, 1, 'is_in_stack_trace';
    };

    subtest 'Previous is in another stack trace' => sub {
        my $ls = StackTrace::Pretty::LogState->new();

        $ls->{_is_in_stack_trace} = 1;

        $ls->read(child_line_st());
        is $ls->is_in_stack_trace, 1, 'is_in_stack_trace';
    };
};

subtest 'line_num' => sub {
    my $ls = StackTrace::Pretty::LogState->new();

    $ls->read('Normal Line');

    $ls->read(first_line_st());
    is $ls->line_num, 0, 'line_num is 0 at first line of stack trace';

    for (1..3) {
        $ls->read(child_line_st());
    }
    is $ls->line_num, 3, 'line_num increases';

    $ls->read(first_line_st());
    is $ls->line_num, 0, 'line_num is reset';
};

done_testing;
