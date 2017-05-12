#!/usr/bin/perl6
use v6;

# ASCII

say ord('a');       # 97
say ord('bab');     # 98    (that of the first letter)
say chr(97);        # a

printf("%c\n", 97); # a
printf("%d %c\n", 97, 97); # 97 a

# TODO pack("C*", ) unpack() Unicode: U

ord('a').say;       # 97

# TODO: in perl 5 this was:
# printf("%vd\n", "ab0\x{0123}"); # 97.98.48.291
# printf("%vx\n", "ab0\x{0123}"); # 61.62.30.123
