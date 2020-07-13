#!/usr/bin/perl
use strictures 2;
use lib '../lib', 'lib';
use Termbox qw[:all];
use experimental 'signatures';
use Data::Dump;
#
my $chars     = "nnnnnnnnnbbbbbbbbbuuuuuuuuuBBBBBBBBB";
my $all_attrs = [ 0, TB_BOLD, TB_UNDERLINE, TB_BOLD | TB_UNDERLINE, ];

sub next_char($current) {
    $current = 0 if ++$current > length $chars;
    $current;
}

sub draw_line ( $x, $y, $bg ) {
    my ( $a, $c );
    my $current_char = 0;
    for my $a ( 0 .. 3 ) {
        for my $c ( TB_DEFAULT .. TB_WHITE ) {
            my $fg = $all_attrs->[$a] | $c;
            tb_change_cell( $x, $y, substr( $chars, $current_char, 1 ), $fg, $bg );
            $current_char = next_char($current_char);
            $x++;
        }
    }
}

sub print_combinations_table ( $sx, $sy, $attrs, $attrs_n ) {
    for my $i ( 0 .. $attrs_n - 1 ) {
        for my $c ( TB_DEFAULT .. TB_WHITE ) {

            #warn $c;
            my $bg = $attrs->[$i] | $c;
            draw_line( $sx, $sy, $bg );
            $sy++;
        }
    }
}

sub draw_all() {
    tb_clear();
    tb_select_output_mode(TB_OUTPUT_NORMAL);
    my $col1 = [ 0, TB_BOLD ];
    my $col2 = [TB_REVERSE];
    print_combinations_table( 1,                  1, $col1, 2 );
    print_combinations_table( 2 + length($chars), 1, $col2, 1 );
    tb_present();
    tb_select_output_mode(TB_OUTPUT_GRAYSCALE);
    my ( $c, $x, $y );

    for ( $x = 0, $y = 23; $x < 24; ++$x ) {
        tb_change_cell( $x,      $y, '@', $x, 0 );
        tb_change_cell( $x + 25, $y, ' ', 0,  $x );
    }
    tb_present();
    tb_select_output_mode(TB_OUTPUT_216);
    $y++;
    for ( $c = 0, $x = 0; $c < 216; ++$c, ++$x ) {
        if ( !( $x % 24 ) ) {
            $x = 0;
            ++$y;
        }
        tb_change_cell( $x,      $y, '@', $c, 0 );
        tb_change_cell( $x + 25, $y, ' ', 0,  $c );
    }
    tb_present();
    tb_select_output_mode(TB_OUTPUT_256);
    $y++;
    for ( $c = 0, $x = 0; $c < 256; ++$c, ++$x ) {
        if ( !( $x % 24 ) ) {
            $x = 0;
            ++$y;
        }
        tb_change_cell( $x,      $y, '+', $c | ( ( $y & 1 ) ? TB_UNDERLINE : 0 ), 0 );
        tb_change_cell( $x + 25, $y, ' ', 0,                                      $c );
    }
    tb_present();
}
my $ret = tb_init();

#ddx $ret;
if ($ret) {
    die sprintf "tb_init() failed with error code %d\n", $ret;
}
draw_all();
my $ev = Termbox::Event->new();
LOOP: while ( tb_poll_event($ev) ) {

    # ddx $ev;
    if ( $ev->type == TB_EVENT_KEY ) {
        if ( $ev->key == TB_KEY_ESC ) {
            last LOOP;
        }
    }
    elsif ( $ev->type == TB_EVENT_RESIZE ) {
        draw_all();
    }
}
tb_shutdown();
