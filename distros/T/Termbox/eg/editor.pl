#!/usr/bin/perl
use strictures 2;
use lib '../lib';
{
    use Termbox qw[:all];
    #
    my @chars = split //, 'hello, world!';
    my $code  = tb_init();
    my %theme = (            # solarized
        base03  => 0x002b36,
        base02  => 0x073642,
        base01  => 0x586e75,
        base00  => 0x657b83,
        base0   => 0x839496,
        base1   => 0x93a1a1,
        base2   => 0xeee8d5,
        base3   => 0xfdf6e3,
        yellow  => 0xb58900,
        orange  => 0xcb4b16,
        red     => 0xdc322f,
        magenta => 0xd33682,
        violet  => 0x6c71c4,
        blue    => 0x268bd2,
        cyan    => 0x2aa198,
        green   => 0x859900
    );
    tb_set_input_mode( TB_INPUT_ESC | TB_INPUT_ALT | TB_INPUT_MOUSE );
    tb_set_output_mode(TB_OUTPUT_TRUECOLOR);
    tb_set_clear_attrs( $theme{base0}, $theme{base03} );
    my $spos   = 3;    # scroll position
    my $status = '';

    sub draw {
        tb_clear();

        # title
        tb_print( 0, 0, $theme{base02}, $theme{base1}, ' ' x tb_width() );
        tb_print( 0, 0, $theme{base02} | TB_TRUECOLOR_BOLD, $theme{base1},
            " 🦪 $0 - [New File]" );
        for my $line ( 1 .. tb_height() - 2 ) {
            tb_print( 0, $line, $theme{base0}, $theme{base02}, sprintf ' %3d ', $line );

            # scrollbar
            tb_print( tb_width() - 1,
                $line, $theme{base0}, $theme{base02}, $line == $spos ? '◧' : '┃' );
        }

        # status bar
        tb_print( 0,  tb_height() - 1, $theme{blue},    $theme{base02}, ' ' x tb_width() );
        tb_print( 0,  tb_height() - 1, $theme{blue},    $theme{base02}, 'Press Ctrl-Q to quit' );
        tb_print( 22, tb_height() - 1, $theme{magenta}, $theme{base02}, $status );
        #
        tb_present();
    }
    draw;
    my $ev = Termbox::Event->new();
    my $y  = 10;
    while ( !tb_poll_event($ev) ) {
        $status = sprintf 'event: type=%d mod=%d key=%d ch=%d w=%d h=%d x=%d y=%d', $ev->type,
            $ev->mod, $ev->key, $ev->ch, $ev->w, $ev->h, $ev->x, $ev->y;
        last    if $ev->key == 17                      && $ev->mod eq 2;
        $spos-- if $ev->key == TB_KEY_MOUSE_WHEEL_UP   && $spos > 1;
        $spos++ if $ev->key == TB_KEY_MOUSE_WHEEL_DOWN && $spos < tb_height() - 2;
        draw;
    }
    tb_shutdown();
}
