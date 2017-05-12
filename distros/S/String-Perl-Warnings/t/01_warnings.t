use strict;
use warnings;
use Test::More tests => 2278;
use_ok('String::Perl::Warnings', qw(is_warning));

while(<DATA>){
  chomp;
  ok( is_warning($_), "Warning: '$_'" );
}

exit 0;
__END__
Reversed += operator at - line 3.
Name "main::a" used only once: possible typo at - line 3.
Reversed += operator at - line 3.
Name "main::a" used only once: possible typo at - line 3.
Reversed += operator at - line 4.
Name "main::a" used only once: possible typo at - line 4.
Use of uninitialized value $b in scalar chop at - line 4.
Use of uninitialized value $b in scalar chop at - line 5.
Use of uninitialized value $b in scalar chop at ./abcd line 1.
Use of uninitialized value $b in scalar chop at ./abcd line 1.
Use of uninitialized value $b in scalar chop at ./abcd line 1.
Use of uninitialized value $b in scalar chop at - line 3.
Use of uninitialized value $b in scalar chop at (eval 1) line 1.
Use of uninitialized value $b in scalar chop at - line 4.
Use of uninitialized value $b in scalar chop at - line 4.
Use of uninitialized value $b in scalar chop at - line 5.
Use of uninitialized value in -e at - line 2.
Use of uninitialized value $b in scalar chop at - line 2.
BEGIN failed--compilation aborted at - line 3.
Reversed += operator at - line 8.
Use of uninitialized value $b in scalar chop at - line 8.
Use of uninitialized value $b in scalar chop at - line 6.
Use of uninitialized value $b in scalar chop at - line 6.
Reversed += operator at - line 3.
Useless use of concatenation (.) or string in void context at - line 3.
Reversed += operator at ./abc line 2.
Use of uninitialized value $a in scalar chop at - line 3.
Reversed += operator at abc.pm line 2.
Use of uninitialized value $a in scalar chop at - line 3.
Use of uninitialized value $b in scalar chop at - line 8.
Use of uninitialized value $b in scalar chop at - line 7.
Use of uninitialized value $b in scalar chop at - line 9.
Use of uninitialized value $b in scalar chop at - line 10.
Reversed += operator at - line 8.
Reversed += operator at - line 7.
Reversed += operator at - line 9.
Reversed += operator at - line 10.
Use of uninitialized value $b in scalar chop at (eval 1) line 3.
Use of uninitialized value $b in scalar chop at (eval 1) line 2.
Use of uninitialized value $b in scalar chop at - line 9.
Use of uninitialized value $b in scalar chop at - line 10.
Reversed += operator at (eval 1) line 3.
Reversed += operator at - line 9.
Reversed += operator at (eval 1) line 2.
Reversed += operator at - line 10.
Reversed += operator at - line 6.
Use of uninitialized value $c in scalar chop at - line 9.
Use of uninitialized value $b in scalar chop at - line 6.
Use of uninitialized value $b in scalar chop at - line 6.
Use of uninitialized value $b in scalar chop at - line 6.
Use of uninitialized value $b in scalar chop at - line 6.
Use of uninitialized value $b in scalar chop at - line 5.
Use of uninitialized value $b in scalar chop at - line 6.
Use of uninitialized value $b in scalar chop at - line 6.
Use of uninitialized value $b in scalar chop at - line 6.
Use of uninitialized value $b in scalar chop at - line 10.
Use of uninitialized value $b in scalar chop at - line 7.
Use of uninitialized value $b in scalar chop at (eval 1) line 3.
Use of uninitialized value $b in scalar chop at (eval 1) line 2.
Use of uninitialized value $b in scalar chop at - line 9.
Use of uninitialized value $b in scalar chop at - line 10.
print() on closed filehandle STDIN at - line 6.
print() on closed filehandle STDIN at - line 4.
print() on closed filehandle STDIN at - line 5.
Reversed += operator at - line 5.
print() on closed filehandle STDIN at - line 6.
print() on closed filehandle STDIN at - line 5.
print() on closed filehandle STDIN at - line 5.
Reversed += operator at abc.pm line 4.
Reversed += operator at ./abc line 4.
Reversed += operator at abc.pm line 4.
Use of uninitialized value $a in scalar chop at - line 3.
Reversed += operator at ./abc line 3.
Use of uninitialized value $a in scalar chop at - line 3.
Use of uninitialized value $b in scalar chop at (eval 1) line 2.
Use of uninitialized value $b in scalar chop at - line 8.
Use of uninitialized value $b in scalar chop at (eval 1) line 3.
Use of uninitialized value $b in scalar chop at - line 10.
Use of uninitialized value $b in scalar chop at (eval 1) line 2.
Use of uninitialized value $b in scalar chop at - line 9.
Use of uninitialized value $b in scalar chop at (eval 1) line 3.
Use of uninitialized value $b in scalar chop at - line 10.
Reversed += operator at - line 11.
Reversed += operator at (eval 1) line 3.
Reversed += operator at - line 10.
Reversed += operator at (eval 1) line 2.
Reversed += operator at - line 11.
Reversed += operator at (eval 1) line 3.
Integer overflow in octal number at - line 3.
Integer overflow in octal number at - line 3.
Illegal octal digit '8' ignored at - line 3.
Octal number > 037777777777 non-portable at - line 3.
Integer overflow in octal number at - line 3.
Illegal octal digit '8' ignored at - line 3.
Octal number > 037777777777 non-portable at - line 3.
Integer overflow in octal number at - line 8.
Illegal octal digit '8' ignored at - line 8.
Octal number > 037777777777 non-portable at - line 8.
Integer overflow in hexadecimal number at - line 3.
Illegal hexadecimal digit 'g' ignored at - line 3.
Hexadecimal number > 0xffffffff non-portable at - line 3.
Integer overflow in binary number at - line 3.
Illegal binary digit '2' ignored at - line 3.
Binary number > 0b11111111111111111111111111111111 non-portable at - line 3.
Integer overflow in hexadecimal number at (eval 1) line 3.
Illegal hexadecimal digit 'g' ignored at (eval 1) line 3.
Hexadecimal number > 0xffffffff non-portable at (eval 1) line 3.
Integer overflow in hexadecimal number at (eval 1) line 2.
Illegal hexadecimal digit 'g' ignored at (eval 1) line 2.
Hexadecimal number > 0xffffffff non-portable at (eval 1) line 2.
Useless use of time in void context at - line 4.
Useless use of length in void context at - line 8.
Useless use of time in void context at - line 4.
Useless use of length in void context at - line 8.
Use of uninitialized value $b in scalar chop at - line 8.
Use of uninitialized value $b in scalar chop at - line 11.
Use of uninitialized value $b in scalar chop at - line 8.
Use of uninitialized value $b in scalar chop at - line 11.
Use of uninitialized value $b in scalar chop at - line 7.
Useless use of length in void context at - line 4.
Useless use of length in void context at - line 4.
Useless use of length in void context at - line 5.
Use of uninitialized value $a in scalar chomp at - line 4.
Useless use of length in void context at - line 4.
Useless use of length in void context at - line 4.
Unsuccessful open on filename containing newline at - line 5.
close() on unopened filehandle fred at - line 6.
Unsuccessful open on filename containing newline at - line 5.
close() on unopened filehandle fred at - line 6.
Reversed += operator at - line 8.
Unknown warnings category 'fred' at - line 9
Use of uninitialized value $m1 in addition (+) at - line 4.
Use of uninitialized value $m2 in addition (+) at - line 5.
Use of uninitialized value $m2 in addition (+) at - line 6.
Use of uninitialized value $m1 in addition (+) at - line 6.
Use of uninitialized value $g1 in addition (+) at - line 5.
Use of uninitialized value $g2 in addition (+) at - line 6.
Use of uninitialized value $g2 in addition (+) at - line 7.
Use of uninitialized value $g1 in addition (+) at - line 7.
Use of uninitialized value $g2 in addition (+) at - line 8.
Use of uninitialized value $m1 in addition (+) at - line 8.
Use of uninitialized value $ma[5] in addition (+) at - line 4.
Use of uninitialized value $ma[6] in addition (+) at - line 5.
Use of uninitialized value $m1 in addition (+) at - line 6.
Use of uninitialized value in addition (+) at - line 6.
Use of uninitialized value in addition (+) at - line 7.
Use of uninitialized value in addition (+) at - line 7.
Use of uninitialized value in addition (+) at - line 8.
Use of uninitialized value in addition (+) at - line 8.
Use of uninitialized value $mau[5] in addition (+) at - line 6.
Use of uninitialized value $mau[-5] in addition (+) at - line 7.
Use of uninitialized value $mau[6] in addition (+) at - line 8.
Use of uninitialized value $mau[-6] in addition (+) at - line 9.
Use of uninitialized value $mau[8] in addition (+) at - line 10.
Use of uninitialized value $mau[7] in addition (+) at - line 10.
Use of uninitialized value $mau[257] in addition (+) at - line 11.
Use of uninitialized value $mau[256] in addition (+) at - line 11.
Use of uninitialized value $mau[-2] in addition (+) at - line 12.
Use of uninitialized value $mau[-1] in addition (+) at - line 12.
Use of uninitialized value $mhu{"bar"} in addition (+) at - line 13.
Use of uninitialized value $mhu{"foo"} in addition (+) at - line 13.
Use of uninitialized value $ga[8] in addition (+) at - line 5.
Use of uninitialized value $ga[-8] in addition (+) at - line 6.
Use of uninitialized value $ga[9] in addition (+) at - line 7.
Use of uninitialized value $ga[-9] in addition (+) at - line 8.
Use of uninitialized value in addition (+) at - line 9.
Use of uninitialized value in addition (+) at - line 9.
Use of uninitialized value in addition (+) at - line 10.
Use of uninitialized value in addition (+) at - line 10.
Use of uninitialized value $gau[8] in addition (+) at - line 6.
Use of uninitialized value $gau[-8] in addition (+) at - line 7.
Use of uninitialized value $gau[9] in addition (+) at - line 8.
Use of uninitialized value $gau[-9] in addition (+) at - line 9.
Use of uninitialized value $gau[11] in addition (+) at - line 10.
Use of uninitialized value $gau[10] in addition (+) at - line 10.
Use of uninitialized value $gau[257] in addition (+) at - line 11.
Use of uninitialized value $gau[256] in addition (+) at - line 11.
Use of uninitialized value $gau[-2] in addition (+) at - line 12.
Use of uninitialized value $gau[-1] in addition (+) at - line 12.
Use of uninitialized value $ghu{"bar"} in addition (+) at - line 13.
Use of uninitialized value $ghu{"foo"} in addition (+) at - line 13.
Use of uninitialized value $mau[20] in addition (+) at - line 14.
Use of uninitialized value $mau[10] in addition (+) at - line 14.
Use of uninitialized value $gau[20] in addition (+) at - line 15.
Use of uninitialized value $gau[10] in addition (+) at - line 15.
Use of uninitialized value in addition (+) at - line 16.
Use of uninitialized value $gau[10] in addition (+) at - line 16.
Use of uninitialized value $mhu{"bar"} in addition (+) at - line 17.
Use of uninitialized value $mhu{"foo"} in addition (+) at - line 17.
Use of uninitialized value $ghu{"bar"} in addition (+) at - line 18.
Use of uninitialized value $ghu{"foo"} in addition (+) at - line 18.
Use of uninitialized value in addition (+) at - line 19.
Use of uninitialized value $ghu{"foo"} in addition (+) at - line 19.
Use of uninitialized value $m1 in array element at - line 5.
Use of uninitialized value $g1 in array element at - line 6.
Use of uninitialized value $m2 in array element at - line 7.
Use of uninitialized value $g2 in array element at - line 8.
Use of uninitialized value $m1 in hash element at - line 10.
Use of uninitialized value $g1 in hash element at - line 11.
Use of uninitialized value $m2 in hash element at - line 12.
Use of uninitialized value $g2 in hash element at - line 13.
Use of uninitialized value $g1 in subtraction (-) at - line 15.
Use of uninitialized value $m2 in subtraction (-) at - line 15.
Use of uninitialized value $m1 in addition (+) at - line 15.
Use of uninitialized value $ga[3] in array element at - line 16.
Use of uninitialized value $ma[4] in array element at - line 17.
Use of uninitialized value $ga[1000] in sin at - line 5.
Use of uninitialized value $ma[1000] in sin at - line 6.
Use of uninitialized value $gh{"foo"} in sin at - line 7.
Use of uninitialized value $mh{"bar"} in sin at - line 8.
Use of uninitialized value within @ga in sin at - line 10.
Use of uninitialized value within @ma in sin at - line 11.
Use of uninitialized value within %gh in sin at - line 12.
Use of uninitialized value within %mh in sin at - line 13.
Use of uninitialized value $mat[0] in sin at - line 13.
Use of uninitialized value in addition (+) at - line 14.
Use of uninitialized value in addition (+) at - line 14.
Use of uninitialized value $mat[1000] in sin at - line 15.
Use of uninitialized value in addition (+) at - line 16.
Use of uninitialized value in addition (+) at - line 16.
Use of uninitialized value within @mat in sin at - line 18.
Use of uninitialized value in addition (+) at - line 19.
Use of uninitialized value in addition (+) at - line 19.
Use of uninitialized value $mht{"foo"} in sin at - line 21.
Use of uninitialized value in addition (+) at - line 22.
Use of uninitialized value in addition (+) at - line 22.
Use of uninitialized value within %mht in sin at - line 24.
Use of uninitialized value in addition (+) at - line 25.
Use of uninitialized value in addition (+) at - line 25.
Use of uninitialized value $1 in addition (+) at - line 27.
Use of uninitialized value $ga[1000] in print at - line 5.
Use of uninitialized value $ga[1000] in print at - line 6.
Use of uninitialized value $m1 in print at - line 7.
Use of uninitialized value $g1 in print at - line 7.
Use of uninitialized value in print at - line 7.
Use of uninitialized value $m2 in print at - line 7.
Use of uninitialized value $ga[1] in print at - line 8.
Use of uninitialized value $m1 in ref-to-glob cast at - line 5.
Use of uninitialized value $g1 in ref-to-glob cast at - line 6.
Use of uninitialized value $m1 in scalar dereference at - line 5.
Use of uninitialized value $g1 in scalar dereference at - line 6.
Use of uninitialized value $m1 in array dereference at - line 8.
Use of uninitialized value $g1 in array dereference at - line 9.
Use of uninitialized value $m2 in hash dereference at - line 10.
Use of uninitialized value $g2 in hash dereference at - line 11.
Use of uninitialized value in addition (+) at - line 13.
Use of uninitialized value $m1 in concatenation (.) or string at - line 14.
Use of uninitialized value in addition (+) at - line 14.
Use of uninitialized value $g1 in concatenation (.) or string at - line 15.
Use of uninitialized value in addition (+) at - line 15.
Use of uninitialized value $m1 in bitwise or (|) at - line 5.
Use of uninitialized value $m2 in bitwise or (|) at - line 5.
Use of uninitialized value $m1 in bitwise and (&) at - line 6.
Use of uninitialized value $m2 in bitwise and (&) at - line 6.
Use of uninitialized value $m1 in bitwise xor (^) at - line 7.
Use of uninitialized value $m2 in bitwise xor (^) at - line 7.
Use of uninitialized value $m1 in 1's complement (~) at - line 8.
Use of uninitialized value $g1 in bitwise or (|) at - line 10.
Use of uninitialized value $g2 in bitwise or (|) at - line 10.
Use of uninitialized value $g1 in bitwise and (&) at - line 11.
Use of uninitialized value $g2 in bitwise and (&) at - line 11.
Use of uninitialized value $g1 in bitwise xor (^) at - line 12.
Use of uninitialized value $g2 in bitwise xor (^) at - line 12.
Use of uninitialized value $g1 in 1's complement (~) at - line 13.
Use of uninitialized value $s1 in scalar chomp at - line 3.
Use of uninitialized value $s2 in scalar chop at - line 4.
Use of uninitialized value $s4 in chomp at - line 5.
Use of uninitialized value $s3 in chomp at - line 5.
Use of uninitialized value $s5 in chop at - line 6.
Use of uninitialized value $s6 in chop at - line 6.
Use of uninitialized value ${$/} in scalar chomp at - line 6.
Use of uninitialized value ${$/} in chomp at - line 8.
Use of uninitialized value $y in chomp at - line 8.
Use of uninitialized value ${$/} in chomp at - line 8.
Use of uninitialized value $y in chop at - line 8.
Use of uninitialized value $m1 in delete at - line 5.
Use of uninitialized value $m1 in delete at - line 6.
Use of uninitialized value $g1 in delete at - line 6.
Use of uninitialized value $m1 in delete at - line 7.
Use of uninitialized value $m1 in delete at - line 8.
Use of uninitialized value $g1 in delete at - line 8.
Use of uninitialized value $m1 in array slice at - line 5.
Use of uninitialized value $g1 in array slice at - line 5.
Use of uninitialized value $m1 in list slice at - line 6.
Use of uninitialized value $g1 in list slice at - line 6.
Use of uninitialized value $m1 in hash slice at - line 7.
Use of uninitialized value $g1 in hash slice at - line 7.
Use of uninitialized value $m1 in exists at - line 5.
Use of uninitialized value $g1 in exists at - line 6.
Use of uninitialized value $m1 in exists at - line 7.
Use of uninitialized value $g1 in exists at - line 8.
Use of uninitialized value $m1 in left bitshift (<<) at - line 6.
Use of uninitialized value $x1 in left bitshift (<<) at - line 6.
Use of uninitialized value $g1 in left bitshift (<<) at - line 7.
Use of uninitialized value $x2 in left bitshift (<<) at - line 7.
Use of uninitialized value $g1 in integer addition (+) at - line 6.
Use of uninitialized value $m1 in integer addition (+) at - line 6.
Use of uninitialized value $g1 in integer subtraction (-) at - line 7.
Use of uninitialized value $m1 in integer subtraction (-) at - line 7.
Use of uninitialized value $g1 in integer multiplication (*) at - line 8.
Use of uninitialized value $m1 in integer multiplication (*) at - line 8.
Use of uninitialized value $g1 in integer division (/) at - line 9.
Use of uninitialized value $m2 in integer division (/) at - line 10.
Use of uninitialized value $g1 in integer modulus (%) at - line 11.
Use of uninitialized value $m1 in integer modulus (%) at - line 11.
Use of uninitialized value $m2 in integer modulus (%) at - line 12.
Use of uninitialized value $g1 in integer lt (<) at - line 13.
Use of uninitialized value $m1 in integer lt (<) at - line 13.
Use of uninitialized value $g1 in integer gt (>) at - line 14.
Use of uninitialized value $m1 in integer gt (>) at - line 14.
Use of uninitialized value $g1 in integer le (<=) at - line 15.
Use of uninitialized value $m1 in integer le (<=) at - line 15.
Use of uninitialized value $g1 in integer ge (>=) at - line 16.
Use of uninitialized value $m1 in integer ge (>=) at - line 16.
Use of uninitialized value $g1 in integer eq (==) at - line 17.
Use of uninitialized value $m1 in integer eq (==) at - line 17.
Use of uninitialized value $g1 in integer ne (!=) at - line 18.
Use of uninitialized value $m1 in integer ne (!=) at - line 18.
Use of uninitialized value $g1 in integer comparison (<=>) at - line 19.
Use of uninitialized value $m1 in integer comparison (<=>) at - line 19.
Use of uninitialized value $m1 in integer negation (-) at - line 20.
Use of uninitialized value $g1 in int at - line 5.
Use of uninitialized value $g2 in abs at - line 6.
Use of uninitialized value $m1 in pack at - line 5.
Use of uninitialized value $m2 in pack at - line 6.
Use of uninitialized value $g1 in pack at - line 6.
Use of uninitialized value $g2 in pack at - line 6.
Use of uninitialized value $m1 in unpack at - line 7.
Use of uninitialized value $m2 in unpack at - line 7.
Use of uninitialized value $m1 in sort at - line 6.
Use of uninitialized value $g1 in sort at - line 6.
Use of uninitialized value $m1 in sort at - line 6.
Use of uninitialized value $g1 in sort at - line 6.
Use of uninitialized value $m1 in sort at - line 7.
Use of uninitialized value $g1 in sort at - line 7.
Use of uninitialized value $m1 in sort at - line 7.
Use of uninitialized value $g1 in sort at - line 7.
Use of uninitialized value $a in subtraction (-) at - line 8.
Use of uninitialized value $b in subtraction (-) at - line 8.
Use of uninitialized value $m1 in sort at - line 9.
Use of uninitialized value $g1 in sort at - line 9.
Use of uninitialized value $m1 in sort at - line 9.
Use of uninitialized value $m1 in sort at - line 9.
Use of uninitialized value $g1 in sort at - line 9.
Use of uninitialized value $g1 in sort at - line 9.
Use of uninitialized value $g1 in division (/) at - line 5.
Use of uninitialized value $m1 in division (/) at - line 5.
Use of uninitialized value $m2 in division (/) at - line 6.
Use of uninitialized value $g1 in modulus (%) at - line 7.
Use of uninitialized value $m1 in modulus (%) at - line 7.
Use of uninitialized value $m2 in modulus (%) at - line 8.
Use of uninitialized value $g1 in numeric eq (==) at - line 9.
Use of uninitialized value $m1 in numeric eq (==) at - line 9.
Use of uninitialized value $g1 in numeric ge (>=) at - line 10.
Use of uninitialized value $m1 in numeric ge (>=) at - line 10.
Use of uninitialized value $g1 in numeric gt (>) at - line 11.
Use of uninitialized value $m1 in numeric gt (>) at - line 11.
Use of uninitialized value $g1 in numeric le (<=) at - line 12.
Use of uninitialized value $m1 in numeric le (<=) at - line 12.
Use of uninitialized value $g1 in numeric lt (<) at - line 13.
Use of uninitialized value $m1 in numeric lt (<) at - line 13.
Use of uninitialized value $g1 in multiplication (*) at - line 14.
Use of uninitialized value $m1 in multiplication (*) at - line 14.
Use of uninitialized value $g1 in numeric comparison (<=>) at - line 15.
Use of uninitialized value $m1 in numeric comparison (<=>) at - line 15.
Use of uninitialized value $g1 in numeric ne (!=) at - line 16.
Use of uninitialized value $m1 in numeric ne (!=) at - line 16.
Use of uninitialized value $g1 in subtraction (-) at - line 17.
Use of uninitialized value $m1 in subtraction (-) at - line 17.
Use of uninitialized value $g1 in exponentiation (**) at - line 18.
Use of uninitialized value $m1 in exponentiation (**) at - line 18.
Use of uninitialized value $g1 in addition (+) at - line 19.
Use of uninitialized value $m1 in addition (+) at - line 19.
Use of uninitialized value $g1 in subtraction (-) at - line 20.
Use of uninitialized value $m1 in subtraction (-) at - line 20.
Use of uninitialized value $m1 in glob elem at - line 5.
Use of uninitialized value $g1 in subroutine prototype at - line 6.
Use of uninitialized value $g1 in bless at - line 7.
Use of uninitialized value $m1 in quoted execution (``, qx) at - line 8.
Use of uninitialized value $m1 in concatenation (.) or string at - line 10.
Use of uninitialized value $g1 in concatenation (.) or string at - line 10.
Use of uninitialized value $_ in pattern match (m//) at - line 5.
Use of uninitialized value $m1 in regexp compilation at - line 6.
Use of uninitialized value $_ in pattern match (m//) at - line 6.
Use of uninitialized value $g1 in regexp compilation at - line 7.
Use of uninitialized value $_ in pattern match (m//) at - line 7.
Use of uninitialized value $_ in substitution (s///) at - line 9.
Use of uninitialized value $m1 in regexp compilation at - line 10.
Use of uninitialized value $_ in substitution (s///) at - line 10.
Use of uninitialized value $_ in substitution (s///) at - line 10.
Use of uninitialized value $_ in substitution (s///) at - line 11.
Use of uninitialized value $g1 in substitution (s///) at - line 11.
Use of uninitialized value $_ in substitution (s///) at - line 11.
Use of uninitialized value $g1 in substitution (s///) at - line 11.
Use of uninitialized value $m1 in regexp compilation at - line 12.
Use of uninitialized value $_ in substitution (s///) at - line 12.
Use of uninitialized value $_ in substitution (s///) at - line 12.
Use of uninitialized value $g1 in substitution iterator at - line 12.
Use of uninitialized value $_ in transliteration (tr///) at - line 13.
Use of uninitialized value $_ in pattern match (m//) at - line 16.
Use of uninitialized value $m1 in regexp compilation at - line 17.
Use of uninitialized value $_ in pattern match (m//) at - line 17.
Use of uninitialized value $g1 in regexp compilation at - line 18.
Use of uninitialized value $_ in pattern match (m//) at - line 18.
Use of uninitialized value $_ in substitution (s///) at - line 19.
Use of uninitialized value $m1 in regexp compilation at - line 20.
Use of uninitialized value $_ in substitution (s///) at - line 20.
Use of uninitialized value $_ in substitution (s///) at - line 20.
Use of uninitialized value $_ in substitution (s///) at - line 21.
Use of uninitialized value $g1 in substitution (s///) at - line 21.
Use of uninitialized value $_ in substitution (s///) at - line 21.
Use of uninitialized value $g1 in substitution (s///) at - line 21.
Use of uninitialized value $m1 in regexp compilation at - line 22.
Use of uninitialized value $_ in substitution (s///) at - line 22.
Use of uninitialized value $_ in substitution (s///) at - line 22.
Use of uninitialized value $g1 in substitution iterator at - line 22.
Use of uninitialized value $_ in transliteration (tr///) at - line 23.
Use of uninitialized value $g2 in pattern match (m//) at - line 25.
Use of uninitialized value $m1 in regexp compilation at - line 26.
Use of uninitialized value $g2 in pattern match (m//) at - line 26.
Use of uninitialized value $g1 in regexp compilation at - line 27.
Use of uninitialized value $g2 in pattern match (m//) at - line 27.
Use of uninitialized value $g2 in substitution (s///) at - line 28.
Use of uninitialized value $m1 in regexp compilation at - line 29.
Use of uninitialized value $g2 in substitution (s///) at - line 29.
Use of uninitialized value $g2 in substitution (s///) at - line 29.
Use of uninitialized value $g2 in substitution (s///) at - line 30.
Use of uninitialized value $g1 in substitution (s///) at - line 30.
Use of uninitialized value $g2 in substitution (s///) at - line 30.
Use of uninitialized value $g1 in substitution (s///) at - line 30.
Use of uninitialized value $m1 in regexp compilation at - line 31.
Use of uninitialized value $g2 in substitution (s///) at - line 31.
Use of uninitialized value $g2 in substitution (s///) at - line 31.
Use of uninitialized value $g1 in substitution iterator at - line 31.
Use of uninitialized value in transliteration (tr///) at - line 32.
Use of uninitialized value $m1 in regexp compilation at - line 35.
Use of uninitialized value $g1 in regexp compilation at - line 36.
Use of uninitialized value $m1 in regexp compilation at - line 38.
Use of uninitialized value $g1 in substitution (s///) at - line 39.
Use of uninitialized value $m1 in regexp compilation at - line 40.
Use of uninitialized value $g1 in substitution iterator at - line 40.
Use of uninitialized value $m1 in substitution iterator at - line 41.
Use of uninitialized value $m1 in list assignment at - line 4.
Use of uninitialized value $_ in study at - line 4.
Use of uninitialized value $g1 in study at - line 5.
Use of uninitialized value $_ in scalar assignment at - line 4.
Use of uninitialized value $m1 in scalar assignment at - line 5.
Use of uninitialized value in addition (+) at - line 5.
Use of uninitialized value in addition (+) at - line 6.
Use of uninitialized value in addition (+) at - line 9.
Use of uninitialized value in addition (+) at - line 10.
Use of uninitialized value $m1 in repeat (x) at - line 4.
Use of uninitialized value $m1 in repeat (x) at - line 5.
Use of uninitialized value $m1 in string at - line 5.
Use of uninitialized value $m1 in string lt at - line 7.
Use of uninitialized value $g1 in string lt at - line 7.
Use of uninitialized value $m1 in string le at - line 8.
Use of uninitialized value $g1 in string le at - line 8.
Use of uninitialized value $m1 in string gt at - line 9.
Use of uninitialized value $g1 in string gt at - line 9.
Use of uninitialized value $m1 in string ge at - line 10.
Use of uninitialized value $g1 in string ge at - line 10.
Use of uninitialized value $m1 in string eq at - line 11.
Use of uninitialized value $g1 in string eq at - line 11.
Use of uninitialized value $m1 in string ne at - line 12.
Use of uninitialized value $g1 in string ne at - line 12.
Use of uninitialized value $m1 in string comparison (cmp) at - line 13.
Use of uninitialized value $g1 in string comparison (cmp) at - line 13.
Use of uninitialized value $g1 in atan2 at - line 5.
Use of uninitialized value $m1 in atan2 at - line 5.
Use of uninitialized value $m1 in sin at - line 6.
Use of uninitialized value $m1 in cos at - line 7.
Use of uninitialized value $m1 in rand at - line 8.
Use of uninitialized value $m1 in srand at - line 9.
Use of uninitialized value $m1 in exp at - line 10.
Use of uninitialized value $m1 in log at - line 11.
Use of uninitialized value $m1 in sqrt at - line 12.
Use of uninitialized value $m1 in hex at - line 13.
Use of uninitialized value $m1 in oct at - line 14.
Use of uninitialized value $m1 in length at - line 15.
Use of uninitialized value $_ in length at - line 16.
Use of uninitialized value $g1 in substr at - line 5.
Use of uninitialized value $m1 in substr at - line 5.
Use of uninitialized value $m2 in substr at - line 6.
Use of uninitialized value $g1 in substr at - line 6.
Use of uninitialized value $m1 in substr at - line 6.
Use of uninitialized value $g2 in substr at - line 7.
Use of uninitialized value $m2 in substr at - line 7.
Use of uninitialized value $g1 in substr at - line 7.
Use of uninitialized value $m1 in substr at - line 7.
Use of uninitialized value $m1 in substr at - line 7.
Use of uninitialized value $g1 in substr at - line 8.
Use of uninitialized value $m1 in substr at - line 8.
Use of uninitialized value in scalar assignment at - line 8.
Use of uninitialized value $m2 in substr at - line 9.
Use of uninitialized value $g1 in substr at - line 9.
Use of uninitialized value $m1 in substr at - line 9.
Use of uninitialized value in scalar assignment at - line 9.
Use of uninitialized value $m2 in vec at - line 11.
Use of uninitialized value $g1 in vec at - line 11.
Use of uninitialized value $m1 in vec at - line 11.
Use of uninitialized value $m2 in vec at - line 12.
Use of uninitialized value $g1 in vec at - line 12.
Use of uninitialized value $m1 in vec at - line 12.
Use of uninitialized value $m1 in index at - line 14.
Use of uninitialized value $m2 in index at - line 14.
Use of uninitialized value $g1 in index at - line 15.
Use of uninitialized value $m1 in index at - line 15.
Use of uninitialized value $m2 in index at - line 15.
Use of uninitialized value $m1 in rindex at - line 16.
Use of uninitialized value $m2 in rindex at - line 16.
Use of uninitialized value $g1 in rindex at - line 17.
Use of uninitialized value $m1 in rindex at - line 17.
Use of uninitialized value $m2 in rindex at - line 17.
Use of uninitialized value $m1 in sprintf at - line 5.
Use of uninitialized value $m1 in sprintf at - line 6.
Use of uninitialized value $m2 in sprintf at - line 6.
Use of uninitialized value $g1 in sprintf at - line 6.
Use of uninitialized value $g2 in sprintf at - line 6.
Use of uninitialized value $m3 in formline at - line 7.
Use of uninitialized value $m1 in formline at - line 8.
Use of uninitialized value $m2 in formline at - line 8.
Use of uninitialized value $g1 in formline at - line 8.
Use of uninitialized value $g2 in formline at - line 8.
Use of uninitialized value $m1 in crypt at - line 5.
Use of uninitialized value $g1 in crypt at - line 5.
Use of uninitialized value $_ in ord at - line 7.
Use of uninitialized value $m1 in ord at - line 8.
Use of uninitialized value $_ in chr at - line 9.
Use of uninitialized value $m1 in chr at - line 10.
Use of uninitialized value $_ in quotemeta at - line 22.
Use of uninitialized value $m1 in quotemeta at - line 23.
Use of uninitialized value $_ in split at - line 5.
Use of uninitialized value $m1 in regexp compilation at - line 6.
Use of uninitialized value $_ in split at - line 6.
Use of uninitialized value $m1 in regexp compilation at - line 7.
Use of uninitialized value $m2 in split at - line 7.
Use of uninitialized value $m1 in regexp compilation at - line 8.
Use of uninitialized value $g1 in split at - line 8.
Use of uninitialized value $m2 in split at - line 8.
Use of uninitialized value $m1 in join or string at - line 10.
Use of uninitialized value $m1 in join or string at - line 11.
Use of uninitialized value $m2 in join or string at - line 11.
Use of uninitialized value $m1 in join or string at - line 12.
Use of uninitialized value $m2 in join or string at - line 12.
Use of uninitialized value $m3 in join or string at - line 12.
Use of uninitialized value $foo1[1] in chomp at - line 4.
Use of uninitialized value $foo2[1] in chomp at - line 5.
Use of uninitialized value $foo3[1] in chop at - line 6.
Use of uninitialized value $foo4[1] in chop at - line 7.
Use of uninitialized value $foo5[1] in sprintf at - line 8.
Use of uninitialized value $foo6[1] in sprintf at - line 9.
Use of uninitialized value $foo7{"baz"} in sprintf at - line 10.
Use of uninitialized value $foo8{"baz"} in sprintf at - line 11.
Use of uninitialized value $m1 in sprintf at - line 12.
Use of uninitialized value $foo9[1] in sprintf at - line 12.
Use of uninitialized value in sprintf at - line 12.
Use of uninitialized value $m2 in sprintf at - line 13.
Use of uninitialized value $foo10[1] in sprintf at - line 13.
Use of uninitialized value in sprintf at - line 13.
Use of uninitialized value $foo11{"baz"} in join or string at - line 14.
Use of uninitialized value $foo12{"baz"} in join or string at - line 15.
Use of uninitialized value within %foo13 in join or string at - line 16.
Use of uninitialized value within %foo14 in join or string at - line 17.
Use of uninitialized value $^FOO in addition (+) at - line 4.
Use of uninitialized value $^A in addition (+) at - line 4.
Use of uninitialized value $GLOB1 in addition (+) at - line 6.
Use of uninitialized value $GLOB2 in addition (+) at - line 7.
Use of uninitialized value $h{"\0011\2\r\n\t\f\"\\abcdefghijklm"...} in join or string at - line 6.
Use of uninitialized value $m1 in subroutine dereference at - line 5.
Use of uninitialized value $m1 in subroutine dereference at - line 5.
Use of uninitialized value $g1 in subroutine dereference at - line 6.
Use of uninitialized value $g1 in subroutine dereference at - line 6.
Use of uninitialized value $m1 in splice at - line 9.
Use of uninitialized value $g1 in splice at - line 9.
Use of uninitialized value $m1 in splice at - line 10.
Use of uninitialized value $g1 in splice at - line 10.
Use of uninitialized value in addition (+) at - line 10.
Use of uninitialized value $m1 in method lookup at - line 13.
Use of uninitialized value in subroutine entry at - line 15.
Use of uninitialized value in subroutine entry at - line 16.
Use of uninitialized value $m1 in warn at - line 18.
Use of uninitialized value $g1 in warn at - line 18.
Use of uninitialized value $m1 in die at - line 20.
Use of uninitialized value $g1 in die at - line 20.
Use of uninitialized value $m1 in symbol reset at - line 22.
Use of uninitialized value $g1 in symbol reset at - line 23.
Use of uninitialized value $FOO in open at - line 5.
Use of uninitialized value in open at - line 7.
Use of uninitialized value in open at - line 8.
Use of uninitialized value in open at - line 9.
Use of uninitialized value $m1 in open at - line 11.
Use of uninitialized value $m1 in open at - line 12.
Use of uninitialized value $g1 in open at - line 13.
Use of uninitialized value $m2 in sysopen at - line 15.
Use of uninitialized value $m1 in sysopen at - line 15.
Use of uninitialized value $m2 in sysopen at - line 16.
Use of uninitialized value $g1 in sysopen at - line 16.
Use of uninitialized value $m1 in sysopen at - line 16.
Use of uninitialized value $m1 in umask at - line 19.
Use of uninitialized value $g1 in umask at - line 20.
Use of uninitialized value $m1 in binmode at - line 23.
Use of uninitialized value $m1 in binmode at - line 23.
Use of uninitialized value $m1 in tie at - line 5.
Use of uninitialized value $m1 in tie at - line 5.
Use of uninitialized value $m1 in ref-to-glob cast at - line 7.
Use of uninitialized value $g1 in read at - line 7.
Use of uninitialized value $m1 in ref-to-glob cast at - line 8.
Use of uninitialized value $g1 in read at - line 8.
Use of uninitialized value $g2 in read at - line 8.
Use of uninitialized value $m1 in ref-to-glob cast at - line 9.
Use of uninitialized value $g1 in sysread at - line 9.
Use of uninitialized value $m1 in ref-to-glob cast at - line 10.
Use of uninitialized value $g1 in sysread at - line 10.
Use of uninitialized value $g2 in sysread at - line 10.
Use of uninitialized value $m1 in printf at - line 5.
Use of uninitialized value $m1 in printf at - line 6.
Use of uninitialized value $m2 in printf at - line 6.
Use of uninitialized value $g1 in printf at - line 6.
Use of uninitialized value $g2 in printf at - line 6.
Use of uninitialized value $ga[1000] in printf at - line 7.
Use of uninitialized value $ga[1000] in printf at - line 8.
Use of uninitialized value $m1 in printf at - line 9.
Use of uninitialized value $g1 in printf at - line 9.
Use of uninitialized value in printf at - line 9.
Use of uninitialized value $m2 in printf at - line 9.
Use of uninitialized value $ga[1] in printf at - line 10.
Use of uninitialized value $x in ref-to-glob cast at - line 5.
Use of uninitialized value $g1 in seek at - line 5.
Use of uninitialized value $m1 in seek at - line 5.
Use of uninitialized value $x in ref-to-glob cast at - line 6.
Use of uninitialized value $g1 in sysseek at - line 6.
Use of uninitialized value $m1 in sysseek at - line 6.
Use of uninitialized value $m1 in ref-to-glob cast at - line 7.
Use of uninitialized value $m2 in socket at - line 11.
Use of uninitialized value $g1 in socket at - line 11.
Use of uninitialized value $m1 in socket at - line 11.
Use of uninitialized value $m2 in socketpair at - line 12.
Use of uninitialized value $g1 in socketpair at - line 12.
Use of uninitialized value $m1 in socketpair at - line 12.
Use of uninitialized value $x in ref-to-glob cast at - line 16.
Use of uninitialized value $g1 in flock at - line 16.
Use of uninitialized value $_ in stat at - line 5.
Use of uninitialized value $_ in lstat at - line 6.
Use of uninitialized value $m1 in stat at - line 7.
Use of uninitialized value $g1 in lstat at - line 8.
Use of uninitialized value $m1 in -R at - line 10.
Use of uninitialized value $m1 in -W at - line 11.
Use of uninitialized value $m1 in -X at - line 12.
Use of uninitialized value $m1 in -r at - line 13.
Use of uninitialized value $m1 in -w at - line 14.
Use of uninitialized value $m1 in -x at - line 15.
Use of uninitialized value $m1 in -e at - line 16.
Use of uninitialized value $m1 in -o at - line 17.
Use of uninitialized value $m1 in -O at - line 18.
Use of uninitialized value $m1 in -z at - line 19.
Use of uninitialized value $m1 in -s at - line 20.
Use of uninitialized value $m1 in -M at - line 21.
Use of uninitialized value $m1 in -A at - line 22.
Use of uninitialized value $m1 in -C at - line 23.
Use of uninitialized value $m1 in -S at - line 24.
Use of uninitialized value $m1 in -c at - line 25.
Use of uninitialized value $m1 in -b at - line 26.
Use of uninitialized value $m1 in -f at - line 27.
Use of uninitialized value $m1 in -d at - line 28.
Use of uninitialized value $m1 in -p at - line 29.
Use of uninitialized value $m1 in -l at - line 30.
Use of uninitialized value $m1 in -l at - line 30.
Use of uninitialized value $m1 in -u at - line 31.
Use of uninitialized value $m1 in -g at - line 32.
Use of uninitialized value $m1 in -t at - line 34.
Use of uninitialized value $m1 in -T at - line 35.
Use of uninitialized value $m1 in -B at - line 36.
Use of uninitialized value $m1 in localtime at - line 5.
Use of uninitialized value $g1 in gmtime at - line 6.
Use of uninitialized value $_ in eval "string" at - line 4.
Use of uninitialized value $m1 in eval "string" at - line 5.
Use of uninitialized value $m1 in exit at - line 4.
  Can't open bidirectional pipe		[Perl_do_open9]
  Missing command in piped open		[Perl_do_open9]
  Missing command in piped open		[Perl_do_open9]
  close() on unopened filehandle %s	[Perl_do_close]
  Use of -l on filehandle %s		[Perl_my_lstat]
  Can't exec \"%s\": %s 		[Perl_do_aexec5]
  Can't exec \"%s\": %s 		[Perl_do_exec3]
  Filehandle %s opened only for output	[Perl_do_eof]
  Can't do inplace edit: %s is not a regular file	[Perl_nextargv]
  Can't do inplace edit: %s would not be unique		[Perl_nextargv]
  Can't rename %s to %s: %s, skipping file		[Perl_nextargv]
  Can't rename %s to %s: %s, skipping file		[Perl_nextargv]
  Can't remove %s: %s, skipping file			[Perl_nextargv]
  Can't do inplace edit on %s: %s			[Perl_nextargv]
Can't open bidirectional pipe at - line 3.
Missing command in piped open at - line 3.
Missing command in piped open at - line 3.
Unsuccessful open on filename containing newline at - line 3.
close() on unopened filehandle fred at - line 3.
tell() on unopened filehandle at - line 10.
seek() on unopened filehandle at - line 11.
sysseek() on unopened filehandle at - line 12.
Use of uninitialized value $a in print at - line 3.
Unsuccessful stat on filename containing newline at - line 3.
Unsuccessful stat on filename containing newline at - line 4.
Use of -l on filehandle STDIN at - line 3.
Use of -l on filehandle $fh at - line 6.
Can't exec "lskdjfalksdjfdjfkls": .+
Can't exec "lskdjfalksdjfdjfkls(:? abc)?": .+
Can't do inplace edit: ./temp.dir is not a regular file at - line 9.
Can't do inplace edit: ./temp.dir is not a regular file at - line 21.
Filehandle STDOUT opened only for output at - line 3.
Can't open a reference at - line 14.
Filehandle STDOUT reopened as FH1 only for input at - line 14.
Filehandle STDIN reopened as $fh1 only for output at - line 14.
     Can't locate package %s for @%s::ISA
     Use of inherited AUTOLOAD for non-method %s::%.*s() is deprecated
    Had to create %s unexpectedly		[gv_fetchpv]
    Attempt to free unreferenced glob pointers	[gp_free]
Can't locate package Fred for @main::ISA at - line 3.
Undefined subroutine &main::joe called at - line 3.
Undefined subroutine &main::joe called at - line 3.
Use of inherited AUTOLOAD for non-method main::fred() is deprecated at - line 5.
    %s", "Bad free() ignored	[Perl_mfree]
  No such signal: SIG%s
No such signal: SIGFRED at - line 3.
SIGINT handler "fred" not defined.
Use of uninitialized value $3 in length at - line 4.
Use of uninitialized value $3 in length at - line 3.
     Found = in conditional, should be ==
     Use of implicit split to @_ is deprecated
     Use of implicit split to @_ is deprecated
     Useless use of time in void context
     Useless use of a variable in void context
     Useless use of a constant in void context
     Useless use of sort in scalar context
     Applying %s to %s will act on scalar(%s)
     Parentheses missing around "my" list at -e line 1.
     Parentheses missing around "local" list at -e line 1.
     Bareword found in conditional at -e line 1.
     Subroutine fred redefined at -e line 1.
     Constant subroutine %s redefined 
     Format FRED redefined at /tmp/x line 5.
     Array @%s missing the @ in argument %d of %s() 
     Statement unlikely to be reached
     defined(@array) is deprecated
     defined(%hash) is deprecated
     /---/ should probably be written as "---"
    %s() called too early to check prototype		[Perl_peep]
    Use of /g modifier is meaningless in split
    Possible precedence problem on bitwise %c operator	[Perl_ck_bitop]
    oops: oopsAV		[oopsAV]	TODO
    oops: oopsHV		[oopsHV]	TODO
Found = in conditional, should be == at - line 3.
Use of implicit split to @_ is deprecated at - line 3.
Use of implicit split to @_ is deprecated at - line 3.
Using a hash as a reference is deprecated at - line 4.
Using a hash as a reference is deprecated at - line 5.
Using an array as a reference is deprecated at - line 6.
Using an array as a reference is deprecated at - line 7.
Using a hash as a reference is deprecated at - line 8.
Using a hash as a reference is deprecated at - line 9.
Using an array as a reference is deprecated at - line 10.
Using an array as a reference is deprecated at - line 11.
Useless use of repeat (x) in void context at - line 3.
Useless use of wantarray in void context at - line 5.
Useless use of reference-type operator in void context at - line 12.
Useless use of reference constructor in void context at - line 13.
Useless use of single ref constructor in void context at - line 14.
Useless use of defined operator in void context at - line 15.
Useless use of hex in void context at - line 16.
Useless use of oct in void context at - line 17.
Useless use of length in void context at - line 18.
Useless use of substr in void context at - line 19.
Useless use of vec in void context at - line 20.
Useless use of index in void context at - line 21.
Useless use of rindex in void context at - line 22.
Useless use of sprintf in void context at - line 23.
Useless use of array element in void context at - line 24.
Useless use of array slice in void context at - line 26.
Useless use of hash element in void context at - line 29.
Useless use of hash slice in void context at - line 30.
Useless use of unpack in void context at - line 31.
Useless use of pack in void context at - line 32.
Useless use of join or string in void context at - line 33.
Useless use of list slice in void context at - line 34.
Useless use of sort in void context at - line 37.
Useless use of reverse in void context at - line 38.
Useless use of range (or flop) in void context at - line 41.
Useless use of caller in void context at - line 42.
Useless use of fileno in void context at - line 43.
Useless use of eof in void context at - line 44.
Useless use of tell in void context at - line 45.
Useless use of readlink in void context at - line 46.
Useless use of time in void context at - line 47.
Useless use of localtime in void context at - line 48.
Useless use of gmtime in void context at - line 49.
Useless use of getgrnam in void context at - line 50.
Useless use of getgrgid in void context at - line 51.
Useless use of getpwnam in void context at - line 52.
Useless use of getpwuid in void context at - line 53.
Useless use of subroutine prototype in void context at - line 54.
Useless use of sort in scalar context at - line 3.
Useless use of string in void context at - line 3.
Useless use of telldir in void context at - line 13.
Useless use of getppid in void context at - line 13.
Useless use of getpgrp in void context at - line 13.
Useless use of times in void context at - line 13.
Useless use of getpriority in void context at - line 13.
Useless use of getlogin in void context at - line 13.
Useless use of getsockname in void context at - line 24.
Useless use of getpeername in void context at - line 25.
Useless use of gethostbyname in void context at - line 26.
Useless use of gethostbyaddr in void context at - line 27.
Useless use of gethostent in void context at - line 28.
Useless use of getnetbyname in void context at - line 29.
Useless use of getnetbyaddr in void context at - line 30.
Useless use of getnetent in void context at - line 31.
Useless use of getprotobyname in void context at - line 32.
Useless use of getprotobynumber in void context at - line 33.
Useless use of getprotoent in void context at - line 34.
Useless use of getservbyname in void context at - line 35.
Useless use of getservbyport in void context at - line 36.
Useless use of getservent in void context at - line 37.
Useless use of a variable in void context at - line 3.
Useless use of a variable in void context at - line 4.
Useless use of a variable in void context at - line 5.
Useless use of a variable in void context at - line 6.
Useless use of a constant in void context at - line 3.
Useless use of a constant in void context at - line 4.
Applying pattern match (m//) to @array will act on scalar(@array) at - line 5.
Applying substitution (s///) to @array will act on scalar(@array) at - line 6.
Applying transliteration (tr///) to @array will act on scalar(@array) at - line 7.
Applying pattern match (m//) to @array will act on scalar(@array) at - line 8.
Applying substitution (s///) to @array will act on scalar(@array) at - line 9.
Applying transliteration (tr///) to @array will act on scalar(@array) at - line 10.
Applying pattern match (m//) to %hash will act on scalar(%hash) at - line 11.
Applying substitution (s///) to %hash will act on scalar(%hash) at - line 12.
Applying transliteration (tr///) to %hash will act on scalar(%hash) at - line 13.
Applying pattern match (m//) to %hash will act on scalar(%hash) at - line 14.
Applying substitution (s///) to %hash will act on scalar(%hash) at - line 15.
Applying transliteration (tr///) to %hash will act on scalar(%hash) at - line 16.
Can't modify private array in substitution (s///) at - line 6, near "s/a/b/ ;"
BEGIN not safe after errors--compilation aborted at - line 18.
Parentheses missing around "my" list at - line 3.
Parentheses missing around "my" list at - line 4.
Parentheses missing around "our" list at - line 3.
Parentheses missing around "local" list at - line 3.
Parentheses missing around "local" list at - line 4.
Bareword found in conditional at - line 3.
Value of <HANDLE> construct can be "0"; test with defined() at - line 4.
Value of readdir() operator can be "0"; test with defined() at - line 4.
Value of glob construct can be "0"; test with defined() at - line 3.
Value of each() operator can be "0"; test with defined() at - line 4.
Value of glob construct can be "0"; test with defined() at - line 3.
Value of readdir() operator can be "0"; test with defined() at - line 4.
Subroutine fred redefined at - line 4.
Constant subroutine fred redefined at - line 4.
Constant subroutine fred redefined at - line 4.
Constant subroutine main::fred redefined at - line 4.
Format FRED redefined at - line 5.
Array @FRED missing the @ in argument 1 of push() at - line 3.
Hash %FRED missing the % in argument 1 of keys() at - line 3.
Statement unlikely to be reached at - line 13.
defined(@array) is deprecated at - line 3.
defined(@array) is deprecated at - line 3.
defined(%hash) is deprecated at - line 3.
Prototype mismatch: sub main::fred () vs ($) at - line 3.
Prototype mismatch: sub main::fred () vs ($) at - line 4.
Prototype mismatch: sub main::freD () vs ($) at - line 11.
Prototype mismatch: sub main::FRED () vs ($) at - line 14.
/---/ should probably be written as "---" at - line 3.
main::fred() called too early to check prototype at - line 3.
Too late to run CHECK block at abc.pm line 3.
Too late to run INIT block at abc.pm line 4.
Too late to run CHECK block at abc.pm line 3.
Too late to run INIT block at abc.pm line 4.
Useless use of push with no values at - line 4.
Useless use of unshift with no values at - line 5.
Use of /g modifier is meaningless in split at - line 4.
Possible precedence problem on bitwise & operator at - line 3.
Possible precedence problem on bitwise ^ operator at - line 4.
Possible precedence problem on bitwise | operator at - line 5.
Possible precedence problem on bitwise & operator at - line 6.
Possible precedence problem on bitwise ^ operator at - line 7.
Possible precedence problem on bitwise | operator at - line 8.
Possible precedence problem on bitwise & operator at - line 9.
Possible precedence problem on bitwise & operator at - line 4.
Possible precedence problem on bitwise ^ operator at - line 5.
Possible precedence problem on bitwise | operator at - line 6.
Possible precedence problem on bitwise & operator at - line 7.
Possible precedence problem on bitwise ^ operator at - line 8.
Possible precedence problem on bitwise | operator at - line 9.
Possible precedence problem on bitwise & operator at - line 10.
     "%s" variable %s masks earlier declaration in same scope
     Variable "%s" will not stay shared 
    "our" variable %s redeclared	(Did you mean "local" instead of "our"?)
    %s never introduced		[pad_leavemy]	TODO
"my" variable $x masks earlier declaration in same scope at - line 4.
"my" variable $y masks earlier declaration in same statement at - line 5.
"my" variable $p masks earlier declaration in same scope at - line 8.
"my" variable $x masks earlier declaration in same scope at - line 4.
"my" variable $y masks earlier declaration in same statement at - line 5.
"my" variable $p masks earlier declaration in same scope at - line 8.
"our" variable $x masks earlier declaration in same scope at - line 4.
"our" variable $y masks earlier declaration in same statement at - line 5.
"our" variable $p masks earlier declaration in same scope at - line 8.
Variable "$x" will not stay shared at - line 7.
Variable "$x" will not stay shared at - line 6.
Variable "$x" will not stay shared at - line 9.
"our" variable $x redeclared at - line 4.
"our" variable $y redeclared at - line 5.
"our" variable $x redeclared at - line 4.
	(Did you mean "local" instead of "our"?)
"our" variable $x redeclared at - line 6.
  Unbalanced scopes: %ld more ENTERs than LEAVEs	[perl_destruct]
  Unbalanced saves: %ld more saves than restores	[perl_destruct]
  Unbalanced tmps: %ld more allocs than frees		[perl_destruct]
  Unbalanced context: %ld more PUSHes than POPs		[perl_destruct]
  Scalars leaked: %ld					[perl_destruct]
Name "main::z" used only once: possible typo at - line 5.
Name "main::x" used only once: possible typo at - line 3.
Name "main::x" used only once: possible typo at - line 3.
Name "main::z" used only once: possible typo at - line 6.
Name "main::x" used only once: possible typo at - line 4.
Name "main::x" used only once: possible typo at - line 3.
Name "main::y" used only once: possible typo at - line 6.
Invalid separator character %c%c%c in PerlIO layer specification %s
Invalid separator character '-' in PerlIO layer specification -aa at - line 6.
Argument list not closed for PerlIO layer "aa(" at - line 6.
Unknown PerlIO layer "xyz" at - line 5.
  Use of "do" to call subroutines is deprecated
Use of "do" to call subroutines is deprecated at - line 4.
Use of "do" to call subroutines is deprecated at - line 5.
Use of "do" to call subroutines is deprecated at - line 7.
Use of "do" to call subroutines is deprecated at - line 8.
  substr outside of string
  Attempt to use reference as lvalue in substr 
  Use of uninitialized value in ref-to-glob cast	[pp_rv2gv()]
  Use of uninitialized value in scalar dereference	[pp_rv2sv()]
  Explicit blessing to '' (assuming package main)
  Constant subroutine %s undefined
  Constant subroutine (anonymous) undefined
substr outside of string at - line 4.
Attempt to use reference as lvalue in substr at - line 5.
Use of uninitialized value in ref-to-glob cast at - line 3.
Use of uninitialized value $x in scalar dereference at - line 3.
Odd number of elements in anonymous hash at - line 3.
Explicit blessing to '' (assuming package main) at - line 3.
Constant subroutine foo undefined at - line 4.
Constant subroutine (anonymous) undefined at - line 4.
     Not enough format arguments	
    Exiting substitution via %s
    Exiting subroutine via %s		
    Exiting eval via %s	
    Exiting pseudo-block via %s 
    Exiting substitution via %s
    Exiting subroutine via %s
    Exiting eval via %s
    Exiting pseudo-block via %s 
      (in cleanup) foo bar
Not enough format arguments at - line 5.
Exiting substitution via last at - line 7.
Exiting subroutine via last at - line 3.
Exiting eval via last at (eval 1) line 1.
Exiting pseudo-block via last at - line 4.
Can't "last" outside a loop block at - line 4.
Exiting substitution via last at - line 7.
Exiting subroutine via last at - line 3.
Exiting eval via last at (eval 1) line 1.
Exiting pseudo-block via last at - line 4.
Label not found for "last fred" at - line 4.
Deep recursion on subroutine "main::fred" at - line 6.
	(in cleanup) A foo bar at - line 4.
	(in cleanup) B foo bar at - line 4.
Use of uninitialized value $foo in print at (eval 1) line 1.
  print() on unopened filehandle abc		[pp_print]
  Filehandle %s opened only for input		[pp_print]
  Filehandle %s opened only for output		[pp_print]
  print() on closed filehandle %s		[pp_print]
  Reference found where even-sized list expected [pp_aassign]
  Filehandle %s opened only for output		[Perl_do_readline] 
  glob failed (can't start child: %s)		[Perl_do_readline] <<TODO
  readline() on closed filehandle %s		[Perl_do_readline]
  readline() on closed filehandle %s		[Perl_do_readline]
  glob failed (child exited with status %d%s)	[Perl_do_readline] <<TODO
  Use of reference "%s" as array index [pp_aelem]
print() on unopened filehandle abc at - line 4.
Filehandle FH opened only for input at - line 12.
Filehandle FOO opened only for input at - line 14.
Filehandle FH opened only for input at - line 19.
Filehandle FOO opened only for input at - line 20.
print() on closed filehandle STDIN at - line 4.
print() on closed filehandle STDIN at - line 6.
print() on closed filehandle at - line 7.
print() on closed filehandle $fh1 at - line 5.
print() on closed filehandle $fh2 at - line 7.
print() on closed filehandle $fh3 at - line 9.
print() on closed filehandle FH4 at - line 11.
Use of uninitialized value $a in array dereference at - line 4.
Use of uninitialized value $a in hash dereference at - line 4.
Odd number of elements in hash assignment at - line 3.
Reference found where even-sized list expected at - line 3.
readline() on closed filehandle STDIN at - line 3.
readline() on closed filehandle STDIN at - line 4.
Filehandle FH opened only for output at - line 5.
Filehandle FOO opened only for output at - line 10.
Filehandle FOO opened only for output at - line 14.
Filehandle FH opened only for output at - line 15.
    die "ok\n" if $_[0] =~ /^Deep recursion on subroutine "main::fred"/
    die "ok\n" if $_[0] =~ /^Deep recursion on subroutine "main::fred"/
Use of uninitialized value $x in concatenation (.) or string at - line 5.
Use of uninitialized value $x in concatenation (.) or string at - line 6.
Use of uninitialized value $y in concatenation (.) or string at - line 6.
Use of uninitialized value $y in concatenation (.) or string at - line 7.
Use of uninitialized value $y in concatenation (.) or string at - line 8.
Use of reference ".*" as array index at - line 4.
Use of reference ".*" as array index at - line 7.
  Attempt to pack pointer to temporary value
Invalid type ',' in unpack at - line 4.
Invalid type ',' in pack at - line 5.
Use of uninitialized value $a in scalar dereference at - line 4.
Attempt to pack pointer to temporary value at - line 4.
Explicit blessing to '' (assuming package main) at - line 3.
  untie attempted while %d inner references still exist	[pp_untie]
  fileno() on unopened filehandle abc		[pp_fileno]
  binmode() on unopened filehandle abc		[pp_binmode]
  printf() on unopened filehandle abc		[pp_prtf]
  Filehandle %s opened only for input		[pp_leavewrite]
  write() on closed filehandle %s		[pp_leavewrite]
  page overflow	 				[pp_leavewrite]
  printf() on unopened filehandle abc		[pp_prtf]
  Filehandle %s opened only for input		[pp_prtf]
  printf() on closed filehandle %s		[pp_prtf]
  syswrite() on closed filehandle %s		[pp_send]
  send() on closed socket %s			[pp_send]
  bind() on closed socket %s			[pp_bind]
  connect() on closed socket %s			[pp_connect]
  listen() on closed socket %s			[pp_listen]
  accept() on closed socket %s			[pp_accept]
  shutdown() on closed socket %s		[pp_shutdown]
  setsockopt() on closed socket %s		[pp_ssockopt]
  getsockname() on closed socket %s		[pp_getpeername]
  getpeername() on closed socket %s		[pp_getpeername]
  Filehandle %s opened only for output		[pp_sysread]
  getc() on unopened filehandle			[pp_getc]
  Non-string passed as bitmask			[pp_sselect]
untie attempted while 1 inner references still exist at - line 5.
Filehandle STDIN opened only for input at - line 5.
write() on closed filehandle STDIN at - line 6.
write() on closed filehandle STDIN at - line 8.
page overflow at - line 13.
printf() on unopened filehandle abc at - line 4.
printf() on closed filehandle STDIN at - line 4.
printf() on closed filehandle STDIN at - line 6.
Filehandle STDIN opened only for input at - line 3.
Filehandle STDIN opened only for input at - line 3.
syswrite() on closed filehandle STDIN at - line 4.
syswrite() on closed filehandle STDIN at - line 6.
flock() on closed filehandle STDIN at - line 16.
flock() on closed filehandle STDIN at - line 18.
flock() on unopened filehandle FOO at - line 19.
flock() on unopened filehandle at - line 20.
send() on closed socket STDIN at - line 22.
bind() on closed socket STDIN at - line 23.
connect() on closed socket STDIN at - line 24.
listen() on closed socket STDIN at - line 25.
accept() on closed socket STDIN at - line 26.
shutdown() on closed socket STDIN at - line 27.
setsockopt() on closed socket STDIN at - line 28.
getsockopt() on closed socket STDIN at - line 29.
getsockname() on closed socket STDIN at - line 30.
getpeername() on closed socket STDIN at - line 31.
send() on closed socket STDIN at - line 33.
bind() on closed socket STDIN at - line 34.
connect() on closed socket STDIN at - line 35.
listen() on closed socket STDIN at - line 36.
accept() on closed socket STDIN at - line 37.
shutdown() on closed socket STDIN at - line 38.
setsockopt() on closed socket STDIN at - line 39.
getsockopt() on closed socket STDIN at - line 40.
getsockname() on closed socket STDIN at - line 41.
getpeername() on closed socket STDIN at - line 42.
Unsuccessful stat on filename containing newline at - line 3.
-T on unopened filehandle HOCUS at - line 6.
stat() on unopened filehandle POCUS at - line 7.
Unsuccessful open on filename containing newline at - line 3.
Filehandle F opened only for output at - line 12.
sysread() on closed filehandle F at - line 17.
read() on closed filehandle F at - line 18.
sysread() on unopened filehandle NONEXISTENT at - line 19.
read() on unopened filehandle NONEXISTENT at - line 20.
binmode() on unopened filehandle BLARG at - line 3.
binmode() on unopened filehandle at - line 4.
lstat() on filehandle FH at - line 4.
lstat() on filehandle $fh at - line 6.
getc() on unopened filehandle FOO at - line 3.
Non-string passed as bitmask at - line 4.
chdir() on unopened filehandle FOO at - line 20.
chdir() on unopened filehandle $dh at - line 22.
  /%.127s/: Unrecognized escape \\%c passed through	[S_regatom] 
  POSIX syntax [%c %c] belongs inside character classes	[S_checkposixcc] 
  Character class syntax [%c %c] belongs inside character classes [S_checkposixcc] 
  /%.127s/: Unrecognized escape \\%c in character class passed through"	[S_regclass] 
  /%.127s/: Unrecognized escape \\%c in character class passed through"	[S_regclassutf8] 
(?=a)* matches null string many times in regex; marked by <-- HERE in m/(?=a)* <-- HERE / at - line 4.
Unrecognized escape \m passed through in regex; marked by <-- HERE in m/a\m <-- HERE / at - line 4.
Unrecognized escape \q passed through in regex; marked by <-- HERE in m/\q <-- HERE / at - line 4.
POSIX syntax [: :] belongs inside character classes in regex; marked by <-- HERE in m/[:alpha:] <-- HERE / at - line 5.
POSIX syntax [: :] belongs inside character classes in regex; marked by <-- HERE in m/[:zog:] <-- HERE / at - line 6.
POSIX syntax [. .] belongs inside character classes in regex; marked by <-- HERE in m/[.zog.] <-- HERE / at - line 5.
POSIX syntax [. .] is reserved for future extensions in regex; marked by <-- HERE in m/[.zog.] <-- HERE / at - line 5.
False [] range "a-\d" in regex; marked by <-- HERE in m/[a-\d <-- HERE ]/ at - line 5.
False [] range "\d-" in regex; marked by <-- HERE in m/[\d- <-- HERE b]/ at - line 6.
False [] range "\s-" in regex; marked by <-- HERE in m/[\s- <-- HERE \d]/ at - line 7.
False [] range "\d-" in regex; marked by <-- HERE in m/[\d- <-- HERE \s]/ at - line 8.
False [] range "a-[:digit:]" in regex; marked by <-- HERE in m/[a-[:digit:] <-- HERE ]/ at - line 9.
False [] range "[:digit:]-" in regex; marked by <-- HERE in m/[[:digit:]- <-- HERE b]/ at - line 10.
False [] range "[:alpha:]-" in regex; marked by <-- HERE in m/[[:alpha:]- <-- HERE [:digit:]]/ at - line 11.
False [] range "[:digit:]-" in regex; marked by <-- HERE in m/[[:digit:]- <-- HERE [:alpha:]]/ at - line 12.
False [] range "a-\d" in regex; marked by <-- HERE in m/[a-\d <-- HERE ]/ at - line 12.
False [] range "\d-" in regex; marked by <-- HERE in m/[\d- <-- HERE b]/ at - line 13.
False [] range "\s-" in regex; marked by <-- HERE in m/[\s- <-- HERE \d]/ at - line 14.
False [] range "\d-" in regex; marked by <-- HERE in m/[\d- <-- HERE \s]/ at - line 15.
False [] range "a-[:digit:]" in regex; marked by <-- HERE in m/[a-[:digit:] <-- HERE ]/ at - line 16.
False [] range "[:digit:]-" in regex; marked by <-- HERE in m/[[:digit:]- <-- HERE b]/ at - line 17.
False [] range "[:alpha:]-" in regex; marked by <-- HERE in m/[[:alpha:]- <-- HERE [:digit:]]/ at - line 18.
False [] range "[:digit:]-" in regex; marked by <-- HERE in m/[[:digit:]- <-- HERE [:alpha:]]/ at - line 19.
Unrecognized escape \z in character class passed through in regex; marked by <-- HERE in m/[a\z <-- HERE b]/ at - line 3.
Useless (?c) - use /gc modifier in regex; marked by <-- HERE in m/(?c <-- HERE )/ at - line 3.
Useless (?-c) - don't use /gc modifier in regex; marked by <-- HERE in m/(?-c <-- HERE )/ at - line 4.
Useless (?g) - use /g modifier in regex; marked by <-- HERE in m/(?g <-- HERE )/ at - line 5.
Useless (?-g) - don't use /g modifier in regex; marked by <-- HERE in m/(?-g <-- HERE )/ at - line 6.
Useless (?o) - use /o modifier in regex; marked by <-- HERE in m/(?o <-- HERE )/ at - line 7.
Useless (?-o) - don't use /o modifier in regex; marked by <-- HERE in m/(?-o <-- HERE )/ at - line 8.
Useless (?g) - use /g modifier in regex; marked by <-- HERE in m/(?g <-- HERE -o)/ at - line 9.
Useless (?-o) - don't use /o modifier in regex; marked by <-- HERE in m/(?g-o <-- HERE )/ at - line 9.
Useless (?g) - use /g modifier in regex; marked by <-- HERE in m/(?g <-- HERE -c)/ at - line 10.
Useless (?-c) - don't use /gc modifier in regex; marked by <-- HERE in m/(?g-c <-- HERE )/ at - line 10.
Useless (?o) - use /o modifier in regex; marked by <-- HERE in m/(?o <-- HERE -cg)/ at - line 11.
Useless (?-c) - don't use /gc modifier in regex; marked by <-- HERE in m/(?o-c <-- HERE g)/ at - line 11.
Useless (?o) - use /o modifier in regex; marked by <-- HERE in m/(?o <-- HERE gc)/ at - line 12.
Useless (?g) - use /g modifier in regex; marked by <-- HERE in m/(?og <-- HERE c)/ at - line 12.
Useless (?c) - use /gc modifier in regex; marked by <-- HERE in m/(?ogc <-- HERE )/ at - line 12.
  Complex regular subexpression recursion limit (%d) exceeded
  Complex regular subexpression recursion limit (%d) exceeded
Complex regular subexpression recursion limit (*MASKED*) exceeded at - line 9.
Complex regular subexpression recursion limit (*MASKED*) exceeded at - line 9.
        NULL OP IN RUN
  Subroutine %s redefined	
  Undefined value assigned to typeglob
  Reference is already weak			[Perl_sv_rvweaken] <<TODO
    Attempt to free non-arena SV: 0x%lx		[del_sv]
    Reference miscount in sv_replace()		[sv_replace]
    Attempt to free unreferenced scalar		[sv_free]
    Attempt to free temp prematurely: SV 0x%lx	[sv_free]
    semi-panic: attempt to dup freed string	[newSVsv]
Use of uninitialized value $a[0] in integer addition (+) at - line 4.
Use of uninitialized value $A in integer multiplication (*) at - line 10.
Use of uninitialized value $x in integer multiplication (*) at - line 4.
Use of uninitialized value $A in bitwise or (|) at - line 10.
Use of uninitialized value within @a in bitwise or (|) at - line 4.
Use of uninitialized value within @a in bitwise and (&) at - line 4.
Use of uninitialized value within @a in 1's complement (~) at - line 4.
Use of uninitialized value $x in multiplication (*) at - line 3.
Use of uninitialized value $a[0] in addition (+) at - line 3.
Use of uninitialized value $A in multiplication (*) at - line 9.
Use of uninitialized value $y in addition (+) at - line 3.
Modification of a read-only value attempted at - line 3.
Use of uninitialized value $y in scalar chop at - line 3.
Use of uninitialized value $A in concatenation (.) or string at - line 10.
Use of uninitialized value $a in join or string at - line 4.
Use of uninitialized value $a in concatenation (.) or string at - line 5.
Use of uninitialized value $a in concatenation (.) or string at - line 6.
Argument "def" isn't numeric in addition (+) at - line 6.
Argument "def" isn't numeric in addition (+) at - line 3.
Argument "def" isn't numeric in addition (+) at - line 4.
Argument "def" isn't numeric in integer addition (+) at - line 4.
Argument "def" isn't numeric in bitwise and (&) at - line 3.
Argument "def" isn't numeric in pack at - line 3.
Argument "d\0f" isn't numeric in addition (+) at - line 4.
Subroutine main::fred redefined at - line 5.
Invalid conversion in printf: "%z" at - line 4.
Invalid conversion in sprintf: "%z" at - line 5.
Invalid conversion in printf: "%\002" at - line 8.
Invalid conversion in sprintf: "%\002" at - line 9.
Undefined value assigned to typeglob at - line 3.
Argument "\x{100}\x{200}" isn't numeric in multiplication (*) at - line 3.
Argument "\x{100}\x{200}" isn't numeric in negation (-) at - line 3.
Insecure dependency in chdir while running with -T switch at - line 5.
Insecure dependency in chdir while running with -T switch at - line 5.
Insecure dependency in chdir while running with -T switch at - line 10.
Insecure dependency in chdir while running with -t switch at - line 5.
Insecure dependency in chdir while running with -t switch at - line 10.
 		Use of comma-less variable list is deprecated 
     \1 better written as $1 
     Semicolon seems to be missing
     Reversed %c= operator 
     Multidimensional syntax %.*s not supported 
     Unquoted string "abc" may clash with future reserved word at - line 3.
     Possible attempt to separate words with commas 
     Possible attempt to put comments in qw() list 
     %s (...) interpreted as function 
     Misplaced _ in number 
    Ambiguous call resolved as CORE::%s(), qualify as such or use &
    Unrecognized escape \\%c passed through
    Integer overflow in binary number
    dump() better written as CORE::dump()
    Use of /c modifier is meaningless without /g     
    Use of /c modifier is meaningless in s///
    Ambiguous use of -%s resolved as -&%s() 		[yylex]
    Precedence problem: open %.*s should be open(%.*s)	[yylex]
    Operator or semicolon missing before %c%s		[yylex]
    Ambiguous use of %c resolved as operator %c
Use of comma-less variable list is deprecated at - line 5.
Use of comma-less variable list is deprecated at - line 5.
Use of comma-less variable list is deprecated at - line 5.
Use of bare << to mean <<"" is deprecated at - line 3.
\1 better written as $1 at - line 3.
Semicolon seems to be missing at - line 3.
Reversed += operator at - line 3.
Reversed -= operator at - line 4.
Reversed *= operator at - line 5.
Reversed %= operator at - line 6.
Reversed &= operator at - line 7.
Reversed .= operator at - line 8.
Reversed ^= operator at - line 9.
Reversed |= operator at - line 10.
Reversed <= operator at - line 11.
syntax error at - line 8, near "=."
syntax error at - line 9, near "=^"
syntax error at - line 10, near "=|"
Unterminated <> operator at - line 11.
syntax error at - line 8, near "=."
syntax error at - line 9, near "=^"
syntax error at - line 10, near "=|"
Unterminated <> operator at - line 11.
Multidimensional syntax $a[1,2] not supported at - line 3.
You need to quote "fred" at - line 3.
Scalar value @a[3] better written as $a[3] at - line 3.
Scalar value @a{3} better written as $a{3} at - line 4.
Unquoted string "abc" may clash with future reserved word at - line 3.
Possible attempt to separate words with commas at - line 3.
Possible attempt to put comments in qw() list at - line 3.
print (...) interpreted as function at - line 7.
printf (...) interpreted as function at - line 4.
sort (...) interpreted as function at - line 4.
Misplaced _ in number at - line 6.
Misplaced _ in number at - line 11.
Misplaced _ in number at - line 16.
Misplaced _ in number at - line 17.
Misplaced _ in number at - line 20.
Misplaced _ in number at - line 21.
Misplaced _ in number at - line 24.
Misplaced _ in number at - line 25.
Misplaced _ in number at - line 28.
Misplaced _ in number at - line 29.
Misplaced _ in number at - line 31.
Misplaced _ in number at - line 32.
Misplaced _ in number at - line 33.
Misplaced _ in number at - line 35.
Misplaced _ in number at - line 36.
Misplaced _ in number at - line 37.
Misplaced _ in number at - line 39.
Misplaced _ in number at - line 40.
Misplaced _ in number at - line 41.
Misplaced _ in number at - line 42.
Bareword "FRED::" refers to nonexistent package at bar line 25.
Ambiguous call resolved as CORE::time(), qualify as such or use & at - line 4.
Warning: Use of "rand" without parentheses is ambiguous at - line 2.
Warning: Use of "rand" without parentheses is ambiguous at - line 3.
Warning: Use of "rand" without parentheses is ambiguous at - line 8.
Warning: Use of "rand" without parentheses is ambiguous at - line 10.
Ambiguous use of -fred resolved as -&fred() at - line 3.
Ambiguous use of -fred resolved as -&fred() at - line 4.
Ambiguous use of -fred resolved as -&fred() at - line 9.
Ambiguous use of -fred resolved as -&fred() at - line 11.
Precedence problem: open FOO should be open(FOO) at - line 2.
Precedence problem: open FOO should be open(FOO) at - line 3.
Precedence problem: open FOO should be open(FOO) at - line 8.
Precedence problem: open FOO should be open(FOO) at - line 10.
Operator or semicolon missing before *foo at - line 3.
Ambiguous use of * resolved as operator * at - line 3.
Operator or semicolon missing before *foo at - line 8.
Ambiguous use of * resolved as operator * at - line 8.
Operator or semicolon missing before *foo at - line 10.
Ambiguous use of * resolved as operator * at - line 10.
Unrecognized escape \m passed through at - line 3.
Binary number > 0b11111111111111111111111111111111 non-portable at - line 5.
Hexadecimal number > 0xffffffff non-portable at - line 8.
Octal number > 037777777777 non-portable at - line 11.
Integer overflow in binary number at - line 5.
Integer overflow in hexadecimal number at - line 8.
Integer overflow in octal number at - line 11.
dump() better written as CORE::dump() at - line 4.
- syntax OK
Possible unintended interpolation of @mjd_previously_unused_array in string at - line 3.
Use of /c modifier is meaningless without /g at - line 4.
Use of /c modifier is meaningless in s/// at - line 5.
Use of /c modifier is meaningless in s/// at - line 6.
Possible unintended interpolation of @F in string at - line 4.
Name "main::F" used only once: possible typo at - line 4.
elseif should be elsif at (eval 1) line 1.
Number found where operator expected at (eval 1) line 1, near "5 6"
	(Missing operator before  6?)
Use of :unique is deprecated at - line 4.
  Can't locate package %s for @%s::ISA	[S_isa_lookup]
Can't locate package Joe for @main::ISA at - line 5.
     Malformed UTF-16 surrogate		
Malformed UTF-8 character (unexpected non-continuation byte 0x73, immediately after start byte 0xf8) at - line 9.
Malformed UTF-8 character (unexpected non-continuation byte 0x73, immediately after start byte 0xf8) at - line 14.
UTF-16 surrogate 0xd800 at - line 3.
UTF-16 surrogate 0xdfff at - line 4.
Unicode character 0xfffe is illegal at - line 8.
Unicode character 0xffff is illegal at - line 9.
Unicode character 0x10fffe is illegal at - line 12.
Unicode character 0x10ffff is illegal at - line 13.
UTF-16 surrogate 0xd800 at - line 3.
UTF-16 surrogate 0xdfff at - line 4.
Unicode character 0xfffe is illegal at - line 8.
Unicode character 0xffff is illegal at - line 9.
Unicode character 0x10fffe is illegal at - line 12.
Unicode character 0x10ffff is illegal at - line 13.
UTF-16 surrogate 0xd800 at - line 3.
UTF-16 surrogate 0xdfff at - line 4.
Unicode character 0xfffe is illegal at - line 8.
Unicode character 0xffff is illegal at - line 9.
Unicode character 0x10fffe is illegal at - line 12.
Unicode character 0x10ffff is illegal at - line 13.
     Illegal octal digit ignored 
     Illegal binary digit ignored
     Integer overflow in binary number
     Binary number > 0b11111111111111111111111111111111 non-portable
     Integer overflow in octal number
     Octal number > 037777777777 non-portable
     Integer overflow in hexadecimal number
     Hexadecimal number > 0xffffffff non-portable
Illegal octal digit '9' ignored at - line 3.
Illegal hexadecimal digit 'v' ignored at - line 3.
Illegal binary digit '9' ignored at - line 3.
Integer overflow in binary number at - line 3.
Integer overflow in hexadecimal number at - line 3.
Integer overflow in octal number at - line 3.
Binary number > 0b11111111111111111111111111111111 non-portable at - line 5.
Hexadecimal number > 0xffffffff non-portable at - line 5.
Octal number > 037777777777 non-portable at - line 5.
Name "main::y" used only once: possible typo at - line 5.
Use of uninitialized value $y in print at - line 5.
Name "main::y" used only once: possible typo at - line 6.
Use of uninitialized value $y in print at - line 6.
Name "main::y" used only once: possible typo at - line 7.
Use of uninitialized value $y in print at - line 7.
Name "main::y" used only once: possible typo at - line 8.
Use of uninitialized value $y in print at - line 8.
Reversed += operator at - line 3.
Name "main::a" used only once: possible typo at - line 3.
Reversed += operator at - line 3.
Name "main::a" used only once: possible typo at - line 3.
Reversed += operator at - line 4.
Name "main::a" used only once: possible typo at - line 4.
Use of uninitialized value $b in scalar chop at - line 4.
Use of uninitialized value $b in scalar chop at - line 5.
Use of uninitialized value $b in scalar chop at ./abcd line 1.
Use of uninitialized value $b in scalar chop at ./abcd line 1.
Use of uninitialized value $b in scalar chop at ./abcd line 1.
Use of uninitialized value $b in scalar chop at - line 3.
Use of uninitialized value $b in scalar chop at (eval 1) line 1.
Use of uninitialized value $b in scalar chop at - line 4.
Use of uninitialized value $b in scalar chop at - line 4.
Use of uninitialized value $b in scalar chop at - line 5.
Use of uninitialized value in -e at - line 2.
Use of uninitialized value $b in scalar chop at - line 2.
Unknown warnings category 'this-should-never-be-a-warning-category' at - line 3
BEGIN failed--compilation aborted at - line 3.
Reversed += operator at - line 8.
Reversed += operator at - line 6.
Use of uninitialized value $b in scalar chop at - line 8.
Use of uninitialized value $b in scalar chop at - line 6.
Use of uninitialized value $b in scalar chop at - line 6.
Reversed += operator at - line 3.
Useless use of concatenation (.) or string in void context at - line 3.
Reversed += operator at ./abc line 2.
Use of uninitialized value $a in scalar chop at - line 3.
Reversed += operator at abc.pm line 2.
Use of uninitialized value $a in scalar chop at - line 3.
Use of uninitialized value $b in scalar chop at - line 8.
Use of uninitialized value $b in scalar chop at - line 7.
Use of uninitialized value $b in scalar chop at - line 9.
Use of uninitialized value $b in scalar chop at - line 10.
Reversed += operator at - line 8.
Reversed += operator at - line 7.
Reversed += operator at - line 9.
Reversed += operator at - line 10.
Use of uninitialized value $b in scalar chop at (eval 1) line 3.
Use of uninitialized value $b in scalar chop at (eval 1) line 2.
Use of uninitialized value $b in scalar chop at - line 9.
Use of uninitialized value $b in scalar chop at - line 10.
Reversed += operator at (eval 1) line 3.
Reversed += operator at - line 9.
Reversed += operator at (eval 1) line 2.
Reversed += operator at - line 10.
Reversed += operator at - line 6.
Use of uninitialized value $c in scalar chop at - line 9.
Use of uninitialized value $b in scalar chop at - line 6.
Use of uninitialized value $b in scalar chop at - line 6.
Use of uninitialized value $b in scalar chop at - line 6.
Use of uninitialized value $b in scalar chop at - line 6.
Use of uninitialized value $b in scalar chop at - line 5.
Use of uninitialized value $b in scalar chop at - line 6.
Use of uninitialized value $b in scalar chop at - line 6.
Use of uninitialized value $b in scalar chop at - line 6.
Use of uninitialized value $b in scalar chop at - line 10.
Use of uninitialized value $b in scalar chop at - line 7.
Use of uninitialized value $b in scalar chop at (eval 1) line 3.
Use of uninitialized value $b in scalar chop at (eval 1) line 2.
Use of uninitialized value $b in scalar chop at - line 9.
Use of uninitialized value $b in scalar chop at - line 10.
Reversed += operator at - line 5.
print() on closed filehandle STDIN at - line 6.
print() on closed filehandle STDIN at - line 4.
print() on closed filehandle STDIN at - line 5.
Reversed += operator at - line 5.
print() on closed filehandle STDIN at - line 6.
print() on closed filehandle STDIN at - line 5.
print() on closed filehandle STDIN at - line 5.
Reversed += operator at abc.pm line 4.
Use of uninitialized value $a in scalar chop at - line 3.
Reversed += operator at ./abc line 4.
Use of uninitialized value $a in scalar chop at - line 3.
Reversed += operator at abc.pm line 4.
Use of uninitialized value $a in scalar chop at - line 3.
Reversed += operator at ./abc line 3.
Use of uninitialized value $a in scalar chop at - line 3.
Use of uninitialized value $b in scalar chop at (eval 1) line 2.
Use of uninitialized value $b in scalar chop at - line 8.
Use of uninitialized value $b in scalar chop at (eval 1) line 3.
Use of uninitialized value $b in scalar chop at - line 10.
Use of uninitialized value $b in scalar chop at (eval 1) line 2.
Use of uninitialized value $b in scalar chop at - line 9.
Use of uninitialized value $b in scalar chop at (eval 1) line 3.
Use of uninitialized value $b in scalar chop at - line 10.
Reversed += operator at - line 11.
Reversed += operator at (eval 1) line 3.
Reversed += operator at - line 10.
Reversed += operator at (eval 1) line 2.
Reversed += operator at - line 11.
Reversed += operator at (eval 1) line 3.
Integer overflow in octal number at - line 3.
Integer overflow in octal number at - line 3.
Illegal octal digit '8' ignored at - line 3.
Octal number > 037777777777 non-portable at - line 3.
Integer overflow in octal number at - line 3.
Illegal octal digit '8' ignored at - line 3.
Octal number > 037777777777 non-portable at - line 3.
Integer overflow in octal number at - line 8.
Illegal octal digit '8' ignored at - line 8.
Octal number > 037777777777 non-portable at - line 8.
Integer overflow in hexadecimal number at - line 3.
Illegal hexadecimal digit 'g' ignored at - line 3.
Hexadecimal number > 0xffffffff non-portable at - line 3.
Integer overflow in binary number at - line 3.
Illegal binary digit '2' ignored at - line 3.
Binary number > 0b11111111111111111111111111111111 non-portable at - line 3.
Integer overflow in hexadecimal number at (eval 1) line 3.
Illegal hexadecimal digit 'g' ignored at (eval 1) line 3.
Hexadecimal number > 0xffffffff non-portable at (eval 1) line 3.
Integer overflow in hexadecimal number at (eval 1) line 2.
Illegal hexadecimal digit 'g' ignored at (eval 1) line 2.
Hexadecimal number > 0xffffffff non-portable at (eval 1) line 2.
Reversed += operator at - line 8.
Reversed += operator at - line 8.
Use of uninitialized value $b in scalar chop at - line 8.
Use of uninitialized value $b in scalar chop at - line 8.
Use of uninitialized value $b in scalar chop at - line 6.
Use of uninitialized value $b in scalar chop at - line 6.
Reversed += operator at ./abc line 2.
Use of uninitialized value $a in scalar chop at - line 3.
Reversed += operator at abc.pm line 2.
Use of uninitialized value $a in scalar chop at - line 3.
-- Use of uninitialized value $b in scalar chop at - line 6.
-- Use of uninitialized value $b in scalar chop at - line 5.
Use of uninitialized value $b in scalar chop at - line 7.
Use of uninitialized value $b in scalar chop at - line 8.
Reversed += operator at - line 6.
Reversed += operator at - line 5.
Reversed += operator at - line 8.
-- Use of uninitialized value $b in scalar chop at (eval 1) line 3.
-- Use of uninitialized value $b in scalar chop at (eval 1) line 2.
Use of uninitialized value $b in scalar chop at - line 7.
Use of uninitialized value $b in scalar chop at - line 8.
-- Reversed += operator at (eval 1) line 3.
-- Reversed += operator at (eval 1) line 2.
Reversed += operator at - line 8.
Useless use of time in void context at - line 4.
Useless use of length in void context at - line 8.
Useless use of time in void context at - line 4.
Useless use of length in void context at - line 8.
Use of uninitialized value $b in scalar chop at - line 8.
Use of uninitialized value $b in scalar chop at - line 11.
Use of uninitialized value $b in scalar chop at - line 8.
Use of uninitialized value $b in scalar chop at - line 11.
Use of uninitialized value $b in scalar chop at - line 7.
Useless use of length in void context at - line 4.
Useless use of length in void context at - line 4.
Useless use of length in void context at - line 5.
Use of uninitialized value $a in scalar chomp at - line 4.
Useless use of length in void context at - line 4.
Useless use of length in void context at - line 4.
Unsuccessful open on filename containing newline at - line 5.
close() on unopened filehandle fred at - line 6.
Unsuccessful open on filename containing newline at - line 5.
close() on unopened filehandle fred at - line 6.
WARN -- Reversed += operator at - line 6.
DIE -- Reversed += operator at - line 8.
Reversed += operator at - line 8.
Unknown warnings category 'fred' at - line 9
Unknown warnings category 'fred' at - line 9
Test the appearance of variable names in "Use of uninitialized value"
Use of uninitialized value $m1 in addition (+) at - line 4.
Use of uninitialized value $m2 in addition (+) at - line 5.
Use of uninitialized value $m2 in addition (+) at - line 6.
Use of uninitialized value $m1 in addition (+) at - line 6.
Use of uninitialized value $g1 in addition (+) at - line 5.
Use of uninitialized value $g2 in addition (+) at - line 6.
Use of uninitialized value $g2 in addition (+) at - line 7.
Use of uninitialized value $g1 in addition (+) at - line 7.
Use of uninitialized value $g2 in addition (+) at - line 8.
Use of uninitialized value $m1 in addition (+) at - line 8.
Use of uninitialized value $ma[5] in addition (+) at - line 4.
Use of uninitialized value $ma[6] in addition (+) at - line 5.
Use of uninitialized value $m1 in addition (+) at - line 6.
Use of uninitialized value in addition (+) at - line 6.
Use of uninitialized value in addition (+) at - line 7.
Use of uninitialized value in addition (+) at - line 7.
Use of uninitialized value in addition (+) at - line 8.
Use of uninitialized value in addition (+) at - line 8.
Use of uninitialized value $mau[5] in addition (+) at - line 6.
Use of uninitialized value $mau[-5] in addition (+) at - line 7.
Use of uninitialized value $mau[6] in addition (+) at - line 8.
Use of uninitialized value $mau[-6] in addition (+) at - line 9.
Use of uninitialized value $mau[8] in addition (+) at - line 10.
Use of uninitialized value $mau[7] in addition (+) at - line 10.
Use of uninitialized value $mau[257] in addition (+) at - line 11.
Use of uninitialized value $mau[256] in addition (+) at - line 11.
Use of uninitialized value $mau[-2] in addition (+) at - line 12.
Use of uninitialized value $mau[-1] in addition (+) at - line 12.
Use of uninitialized value $mhu{"bar"} in addition (+) at - line 13.
Use of uninitialized value $mhu{"foo"} in addition (+) at - line 13.
Use of uninitialized value $ga[8] in addition (+) at - line 5.
Use of uninitialized value $ga[-8] in addition (+) at - line 6.
Use of uninitialized value $ga[9] in addition (+) at - line 7.
Use of uninitialized value $ga[-9] in addition (+) at - line 8.
Use of uninitialized value in addition (+) at - line 9.
Use of uninitialized value in addition (+) at - line 9.
Use of uninitialized value in addition (+) at - line 10.
Use of uninitialized value in addition (+) at - line 10.
Use of uninitialized value $gau[8] in addition (+) at - line 6.
Use of uninitialized value $gau[-8] in addition (+) at - line 7.
Use of uninitialized value $gau[9] in addition (+) at - line 8.
Use of uninitialized value $gau[-9] in addition (+) at - line 9.
Use of uninitialized value $gau[11] in addition (+) at - line 10.
Use of uninitialized value $gau[10] in addition (+) at - line 10.
Use of uninitialized value $gau[257] in addition (+) at - line 11.
Use of uninitialized value $gau[256] in addition (+) at - line 11.
Use of uninitialized value $gau[-2] in addition (+) at - line 12.
Use of uninitialized value $gau[-1] in addition (+) at - line 12.
Use of uninitialized value $ghu{"bar"} in addition (+) at - line 13.
Use of uninitialized value $ghu{"foo"} in addition (+) at - line 13.
Use of uninitialized value $mau[20] in addition (+) at - line 14.
Use of uninitialized value $mau[10] in addition (+) at - line 14.
Use of uninitialized value $gau[20] in addition (+) at - line 15.
Use of uninitialized value $gau[10] in addition (+) at - line 15.
Use of uninitialized value in addition (+) at - line 16.
Use of uninitialized value $gau[10] in addition (+) at - line 16.
Use of uninitialized value $mhu{"bar"} in addition (+) at - line 17.
Use of uninitialized value $mhu{"foo"} in addition (+) at - line 17.
Use of uninitialized value $ghu{"bar"} in addition (+) at - line 18.
Use of uninitialized value $ghu{"foo"} in addition (+) at - line 18.
Use of uninitialized value in addition (+) at - line 19.
Use of uninitialized value $ghu{"foo"} in addition (+) at - line 19.
Use of uninitialized value $m1 in array element at - line 5.
Use of uninitialized value $g1 in array element at - line 6.
Use of uninitialized value $m2 in array element at - line 7.
Use of uninitialized value $g2 in array element at - line 8.
Use of uninitialized value $m1 in hash element at - line 10.
Use of uninitialized value $g1 in hash element at - line 11.
Use of uninitialized value $m2 in hash element at - line 12.
Use of uninitialized value $g2 in hash element at - line 13.
Use of uninitialized value $g1 in subtraction (-) at - line 15.
Use of uninitialized value $m2 in subtraction (-) at - line 15.
Use of uninitialized value $m1 in addition (+) at - line 15.
Use of uninitialized value $ga[3] in array element at - line 16.
Use of uninitialized value $ma[4] in array element at - line 17.
Use of uninitialized value $ga[1000] in sin at - line 5.
Use of uninitialized value $ma[1000] in sin at - line 6.
Use of uninitialized value $gh{"foo"} in sin at - line 7.
Use of uninitialized value $mh{"bar"} in sin at - line 8.
Use of uninitialized value within @ga in sin at - line 10.
Use of uninitialized value within @ma in sin at - line 11.
Use of uninitialized value within %gh in sin at - line 12.
Use of uninitialized value within %mh in sin at - line 13.
Use of uninitialized value $mat[0] in sin at - line 13.
Use of uninitialized value in addition (+) at - line 14.
Use of uninitialized value in addition (+) at - line 14.
Use of uninitialized value $mat[1000] in sin at - line 15.
Use of uninitialized value in addition (+) at - line 16.
Use of uninitialized value in addition (+) at - line 16.
Use of uninitialized value within @mat in sin at - line 18.
Use of uninitialized value in addition (+) at - line 19.
Use of uninitialized value in addition (+) at - line 19.
Use of uninitialized value $mht{"foo"} in sin at - line 21.
Use of uninitialized value in addition (+) at - line 22.
Use of uninitialized value in addition (+) at - line 22.
Use of uninitialized value within %mht in sin at - line 24.
Use of uninitialized value in addition (+) at - line 25.
Use of uninitialized value in addition (+) at - line 25.
Use of uninitialized value $1 in addition (+) at - line 27.
Use of uninitialized value $ga[1000] in print at - line 5.
Use of uninitialized value $ga[1000] in print at - line 6.
Use of uninitialized value $m1 in print at - line 7.
Use of uninitialized value $g1 in print at - line 7.
Use of uninitialized value in print at - line 7.
Use of uninitialized value $m2 in print at - line 7.
Use of uninitialized value $ga[1] in print at - line 8.
Use of uninitialized value $m1 in ref-to-glob cast at - line 5.
Use of uninitialized value $g1 in ref-to-glob cast at - line 6.
Use of uninitialized value $m1 in scalar dereference at - line 5.
Use of uninitialized value $g1 in scalar dereference at - line 6.
Use of uninitialized value $m1 in array dereference at - line 8.
Use of uninitialized value $g1 in array dereference at - line 9.
Use of uninitialized value $m2 in hash dereference at - line 10.
Use of uninitialized value $g2 in hash dereference at - line 11.
Use of uninitialized value in addition (+) at - line 13.
Use of uninitialized value $m1 in concatenation (.) or string at - line 14.
Use of uninitialized value in addition (+) at - line 14.
Use of uninitialized value $g1 in concatenation (.) or string at - line 15.
Use of uninitialized value in addition (+) at - line 15.
Use of uninitialized value $m1 in bitwise or (|) at - line 5.
Use of uninitialized value $m2 in bitwise or (|) at - line 5.
Use of uninitialized value $m1 in bitwise and (&) at - line 6.
Use of uninitialized value $m2 in bitwise and (&) at - line 6.
Use of uninitialized value $m1 in bitwise xor (^) at - line 7.
Use of uninitialized value $m2 in bitwise xor (^) at - line 7.
Use of uninitialized value $m1 in 1's complement (~) at - line 8.
Use of uninitialized value $g1 in bitwise or (|) at - line 10.
Use of uninitialized value $g2 in bitwise or (|) at - line 10.
Use of uninitialized value $g1 in bitwise and (&) at - line 11.
Use of uninitialized value $g2 in bitwise and (&) at - line 11.
Use of uninitialized value $g1 in bitwise xor (^) at - line 12.
Use of uninitialized value $g2 in bitwise xor (^) at - line 12.
Use of uninitialized value $g1 in 1's complement (~) at - line 13.
Use of uninitialized value $s1 in scalar chomp at - line 3.
Use of uninitialized value $s2 in scalar chop at - line 4.
Use of uninitialized value $s4 in chomp at - line 5.
Use of uninitialized value $s3 in chomp at - line 5.
Use of uninitialized value $s5 in chop at - line 6.
Use of uninitialized value $s6 in chop at - line 6.
Use of uninitialized value ${$/} in scalar chomp at - line 6.
Use of uninitialized value ${$/} in chomp at - line 8.
Use of uninitialized value $y in chomp at - line 8.
Use of uninitialized value ${$/} in chomp at - line 8.
Use of uninitialized value $y in chop at - line 8.
Use of uninitialized value $m1 in delete at - line 5.
Use of uninitialized value $m1 in delete at - line 6.
Use of uninitialized value $g1 in delete at - line 6.
Use of uninitialized value $m1 in delete at - line 7.
Use of uninitialized value $m1 in delete at - line 8.
Use of uninitialized value $g1 in delete at - line 8.
Use of uninitialized value $m1 in array slice at - line 5.
Use of uninitialized value $g1 in array slice at - line 5.
Use of uninitialized value $m1 in list slice at - line 6.
Use of uninitialized value $g1 in list slice at - line 6.
Use of uninitialized value $m1 in hash slice at - line 7.
Use of uninitialized value $g1 in hash slice at - line 7.
Use of uninitialized value $m1 in exists at - line 5.
Use of uninitialized value $g1 in exists at - line 6.
Use of uninitialized value $m1 in exists at - line 7.
Use of uninitialized value $g1 in exists at - line 8.
Use of uninitialized value $m1 in left bitshift (<<) at - line 6.
Use of uninitialized value $x1 in left bitshift (<<) at - line 6.
Use of uninitialized value $g1 in left bitshift (<<) at - line 7.
Use of uninitialized value $x2 in left bitshift (<<) at - line 7.
Use of uninitialized value $g1 in integer addition (+) at - line 6.
Use of uninitialized value $m1 in integer addition (+) at - line 6.
Use of uninitialized value $g1 in integer subtraction (-) at - line 7.
Use of uninitialized value $m1 in integer subtraction (-) at - line 7.
Use of uninitialized value $g1 in integer multiplication (*) at - line 8.
Use of uninitialized value $m1 in integer multiplication (*) at - line 8.
Use of uninitialized value $g1 in integer division (/) at - line 9.
Use of uninitialized value $m2 in integer division (/) at - line 10.
Use of uninitialized value $g1 in integer modulus (%) at - line 11.
Use of uninitialized value $m1 in integer modulus (%) at - line 11.
Use of uninitialized value $m2 in integer modulus (%) at - line 12.
Use of uninitialized value $g1 in integer lt (<) at - line 13.
Use of uninitialized value $m1 in integer lt (<) at - line 13.
Use of uninitialized value $g1 in integer gt (>) at - line 14.
Use of uninitialized value $m1 in integer gt (>) at - line 14.
Use of uninitialized value $g1 in integer le (<=) at - line 15.
Use of uninitialized value $m1 in integer le (<=) at - line 15.
Use of uninitialized value $g1 in integer ge (>=) at - line 16.
Use of uninitialized value $m1 in integer ge (>=) at - line 16.
Use of uninitialized value $g1 in integer eq (==) at - line 17.
Use of uninitialized value $m1 in integer eq (==) at - line 17.
Use of uninitialized value $g1 in integer ne (!=) at - line 18.
Use of uninitialized value $m1 in integer ne (!=) at - line 18.
Use of uninitialized value $g1 in integer comparison (<=>) at - line 19.
Use of uninitialized value $m1 in integer comparison (<=>) at - line 19.
Use of uninitialized value $m1 in integer negation (-) at - line 20.
Use of uninitialized value $g1 in int at - line 5.
Use of uninitialized value $g2 in abs at - line 6.
Use of uninitialized value $m1 in pack at - line 5.
Use of uninitialized value $m2 in pack at - line 6.
Use of uninitialized value $g1 in pack at - line 6.
Use of uninitialized value $g2 in pack at - line 6.
Use of uninitialized value $m1 in unpack at - line 7.
Use of uninitialized value $m2 in unpack at - line 7.
Use of uninitialized value $m1 in sort at - line 6.
Use of uninitialized value $g1 in sort at - line 6.
Use of uninitialized value $m1 in sort at - line 6.
Use of uninitialized value $g1 in sort at - line 6.
Use of uninitialized value $m1 in sort at - line 7.
Use of uninitialized value $g1 in sort at - line 7.
Use of uninitialized value $m1 in sort at - line 7.
Use of uninitialized value $g1 in sort at - line 7.
Use of uninitialized value $a in subtraction (-) at - line 8.
Use of uninitialized value $b in subtraction (-) at - line 8.
Use of uninitialized value $m1 in sort at - line 9.
Use of uninitialized value $g1 in sort at - line 9.
Use of uninitialized value $m1 in sort at - line 9.
Use of uninitialized value $m1 in sort at - line 9.
Use of uninitialized value $g1 in sort at - line 9.
Use of uninitialized value $g1 in sort at - line 9.
Use of uninitialized value $g1 in division (/) at - line 5.
Use of uninitialized value $m1 in division (/) at - line 5.
Use of uninitialized value $m2 in division (/) at - line 6.
Use of uninitialized value $g1 in modulus (%) at - line 7.
Use of uninitialized value $m1 in modulus (%) at - line 7.
Use of uninitialized value $m2 in modulus (%) at - line 8.
Use of uninitialized value $g1 in numeric eq (==) at - line 9.
Use of uninitialized value $m1 in numeric eq (==) at - line 9.
Use of uninitialized value $g1 in numeric ge (>=) at - line 10.
Use of uninitialized value $m1 in numeric ge (>=) at - line 10.
Use of uninitialized value $g1 in numeric gt (>) at - line 11.
Use of uninitialized value $m1 in numeric gt (>) at - line 11.
Use of uninitialized value $g1 in numeric le (<=) at - line 12.
Use of uninitialized value $m1 in numeric le (<=) at - line 12.
Use of uninitialized value $g1 in numeric lt (<) at - line 13.
Use of uninitialized value $m1 in numeric lt (<) at - line 13.
Use of uninitialized value $g1 in multiplication (*) at - line 14.
Use of uninitialized value $m1 in multiplication (*) at - line 14.
Use of uninitialized value $g1 in numeric comparison (<=>) at - line 15.
Use of uninitialized value $m1 in numeric comparison (<=>) at - line 15.
Use of uninitialized value $g1 in numeric ne (!=) at - line 16.
Use of uninitialized value $m1 in numeric ne (!=) at - line 16.
Use of uninitialized value $g1 in subtraction (-) at - line 17.
Use of uninitialized value $m1 in subtraction (-) at - line 17.
Use of uninitialized value $g1 in exponentiation (**) at - line 18.
Use of uninitialized value $m1 in exponentiation (**) at - line 18.
Use of uninitialized value $g1 in addition (+) at - line 19.
Use of uninitialized value $m1 in addition (+) at - line 19.
Use of uninitialized value $g1 in subtraction (-) at - line 20.
Use of uninitialized value $m1 in subtraction (-) at - line 20.
Use of uninitialized value $m1 in glob elem at - line 5.
Use of uninitialized value $g1 in subroutine prototype at - line 6.
Use of uninitialized value $g1 in bless at - line 7.
Use of uninitialized value $m1 in quoted execution (``, qx) at - line 8.
Use of uninitialized value $m1 in concatenation (.) or string at - line 10.
Use of uninitialized value $g1 in concatenation (.) or string at - line 10.
Use of uninitialized value $_ in pattern match (m//) at - line 5.
Use of uninitialized value $m1 in regexp compilation at - line 6.
Use of uninitialized value $_ in pattern match (m//) at - line 6.
Use of uninitialized value $g1 in regexp compilation at - line 7.
Use of uninitialized value $_ in pattern match (m//) at - line 7.
Use of uninitialized value $_ in substitution (s///) at - line 9.
Use of uninitialized value $m1 in regexp compilation at - line 10.
Use of uninitialized value $_ in substitution (s///) at - line 10.
Use of uninitialized value $_ in substitution (s///) at - line 10.
Use of uninitialized value $_ in substitution (s///) at - line 11.
Use of uninitialized value $g1 in substitution (s///) at - line 11.
Use of uninitialized value $_ in substitution (s///) at - line 11.
Use of uninitialized value $g1 in substitution (s///) at - line 11.
Use of uninitialized value $m1 in regexp compilation at - line 12.
Use of uninitialized value $_ in substitution (s///) at - line 12.
Use of uninitialized value $_ in substitution (s///) at - line 12.
Use of uninitialized value $g1 in substitution iterator at - line 12.
Use of uninitialized value $_ in transliteration (tr///) at - line 13.
Use of uninitialized value $_ in pattern match (m//) at - line 16.
Use of uninitialized value $m1 in regexp compilation at - line 17.
Use of uninitialized value $_ in pattern match (m//) at - line 17.
Use of uninitialized value $g1 in regexp compilation at - line 18.
Use of uninitialized value $_ in pattern match (m//) at - line 18.
Use of uninitialized value $_ in substitution (s///) at - line 19.
Use of uninitialized value $m1 in regexp compilation at - line 20.
Use of uninitialized value $_ in substitution (s///) at - line 20.
Use of uninitialized value $_ in substitution (s///) at - line 20.
Use of uninitialized value $_ in substitution (s///) at - line 21.
Use of uninitialized value $g1 in substitution (s///) at - line 21.
Use of uninitialized value $_ in substitution (s///) at - line 21.
Use of uninitialized value $g1 in substitution (s///) at - line 21.
Use of uninitialized value $m1 in regexp compilation at - line 22.
Use of uninitialized value $_ in substitution (s///) at - line 22.
Use of uninitialized value $_ in substitution (s///) at - line 22.
Use of uninitialized value $g1 in substitution iterator at - line 22.
Use of uninitialized value $_ in transliteration (tr///) at - line 23.
Use of uninitialized value $g2 in pattern match (m//) at - line 25.
Use of uninitialized value $m1 in regexp compilation at - line 26.
Use of uninitialized value $g2 in pattern match (m//) at - line 26.
Use of uninitialized value $g1 in regexp compilation at - line 27.
Use of uninitialized value $g2 in pattern match (m//) at - line 27.
Use of uninitialized value $g2 in substitution (s///) at - line 28.
Use of uninitialized value $m1 in regexp compilation at - line 29.
Use of uninitialized value $g2 in substitution (s///) at - line 29.
Use of uninitialized value $g2 in substitution (s///) at - line 29.
Use of uninitialized value $g2 in substitution (s///) at - line 30.
Use of uninitialized value $g1 in substitution (s///) at - line 30.
Use of uninitialized value $g2 in substitution (s///) at - line 30.
Use of uninitialized value $g1 in substitution (s///) at - line 30.
Use of uninitialized value $m1 in regexp compilation at - line 31.
Use of uninitialized value $g2 in substitution (s///) at - line 31.
Use of uninitialized value $g2 in substitution (s///) at - line 31.
Use of uninitialized value $g1 in substitution iterator at - line 31.
Use of uninitialized value in transliteration (tr///) at - line 32.
Use of uninitialized value $m1 in regexp compilation at - line 35.
Use of uninitialized value $g1 in regexp compilation at - line 36.
Use of uninitialized value $m1 in regexp compilation at - line 38.
Use of uninitialized value $g1 in substitution (s///) at - line 39.
Use of uninitialized value $m1 in regexp compilation at - line 40.
Use of uninitialized value $g1 in substitution iterator at - line 40.
Use of uninitialized value $m1 in substitution iterator at - line 41.
Use of uninitialized value $m1 in list assignment at - line 4.
Use of uninitialized value $_ in study at - line 4.
Use of uninitialized value $g1 in study at - line 5.
Use of uninitialized value $_ in scalar assignment at - line 4.
Use of uninitialized value $m1 in scalar assignment at - line 5.
Use of uninitialized value in addition (+) at - line 5.
Use of uninitialized value in addition (+) at - line 6.
Use of uninitialized value in addition (+) at - line 9.
Use of uninitialized value in addition (+) at - line 10.
Use of uninitialized value $m1 in repeat (x) at - line 4.
Use of uninitialized value $m1 in repeat (x) at - line 5.
Use of uninitialized value $m1 in string at - line 5.
Use of uninitialized value $m1 in string lt at - line 7.
Use of uninitialized value $g1 in string lt at - line 7.
Use of uninitialized value $m1 in string le at - line 8.
Use of uninitialized value $g1 in string le at - line 8.
Use of uninitialized value $m1 in string gt at - line 9.
Use of uninitialized value $g1 in string gt at - line 9.
Use of uninitialized value $m1 in string ge at - line 10.
Use of uninitialized value $g1 in string ge at - line 10.
Use of uninitialized value $m1 in string eq at - line 11.
Use of uninitialized value $g1 in string eq at - line 11.
Use of uninitialized value $m1 in string ne at - line 12.
Use of uninitialized value $g1 in string ne at - line 12.
Use of uninitialized value $m1 in string comparison (cmp) at - line 13.
Use of uninitialized value $g1 in string comparison (cmp) at - line 13.
Use of uninitialized value $g1 in atan2 at - line 5.
Use of uninitialized value $m1 in atan2 at - line 5.
Use of uninitialized value $m1 in sin at - line 6.
Use of uninitialized value $m1 in cos at - line 7.
Use of uninitialized value $m1 in rand at - line 8.
Use of uninitialized value $m1 in srand at - line 9.
Use of uninitialized value $m1 in exp at - line 10.
Use of uninitialized value $m1 in log at - line 11.
Use of uninitialized value $m1 in sqrt at - line 12.
Use of uninitialized value $m1 in hex at - line 13.
Use of uninitialized value $m1 in oct at - line 14.
Use of uninitialized value $m1 in length at - line 15.
Use of uninitialized value $_ in length at - line 16.
Use of uninitialized value $g1 in substr at - line 5.
Use of uninitialized value $m1 in substr at - line 5.
Use of uninitialized value $m2 in substr at - line 6.
Use of uninitialized value $g1 in substr at - line 6.
Use of uninitialized value $m1 in substr at - line 6.
Use of uninitialized value $g2 in substr at - line 7.
Use of uninitialized value $m2 in substr at - line 7.
Use of uninitialized value $g1 in substr at - line 7.
Use of uninitialized value $m1 in substr at - line 7.
Use of uninitialized value $m1 in substr at - line 7.
Use of uninitialized value $g1 in substr at - line 8.
Use of uninitialized value $m1 in substr at - line 8.
Use of uninitialized value in scalar assignment at - line 8.
Use of uninitialized value $m2 in substr at - line 9.
Use of uninitialized value $g1 in substr at - line 9.
Use of uninitialized value $m1 in substr at - line 9.
Use of uninitialized value in scalar assignment at - line 9.
Use of uninitialized value $m2 in vec at - line 11.
Use of uninitialized value $g1 in vec at - line 11.
Use of uninitialized value $m1 in vec at - line 11.
Use of uninitialized value $m2 in vec at - line 12.
Use of uninitialized value $g1 in vec at - line 12.
Use of uninitialized value $m1 in vec at - line 12.
Use of uninitialized value $m1 in index at - line 14.
Use of uninitialized value $m2 in index at - line 14.
Use of uninitialized value $g1 in index at - line 15.
Use of uninitialized value $m1 in index at - line 15.
Use of uninitialized value $m2 in index at - line 15.
Use of uninitialized value $m1 in rindex at - line 16.
Use of uninitialized value $m2 in rindex at - line 16.
Use of uninitialized value $g1 in rindex at - line 17.
Use of uninitialized value $m1 in rindex at - line 17.
Use of uninitialized value $m2 in rindex at - line 17.
Use of uninitialized value $m1 in sprintf at - line 5.
Use of uninitialized value $m1 in sprintf at - line 6.
Use of uninitialized value $m2 in sprintf at - line 6.
Use of uninitialized value $g1 in sprintf at - line 6.
Use of uninitialized value $g2 in sprintf at - line 6.
Use of uninitialized value $m3 in formline at - line 7.
Use of uninitialized value $m1 in formline at - line 8.
Use of uninitialized value $m2 in formline at - line 8.
Use of uninitialized value $g1 in formline at - line 8.
Use of uninitialized value $g2 in formline at - line 8.
Use of uninitialized value $m1 in crypt at - line 5.
Use of uninitialized value $g1 in crypt at - line 5.
Use of uninitialized value $_ in ord at - line 7.
Use of uninitialized value $m1 in ord at - line 8.
Use of uninitialized value $_ in chr at - line 9.
Use of uninitialized value $m1 in chr at - line 10.
Use of uninitialized value $_ in quotemeta at - line 22.
Use of uninitialized value $m1 in quotemeta at - line 23.
Use of uninitialized value $_ in split at - line 5.
Use of uninitialized value $m1 in regexp compilation at - line 6.
Use of uninitialized value $_ in split at - line 6.
Use of uninitialized value $m1 in regexp compilation at - line 7.
Use of uninitialized value $m2 in split at - line 7.
Use of uninitialized value $m1 in regexp compilation at - line 8.
Use of uninitialized value $g1 in split at - line 8.
Use of uninitialized value $m2 in split at - line 8.
Use of uninitialized value $m1 in join or string at - line 10.
Use of uninitialized value $m1 in join or string at - line 11.
Use of uninitialized value $m2 in join or string at - line 11.
Use of uninitialized value $m1 in join or string at - line 12.
Use of uninitialized value $m2 in join or string at - line 12.
Use of uninitialized value $m3 in join or string at - line 12.
Use of uninitialized value $foo1[1] in chomp at - line 4.
Use of uninitialized value $foo2[1] in chomp at - line 5.
Use of uninitialized value $foo3[1] in chop at - line 6.
Use of uninitialized value $foo4[1] in chop at - line 7.
Use of uninitialized value $foo5[1] in sprintf at - line 8.
Use of uninitialized value $foo6[1] in sprintf at - line 9.
Use of uninitialized value $foo7{"baz"} in sprintf at - line 10.
Use of uninitialized value $foo8{"baz"} in sprintf at - line 11.
Use of uninitialized value $m1 in sprintf at - line 12.
Use of uninitialized value $foo9[1] in sprintf at - line 12.
Use of uninitialized value in sprintf at - line 12.
Use of uninitialized value $m2 in sprintf at - line 13.
Use of uninitialized value $foo10[1] in sprintf at - line 13.
Use of uninitialized value in sprintf at - line 13.
Use of uninitialized value $foo11{"baz"} in join or string at - line 14.
Use of uninitialized value $foo12{"baz"} in join or string at - line 15.
Use of uninitialized value within %foo13 in join or string at - line 16.
Use of uninitialized value within %foo14 in join or string at - line 17.
Use of uninitialized value $^FOO in addition (+) at - line 4.
Use of uninitialized value $^A in addition (+) at - line 4.
Use of uninitialized value $GLOB1 in addition (+) at - line 6.
Use of uninitialized value $GLOB2 in addition (+) at - line 7.
Use of uninitialized value $h{"\0011\2\r\n\t\f\"\\abcdefghijklm"...} in join or string at - line 6.
Use of uninitialized value $m1 in subroutine dereference at - line 5.
Use of uninitialized value $m1 in subroutine dereference at - line 5.
Use of uninitialized value $g1 in subroutine dereference at - line 6.
Use of uninitialized value $g1 in subroutine dereference at - line 6.
Use of uninitialized value $m1 in splice at - line 9.
Use of uninitialized value $g1 in splice at - line 9.
Use of uninitialized value $m1 in splice at - line 10.
Use of uninitialized value $g1 in splice at - line 10.
Use of uninitialized value in addition (+) at - line 10.
Use of uninitialized value $m1 in method lookup at - line 13.
Use of uninitialized value in subroutine entry at - line 15.
Use of uninitialized value in subroutine entry at - line 16.
Use of uninitialized value $m1 in warn at - line 18.
Use of uninitialized value $g1 in warn at - line 18.
Use of uninitialized value $m1 in die at - line 20.
Use of uninitialized value $g1 in die at - line 20.
Use of uninitialized value $m1 in symbol reset at - line 22.
Use of uninitialized value $g1 in symbol reset at - line 23.
Use of uninitialized value $FOO in open at - line 5.
Use of uninitialized value in open at - line 7.
Use of uninitialized value in open at - line 8.
Use of uninitialized value in open at - line 9.
Use of uninitialized value $m1 in open at - line 11.
Use of uninitialized value $m1 in open at - line 12.
Use of uninitialized value $g1 in open at - line 13.
Use of uninitialized value $m2 in sysopen at - line 15.
Use of uninitialized value $m1 in sysopen at - line 15.
Use of uninitialized value $m2 in sysopen at - line 16.
Use of uninitialized value $g1 in sysopen at - line 16.
Use of uninitialized value $m1 in sysopen at - line 16.
Use of uninitialized value $m1 in umask at - line 19.
Use of uninitialized value $g1 in umask at - line 20.
Use of uninitialized value $m1 in binmode at - line 23.
Use of uninitialized value $m1 in binmode at - line 23.
Use of uninitialized value $m1 in tie at - line 5.
Use of uninitialized value $m1 in tie at - line 5.
Use of uninitialized value $m1 in ref-to-glob cast at - line 7.
Use of uninitialized value $g1 in read at - line 7.
Use of uninitialized value $m1 in ref-to-glob cast at - line 8.
Use of uninitialized value $g1 in read at - line 8.
Use of uninitialized value $g2 in read at - line 8.
Use of uninitialized value $m1 in ref-to-glob cast at - line 9.
Use of uninitialized value $g1 in sysread at - line 9.
Use of uninitialized value $m1 in ref-to-glob cast at - line 10.
Use of uninitialized value $g1 in sysread at - line 10.
Use of uninitialized value $g2 in sysread at - line 10.
Use of uninitialized value $m1 in printf at - line 5.
Use of uninitialized value $m1 in printf at - line 6.
Use of uninitialized value $m2 in printf at - line 6.
Use of uninitialized value $g1 in printf at - line 6.
Use of uninitialized value $g2 in printf at - line 6.
Use of uninitialized value $ga[1000] in printf at - line 7.
Use of uninitialized value $ga[1000] in printf at - line 8.
Use of uninitialized value $m1 in printf at - line 9.
Use of uninitialized value $g1 in printf at - line 9.
Use of uninitialized value in printf at - line 9.
Use of uninitialized value $m2 in printf at - line 9.
Use of uninitialized value $ga[1] in printf at - line 10.
Use of uninitialized value $x in ref-to-glob cast at - line 5.
Use of uninitialized value $g1 in seek at - line 5.
Use of uninitialized value $m1 in seek at - line 5.
Use of uninitialized value $x in ref-to-glob cast at - line 6.
Use of uninitialized value $g1 in sysseek at - line 6.
Use of uninitialized value $m1 in sysseek at - line 6.
Use of uninitialized value $m1 in ref-to-glob cast at - line 7.
Use of uninitialized value $m2 in socket at - line 11.
Use of uninitialized value $g1 in socket at - line 11.
Use of uninitialized value $m1 in socket at - line 11.
Use of uninitialized value $m2 in socketpair at - line 12.
Use of uninitialized value $g1 in socketpair at - line 12.
Use of uninitialized value $m1 in socketpair at - line 12.
Use of uninitialized value $x in ref-to-glob cast at - line 16.
Use of uninitialized value $g1 in flock at - line 16.
Use of uninitialized value $_ in stat at - line 5.
Use of uninitialized value $_ in lstat at - line 6.
Use of uninitialized value $m1 in stat at - line 7.
Use of uninitialized value $g1 in lstat at - line 8.
Use of uninitialized value $m1 in -R at - line 10.
Use of uninitialized value $m1 in -W at - line 11.
Use of uninitialized value $m1 in -X at - line 12.
Use of uninitialized value $m1 in -r at - line 13.
Use of uninitialized value $m1 in -w at - line 14.
Use of uninitialized value $m1 in -x at - line 15.
Use of uninitialized value $m1 in -e at - line 16.
Use of uninitialized value $m1 in -o at - line 17.
Use of uninitialized value $m1 in -O at - line 18.
Use of uninitialized value $m1 in -z at - line 19.
Use of uninitialized value $m1 in -s at - line 20.
Use of uninitialized value $m1 in -M at - line 21.
Use of uninitialized value $m1 in -A at - line 22.
Use of uninitialized value $m1 in -C at - line 23.
Use of uninitialized value $m1 in -S at - line 24.
Use of uninitialized value $m1 in -c at - line 25.
Use of uninitialized value $m1 in -b at - line 26.
Use of uninitialized value $m1 in -f at - line 27.
Use of uninitialized value $m1 in -d at - line 28.
Use of uninitialized value $m1 in -p at - line 29.
Use of uninitialized value $m1 in -l at - line 30.
Use of uninitialized value $m1 in -l at - line 30.
Use of uninitialized value $m1 in -u at - line 31.
Use of uninitialized value $m1 in -g at - line 32.
Use of uninitialized value $m1 in -t at - line 34.
Use of uninitialized value $m1 in -T at - line 35.
Use of uninitialized value $m1 in -B at - line 36.
Use of uninitialized value $m1 in localtime at - line 5.
Use of uninitialized value $g1 in gmtime at - line 6.
Use of uninitialized value $_ in eval "string" at - line 4.
Use of uninitialized value $m1 in eval "string" at - line 5.
Use of uninitialized value $m1 in exit at - line 4.
  Can't open bidirectional pipe		[Perl_do_open9]
  Missing command in piped open		[Perl_do_open9]
  Missing command in piped open		[Perl_do_open9]
  close() on unopened filehandle %s	[Perl_do_close]
  Use of -l on filehandle %s		[Perl_my_lstat]
  Can't exec \"%s\": %s 		[Perl_do_aexec5]
  Can't exec \"%s\": %s 		[Perl_do_exec3]
  Filehandle %s opened only for output	[Perl_do_eof]
  Can't do inplace edit: %s is not a regular file	[Perl_nextargv]
  Can't do inplace edit: %s would not be unique		[Perl_nextargv]
  Can't rename %s to %s: %s, skipping file		[Perl_nextargv]
  Can't rename %s to %s: %s, skipping file		[Perl_nextargv]
  Can't remove %s: %s, skipping file			[Perl_nextargv]
  Can't do inplace edit on %s: %s			[Perl_nextargv]
Can't open bidirectional pipe at - line 3.
Missing command in piped open at - line 3.
Missing command in piped open at - line 3.
Unsuccessful open on filename containing newline at - line 3.
close() on unopened filehandle fred at - line 3.
tell() on unopened filehandle at - line 10.
seek() on unopened filehandle at - line 11.
sysseek() on unopened filehandle at - line 12.
Use of uninitialized value $a in print at - line 3.
Unsuccessful stat on filename containing newline at - line 3.
Unsuccessful stat on filename containing newline at - line 4.
Use of -l on filehandle STDIN at - line 3.
Use of -l on filehandle $fh at - line 6.
Can't exec "lskdjfalksdjfdjfkls": .+
Can't exec "lskdjfalksdjfdjfkls(:? abc)?": .+
Can't do inplace edit: ./temp.dir is not a regular file at - line 9.
Can't do inplace edit: ./temp.dir is not a regular file at - line 21.
Filehandle STDOUT opened only for output at - line 3.
Can't open a reference at - line 14.
Filehandle STDOUT reopened as FH1 only for input at - line 14.
Filehandle STDIN reopened as $fh1 only for output at - line 14.
     Can't locate package %s for @%s::ISA
     Use of inherited AUTOLOAD for non-method %s::%.*s() is deprecated
    Had to create %s unexpectedly		[gv_fetchpv]
    Attempt to free unreferenced glob pointers	[gp_free]
Can't locate package Fred for @main::ISA at - line 3.
Undefined subroutine &main::joe called at - line 3.
Undefined subroutine &main::joe called at - line 3.
Use of inherited AUTOLOAD for non-method main::fred() is deprecated at - line 5.
    %s", "Bad free() ignored	[Perl_mfree]
  No such signal: SIG%s
No such signal: SIGFRED at - line 3.
SIGINT handler "fred" not defined.
Use of uninitialized value $3 in length at - line 4.
Use of uninitialized value $3 in length at - line 3.
     Found = in conditional, should be ==
     Use of implicit split to @_ is deprecated
     Use of implicit split to @_ is deprecated
     Useless use of time in void context
     Useless use of a variable in void context
     Useless use of a constant in void context
     Useless use of sort in scalar context
     Applying %s to %s will act on scalar(%s)
     Parentheses missing around "my" list at -e line 1.
     Parentheses missing around "local" list at -e line 1.
     Bareword found in conditional at -e line 1.
     Subroutine fred redefined at -e line 1.
     Constant subroutine %s redefined 
     Format FRED redefined at /tmp/x line 5.
     Array @%s missing the @ in argument %d of %s() 
     Statement unlikely to be reached
     defined(@array) is deprecated
     defined(%hash) is deprecated
     /---/ should probably be written as "---"
    %s() called too early to check prototype		[Perl_peep]
    Use of /g modifier is meaningless in split
    Possible precedence problem on bitwise %c operator	[Perl_ck_bitop]
    oops: oopsAV		[oopsAV]	TODO
    oops: oopsHV		[oopsHV]	TODO
Found = in conditional, should be == at - line 3.
Use of implicit split to @_ is deprecated at - line 3.
Use of implicit split to @_ is deprecated at - line 3.
Using a hash as a reference is deprecated at - line 4.
Using a hash as a reference is deprecated at - line 5.
Using an array as a reference is deprecated at - line 6.
Using an array as a reference is deprecated at - line 7.
Using a hash as a reference is deprecated at - line 8.
Using a hash as a reference is deprecated at - line 9.
Using an array as a reference is deprecated at - line 10.
Using an array as a reference is deprecated at - line 11.
Useless use of repeat (x) in void context at - line 3.
Useless use of wantarray in void context at - line 5.
Useless use of reference-type operator in void context at - line 12.
Useless use of reference constructor in void context at - line 13.
Useless use of single ref constructor in void context at - line 14.
Useless use of defined operator in void context at - line 15.
Useless use of hex in void context at - line 16.
Useless use of oct in void context at - line 17.
Useless use of length in void context at - line 18.
Useless use of substr in void context at - line 19.
Useless use of vec in void context at - line 20.
Useless use of index in void context at - line 21.
Useless use of rindex in void context at - line 22.
Useless use of sprintf in void context at - line 23.
Useless use of array element in void context at - line 24.
Useless use of array slice in void context at - line 26.
Useless use of hash element in void context at - line 29.
Useless use of hash slice in void context at - line 30.
Useless use of unpack in void context at - line 31.
Useless use of pack in void context at - line 32.
Useless use of join or string in void context at - line 33.
Useless use of list slice in void context at - line 34.
Useless use of sort in void context at - line 37.
Useless use of reverse in void context at - line 38.
Useless use of range (or flop) in void context at - line 41.
Useless use of caller in void context at - line 42.
Useless use of fileno in void context at - line 43.
Useless use of eof in void context at - line 44.
Useless use of tell in void context at - line 45.
Useless use of readlink in void context at - line 46.
Useless use of time in void context at - line 47.
Useless use of localtime in void context at - line 48.
Useless use of gmtime in void context at - line 49.
Useless use of getgrnam in void context at - line 50.
Useless use of getgrgid in void context at - line 51.
Useless use of getpwnam in void context at - line 52.
Useless use of getpwuid in void context at - line 53.
Useless use of subroutine prototype in void context at - line 54.
Useless use of sort in scalar context at - line 3.
Useless use of string in void context at - line 3.
Useless use of telldir in void context at - line 13.
Useless use of getppid in void context at - line 13.
Useless use of getpgrp in void context at - line 13.
Useless use of times in void context at - line 13.
Useless use of getpriority in void context at - line 13.
Useless use of getlogin in void context at - line 13.
Useless use of getsockname in void context at - line 24.
Useless use of getpeername in void context at - line 25.
Useless use of gethostbyname in void context at - line 26.
Useless use of gethostbyaddr in void context at - line 27.
Useless use of gethostent in void context at - line 28.
Useless use of getnetbyname in void context at - line 29.
Useless use of getnetbyaddr in void context at - line 30.
Useless use of getnetent in void context at - line 31.
Useless use of getprotobyname in void context at - line 32.
Useless use of getprotobynumber in void context at - line 33.
Useless use of getprotoent in void context at - line 34.
Useless use of getservbyname in void context at - line 35.
Useless use of getservbyport in void context at - line 36.
Useless use of getservent in void context at - line 37.
Useless use of a variable in void context at - line 3.
Useless use of a variable in void context at - line 4.
Useless use of a variable in void context at - line 5.
Useless use of a variable in void context at - line 6.
Useless use of a constant in void context at - line 3.
Useless use of a constant in void context at - line 4.
Applying pattern match (m//) to @array will act on scalar(@array) at - line 5.
Applying substitution (s///) to @array will act on scalar(@array) at - line 6.
Applying transliteration (tr///) to @array will act on scalar(@array) at - line 7.
Applying pattern match (m//) to @array will act on scalar(@array) at - line 8.
Applying substitution (s///) to @array will act on scalar(@array) at - line 9.
Applying transliteration (tr///) to @array will act on scalar(@array) at - line 10.
Applying pattern match (m//) to %hash will act on scalar(%hash) at - line 11.
Applying substitution (s///) to %hash will act on scalar(%hash) at - line 12.
Applying transliteration (tr///) to %hash will act on scalar(%hash) at - line 13.
Applying pattern match (m//) to %hash will act on scalar(%hash) at - line 14.
Applying substitution (s///) to %hash will act on scalar(%hash) at - line 15.
Applying transliteration (tr///) to %hash will act on scalar(%hash) at - line 16.
Can't modify private array in substitution (s///) at - line 6, near "s/a/b/ ;"
BEGIN not safe after errors--compilation aborted at - line 18.
Parentheses missing around "my" list at - line 3.
Parentheses missing around "my" list at - line 4.
Parentheses missing around "our" list at - line 3.
Parentheses missing around "local" list at - line 3.
Parentheses missing around "local" list at - line 4.
Bareword found in conditional at - line 3.
Value of <HANDLE> construct can be "0"; test with defined() at - line 4.
Value of readdir() operator can be "0"; test with defined() at - line 4.
Value of glob construct can be "0"; test with defined() at - line 3.
Value of each() operator can be "0"; test with defined() at - line 4.
Value of glob construct can be "0"; test with defined() at - line 3.
Value of readdir() operator can be "0"; test with defined() at - line 4.
Subroutine fred redefined at - line 4.
Constant subroutine fred redefined at - line 4.
Constant subroutine fred redefined at - line 4.
Constant subroutine main::fred redefined at - line 4.
Format FRED redefined at - line 5.
Array @FRED missing the @ in argument 1 of push() at - line 3.
Hash %FRED missing the % in argument 1 of keys() at - line 3.
Statement unlikely to be reached at - line 13.
defined(@array) is deprecated at - line 3.
defined(@array) is deprecated at - line 3.
defined(%hash) is deprecated at - line 3.
Prototype mismatch: sub main::fred () vs ($) at - line 3.
Prototype mismatch: sub main::fred () vs ($) at - line 4.
Prototype mismatch: sub main::freD () vs ($) at - line 11.
Prototype mismatch: sub main::FRED () vs ($) at - line 14.
/---/ should probably be written as "---" at - line 3.
main::fred() called too early to check prototype at - line 3.
Too late to run CHECK block at abc.pm line 3.
Too late to run INIT block at abc.pm line 4.
Too late to run CHECK block at abc.pm line 3.
Too late to run INIT block at abc.pm line 4.
Useless use of push with no values at - line 4.
Useless use of unshift with no values at - line 5.
Use of /g modifier is meaningless in split at - line 4.
Possible precedence problem on bitwise & operator at - line 3.
Possible precedence problem on bitwise ^ operator at - line 4.
Possible precedence problem on bitwise | operator at - line 5.
Possible precedence problem on bitwise & operator at - line 6.
Possible precedence problem on bitwise ^ operator at - line 7.
Possible precedence problem on bitwise | operator at - line 8.
Possible precedence problem on bitwise & operator at - line 9.
Possible precedence problem on bitwise & operator at - line 4.
Possible precedence problem on bitwise ^ operator at - line 5.
Possible precedence problem on bitwise | operator at - line 6.
Possible precedence problem on bitwise & operator at - line 7.
Possible precedence problem on bitwise ^ operator at - line 8.
Possible precedence problem on bitwise | operator at - line 9.
Possible precedence problem on bitwise & operator at - line 10.
