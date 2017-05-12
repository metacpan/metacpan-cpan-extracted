#!perl

use Test::More;
use Test::Exception;
use strict;
use warnings FATAL => 'all';
BEGIN { use_ok 'Number::RGB' }

{ # Test ->new
    is+Number::RGB->new(rgb_number => 255) . '', '255,255,255', '->new(255)';
    is+Number::RGB->new(rgb_number => 0)   . '', '0,0,0',       '->new(0)';
    is+Number::RGB->new(rgb => [0,6,7])    . '', '0,6,7',       '->new(0,6,7)';
    is+Number::RGB->new(hex => '#fff423') . '', '255,244,35', '->new(#fff423)';
    is+Number::RGB->new(hex => 'fff423')  . '', '255,244,35', '->new(fff423)';
    is+Number::RGB->new(hex => '#423')     . '',  '68,34,51',   '->new(#423)';
    is+Number::RGB->new(hex => '423')      . '',  '68,34,51',   '->new(423)';
    is+Number::RGB->new(hex => '333')      . '',  '51,51,51',   '->new(333)';

    throws_ok { Number::RGB->new('333') }
        qr/Odd number of parameters.*01_functionality\.t/s,
            q{dies on ->new('333')};

    throws_ok { Number::RGB->new() }
        qr/\Qnew() requires parameters\E/,
            q{dies on ->new()};
}

{ # Test attribute [and by extension ->new_from_guess]
    my $v1  :RGB(255);     is $v1,  '255,255,255', ':RGB(255)';
    my $v2  :RGB(0);       is $v2,  '0,0,0',       ':RGB(0)';
    my $v3  :RGB(0,6,7);   is $v3,  '0,6,7',       ':RGB(0,6,7)';
    my $v4  :RGB(#fff423); is $v4,  '255,244,35',  ':RGB(#fff423)';
    my $v5  :RGB(fff423);  is $v5,  '255,244,35',  ':RGB(fff423)';
    my $v6  :RGB(#423);    is $v6,  '68,34,51',    ':RGB(#423)';
    my $v7  :RGB(423);     is $v7,  '68,34,51',    ':RGB(423)';
    my $v8  :RGB(333);     is $v8,  '51,51,51',    ':RGB(333)';

    my $re = qr/couldn't guess.*01_functionality\.t/;
    throws_ok { my $v :RGB(#42)         } $re, 'dies on RGB(#42)';
    throws_ok { my $v :RGB(5555)        } $re, 'dies on RGB(5555)';
    throws_ok { my $v :RGB(555,555,555) } $re, 'dies on RGB(555,555,555)';
}

{   # Test methods
    my $c :RGB(17,34,172);
    isa_ok $c, 'Number::RGB';
    can_ok $c, qw/r  g  b  rgb  hex  hex_uc  as_string  new  new_from_guess/;

    is $c->r,          17,            '->r';
    is $c->g,          34,            '->g';
    is $c->b,          172,           '->b';
    is_deeply $c->rgb, [17, 34, 172], '->rgb';
    is $c->hex,        '#1122ac',     '->hex';
    is $c->hex_uc,     '#1122AC',     '->hex_uc';
    is $c->as_string,  '17,34,172',   '->as_string';
}

{ # Test overloads and math
    my $black :RGB(0);
    my $white :RGB(255);
    my $gray  :RGB(128);
    my $blue  :RGB(00f);
    my $green :RGB(0f0);
    my $red   :RGB(f00);
    my $tiber :RGB(17,34,51);
    my $c     :RGB(1,2,3);

    # Overflow:
    is $white * 2, '255,255,255', '$white * 2';
    is $black - $white, '0,0,0', '$black - $white';

    # Rounding
    is $white / 2, '128,128,128', '$white / 2';

    # Stringification
    is "$white",  '255,255,255', '"$white"';

    # Math
    is $black +  $gray,  '128,128,128', '$black + $gray';
    is $tiber +  22,     '39,56,73',    '$tiber + 22';
    is $white -  $gray,  '127,127,127', '$white - $gray';
    is $tiber -  22,     '0,12,29',     '$tiber - 22';
    is 22     -  $tiber, '5,0,0',       '22 - $tiber';
    is $red   *  $tiber, '255,0,0',     '$red * $tiber';
    is $tiber *  2,      '34,68,102',   '$tiber * 2';
    is $white /  $tiber, '15,8,5',      '$white / $tiber';
    is $tiber /  2,      '8,17,26',     '$tiber / 2';
    is $c     << $c,     '2,8,24',      '$c << $c';
    is $c     << 2,      '4,8,12',      '$c << 2';
    is $white >> $c,     '127,63,31',   '$white >> $c';
    is $white >> 2,      '63,63,63',    '$white >> 2';
    is $white &  $red,   '255,0,0',     '$white & $red';
    is $green &  1,      '0,1,0',       '$green & 1';
    is $green ^  $red,   '255,255,0',   '$green ^ $red';
    is $green ^  1,      '1,254,1',     '$green ^ 1';
    is $green |  $red,   '255,255,0',   '$green | $red';
    is $green |  1,      '1,255,1',     '$green | 1';
}

{ # Regression check against https://github.com/zoffixznet/Number-RGB/issues/1
    #... the test doesn't always detect the issue, but "detects sometimes"
    #... is better than nothing. If the issue returns, someone will eventually
    #... get a failing test
    lives_ok {
        for ( 1..3 ) {
            for ( 0..255 ) {
                my $c = Number::RGB->new_from_guess($_);
                die "->new_from_guess($_) was incorrectly interpreted as $c"
                    unless $c eq "$_,$_,$_";
            }
        }
    } 'guess from single 0..255 seems to work';
}

done_testing;