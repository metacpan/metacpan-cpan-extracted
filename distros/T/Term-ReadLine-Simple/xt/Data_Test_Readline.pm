package # hide
Data_Test_Readline;

use 5.008003;
use warnings;
use strict;


sub key_seq {
    return {
        CONTROL_M => "\x{0d}",
        ENTER     => "\x{0d}",

        RIGHT     => "\e[C",
        RIGHT_O   => "\eOC",
        CONTROL_F => "\x{06}",

        LEFT      => "\e[D",
        LEFT_O    => "\eOD",
        CONTROL_B => "\x{02}",

        CONTROL_A => "\x{01}",
        HOME      => "\e[H",

        CONTROL_E => "\x{05}",
        END       => "\e[F",

        CONTROL_H => "\x{08}",
        BTAB      => "\x{08}",
        BSPACE    => "\x{7f}",
        BTAB_Z    => "\e[Z",
        BTAB_OZ   => "\eOZ",

        CONTROL_D => "\x{04}",
        DELETE    => "\e[3~",

        CONTROL_K => "\x{0b}",
        CONTROL_U => "\x{15}",
    };
}

sub return_test_data {
    return [
        {
            used_keys => [ "-", 'ENTER' ],
            expected  => "<->",
            arguments => [ 'Prompt: ' ],
        },
        {
            used_keys => [ 'ENTER' ],
            expected  => "<default>",
            arguments => [ 'Prompt: ', "default" ],
        },
        {
            used_keys => [ ( 'LEFT' ) x 4, 'CONTROL_K', " ", 'ENTER' ],
            expected  => "<def >",
            arguments => [ 'Prompt: ', 'default' ],
        },
        {
            used_keys => [ ( 'LEFT' ) x 5, "-", 'ENTER' ],
            expected  => "<de-fault>",
            arguments => [ 'Prompt: ', "default" ],
        },
        {
            used_keys => [ ( 'BSPACE' ) x 7, "hello", " ", "world", 'ENTER' ],
            expected  => "<hello world>",
            arguments => [ 'Prompt: ', { default => "default" } ],
        },
        {
            used_keys => [ "house", 'ENTER' ],
            expected  => "<The house>",
            arguments => [ 'Prompt: ', { default => "The ", no_echo => 1 } ],
        },
        {
            used_keys => [ "0123456789", ( 'LEFT' ) x 5, 'CONTROL_U', 'ENTER' ],
            expected  => "<56789>",
            arguments => [ ': ' ],
        },
        {
             used_keys => [ 'CONTROL_U', "a", 'ENTER'],
             expected  => "<a>",
             arguments => [ 'Prompt: ', { default => "many words " x 1000, no_echo => 0 } ],
        },
        {
            used_keys => [ "abcde ", "XY " x 10, ( 'LEFT' ) x 36, ( 'RIGHT' ) x 8, 'CONTROL_K', 'ENTER' ],
            expected  => "<DEFAULT abcde XY>",
            arguments => [ "Prompt: ", { default => "DEFAULT " } ],
        },
        {
            used_keys => [ "The black cat climbed the green tree", 'HOME', ( 'RIGHT' ) x 4, ( 'DELETE' ) x 6, 'END', ( 'LEFT' ) x 5, ( 'BSPACE' ) x 6, 'ENTER' ],
            expected  => "<The cat climbed the tree>",
            arguments => [ 'Prompt: ' ],
        },
        {
            used_keys => [ qw( HOME RIGHT RIGHT_O DELETE CONTROL_D END LEFT LEFT_O BSPACE CONTROL_H CONTROL_A DELETE CONTROL_E BSPACE _ABC ENTER ) ],
            expected  => "<hblack cat climbed the green e_ABC>",
            arguments => [ 'Prompt: ', { default => "The black cat climbed the green tree" } ],
        },
    ];
}




1;

__END__
