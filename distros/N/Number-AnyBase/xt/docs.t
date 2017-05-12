#!perl

use Test::More;

### SYNOPSYS ###

use strict;
use warnings;

use Number::AnyBase;

# 62 symbols alphabet
my @alphabet = (0..9, 'A'..'Z', 'a'..'z');
my $conv = Number::AnyBase->new( @alphabet );
my $base62_num = $conv->to_base( 123456 );     # W7E
my $dec_num    = $conv->to_dec( $base62_num ); # back to 123456

use feature 'say';

# URI unreserved characters alphabet
my $uri_conv = Number::AnyBase->new_urisafe;
say $uri_conv->to_base( 1234567890 ); # ~2Bn4
say $uri_conv->to_dec( '~2Bn4' );     # 1234567890

# ASCII printable characters alphabet
my $ascii_conv = Number::AnyBase->new_ascii;
say $ascii_conv->to_base( 199_000_000_000 ); # >Z8X<8
say $ascii_conv->to_dec( '>Z8X<8' );         # 199000000000

# Hexadecimal base
my $hex_conv = Number::AnyBase->new( 0..9, 'A'..'F' );
say $hex_conv->to_base( 2047 ); # 7FF
say $hex_conv->to_dec( '7FF' ); # 2047

# Morse alphabet
my $morse_conv = Number::AnyBase->new( '._' );
say $morse_conv->to_base( 99 );       # __...__
say $morse_conv->to_dec( '__...__' ); # 99

{
    # Unicode alphabet (webdings font);
    use utf8;
    binmode STDOUT, ':utf8';
    my $webdings_conv = Number::AnyBase->new(
        '♣♤♥♦☭☹☺☻✈✪✫✭✰✵✶✻❖♩♧♪♫♬⚓⚒⛔✼✾❁❂❄❅❊☿⚡⚢⚣⚤⚥⚦⛀⛁⛦⛨'
    );
    say $webdings_conv->to_base( 1000000000 ); # ☺⚢♬♬⚥⛦
    say $webdings_conv->to_dec( '☺⚢♬♬⚥⛦' );   # 1000000000
}

# Fast native unary increment/decrement
my $sequence = Number::AnyBase->fastnew(['A'..'Z']);
say $sequence->next('ZZZ');  # BAAA
say $sequence->prev('BAAA'); # ZZZ

{
    use constant SEQ_LENGTH => 10_000;
    
    my $conv = Number::AnyBase->new( 0..9, 'A'..'Z', 'a'..'z' );
    my (@seq1, @seq2);
    my $base_num = 'zzzzzz';
    
    my $next = $base_num;
    push @seq1, $next = $conv->next($next) for 1..SEQ_LENGTH;
    
    # @seq2 construction is marginally faster:
    my $dec_num = $conv->to_dec($base_num);
    push @seq2, $conv->to_base( $dec_num + $_ ) for 1..SEQ_LENGTH;
    
    is_deeply \@seq1, \@seq2,
        'Native increment vs to_base() on large sequences';
}

ok( 1 == 1, 'Docs OK' );
done_testing;
