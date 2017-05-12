use StackTrace::HiPerf;
use strict;
use Test::More tests => 4;
use warnings;

{
    my $trace = StackTrace::HiPerf::trace();
    is( $trace, '', 'no trace' );
}

{
    my $trace;
    my $sub = sub {
        $trace = StackTrace::HiPerf::trace();
    };
    $sub->();
    is( $trace, '16|t/basic.t||', 'small trace' );
}

sub large_trace {
    my ( $caller_line_num, $test_msg, $start_level, ) = @_;
    $start_level = 0 unless defined $start_level;

    no warnings 'recursion';

    my $trace;
    my $max_level = 100;
    my $cur_level = 1;
    my $sub_foo;
    my $sub_bar;

    $sub_foo = sub {
         $sub_foo->() &&  return 1 if $cur_level++ <= $max_level;
        eval {
            $sub_bar->();
        };
    };

    $sub_bar = sub {
        $trace = StackTrace::HiPerf::trace( $start_level );
    };
    $sub_foo->();

    my $trace_expected;
    $trace_expected .= '35|t/basic.t||34|t/basic.t||' unless $start_level;

    my $middle_count = $max_level;
    $middle_count -= ( $start_level - 2 ) if $start_level;
    $trace_expected .= '33|t/basic.t||' for 1 .. $middle_count;

    $trace_expected .= '42|t/basic.t||';
    $trace_expected .= "$caller_line_num|t/basic.t||";

    is( $trace, $trace_expected, $test_msg );
}

large_trace( 57, 'large trace' );

large_trace( 59, 'large trace start at 50', 50 );
