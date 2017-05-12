package # hide
Data_Test_Arguments;

use 5.008003;
use warnings;
use strict;


sub valid_values {
    return {
        beep         => [ 0, 1 ],
        clear_screen => [ 0, 1 ],
        hide_cursor  => [ 0, 1 ],
        index        => [ 0, 1 ],
        justify      => [ 0, 1, 2 ],
        layout       => [ 0, 1, 2, 3 ],
        mouse        => [ 0, 1, 2, 3, 4 ],
        order        => [ 0, 1 ],
        page         => [ 0, 1 ],

        # '[ 1-9 ][ 0-9 ]*'
        keep       => [ 1, 2, 100, 999999, undef ],
        ll         => [ 1, 2, 100, 999999, undef ],
        max_height => [ 1, 2, 100, 999999, undef ],
        max_width  => [ 1, 2, 100, 999999, undef ],

        # '[ 0-9 ]+'
        default     => [ 0, 1, 2, 100, 999999, undef ],
        pad         => [ 0, 1, 2, 100, 999999, undef ],
        pad_one_row => [ 0, 1, 2, 100, 999999, undef ],

        # ''
        empty  => [ 0, 'Hello' x 50, '', ' ', 'abc', 'world', undef ],
        prompt => [ 0, 'Hello' x 50, '', ' ', 'abc', 'world', undef ],
        undef  => [ 0, 'Hello' x 50, '', ' ', 'abc', 'world', undef ],

        # ARRAY max 2 int
        lf => [ [ 2, 4 ], [ 8 ], [], undef ],

        # ARRAY int
        mark        => [ [ 0, 1, 2, 100, 999999 ], [ 1 ], undef ],
        no_spacebar => [ [ 0, 1, 2, 100, 999999 ], [ 1 ], undef ],
    };
}

sub mixed_options_1 {
    return {
        beep  => 0, clear_screen => undef, hide_cursor => 1, index => 0, justify => 0, layout => 0, mouse => 0,
        order => 1, page => 0, keep => 1, ll => 1, max_height => 19, max_width => 19, default => 9, pad => 3,
        pad_one_row => 2, empty => '', prompt => '', undef => '', lf => [ 1 ], no_spacebar => [ 0 ], mark => [ 3, 4 ]
    };
}


sub mixed_options_2 {
    return {
        mark => [ 0 ], no_spacebar => [ 11, 0, 8 ], lf => [ 1, 1 ], undef => '', prompt => 'prompt_line', empty => '',
        pad_one_row => 2, pad => 3, default => 9, max_width => 19, max_height => 119, ll => 15, keep => 1, page => 1,
        order => 1, mouse => 0, layout => 3, justify => 0, index => 0, hide_cursor => 1, clear_screen => undef, beep => 0
    };
}

##################################################################################################

sub invalid_values {
    my @invalid = ( -1, 2, 2 .. 10, 999999, '01', '', 'a', { 1, 1 }, [ 1 ], [ 2 ] );
    return{
        beep         => [ grep { ! /^[ 0 1 ]\z/x }         @invalid ],
        clear_screen => [ grep { ! /^[ 0 1 ]\z/x }         @invalid ],
        hide_cursor  => [ grep { ! /^[ 0 1 ]\z/x }         @invalid ],
        index        => [ grep { ! /^[ 0 1 ]\z/x }         @invalid ],
        justify      => [ grep { ! /^[ 0 1 2 ]\z/x }       @invalid ],
        layout       => [ grep { ! /^[ 0 1 2 3 ]\z/x }     @invalid ],
        mouse        => [ grep { ! /^[ 0 1 2 3 4 ]\z/x }   @invalid ],
        order        => [ grep { ! /^[ 0 1 ]\z/x }         @invalid ],
        page         => [ grep { ! /^[ 0 1 ]\z/x }         @invalid ],
        keep         => [ grep { ! /^[ 1-9 ][ 0-9 ]*\z/x } @invalid ],
        ll           => [ grep { ! /^[ 1-9 ][ 0-9 ]*\z/x } @invalid ],
        max_height   => [ grep { ! /^[ 1-9 ][ 0-9 ]*\z/x } @invalid ],
        max_width    => [ grep { ! /^[ 1-9 ][ 0-9 ]*\z/x } @invalid ],
        default      => [ grep { ! /^[ 0-9 ]+\z/x }        @invalid ],
        pad          => [ grep { ! /^[ 0-9 ]+\z/x }        @invalid ],
        pad_one_row  => [ grep { ! /^[ 0-9 ]+\z/x }        @invalid ],

        # ''
        empty  => [ { 1, 1 }, [ 1 ], {}, [], [ 2 ] ],
        prompt => [ { 1, 1 }, [ 1 ], {}, [], [ 2 ] ],
        undef  => [ { 1, 1 }, [ 1 ], {}, [], [ 2 ] ],

        # ARRAY max 2 int
        lf => [ -2, -1, 0, 1, '', 'a', { 1, 1 }, {}, [ 1, 2, 3, ], [ 'a', 'b' ], [ -3, -4 ] ],

        # ARRAY int
        mark        => [ -2, -1, 0, 1, '', 'a', { 1, 1 }, {}, [ 'a', 'b' ], [ -3, -4 ] ],
        no_spacebar => [ -2, -1, 0, 1, '', 'a', { 1, 1 }, {}, [ 'a', 'b' ], [ -3, -4 ] ],
    };
}

sub mixed_invalid_1 {
    return {
        beep  => -1, clear_screen => 2, hide_cursor => 3, index => 4, justify => '@', layout => 5, mouse => {},
        order => 1, page => 0, keep => -1, ll => -1, max_height => 0, max_width => 0, default => [], pad => 'a',
        pad_one_row => 'b', empty => [], prompt => {}, undef => [], lf => 4, no_spacebar => 4, mark => 'o'
    };
}


sub mixed_invalid_2 {
    return {
        mark => '', no_spacebar => 'a', lf => 'b', undef => [], prompt => {}, empty => {}, pad_one_row => 'c',
        pad => 'd', default => 'e', max_width => -1, max_height => -2, ll => -4, keep => -5, page => -6, order => -7,
        mouse => 'k', layout => 'e', justify => [], index => {}, hide_cursor => -1,  clear_screen => [], beep  => 10
    };
}


1;

__END__
