
BEGIN {
    use FindBin qw($Bin);
    require "$Bin/test.pl";
    plan(tests => 23);
}

use Regexp::Fields;

#
# sanity check
#

$rx = qr/(?<a>.)(?<b>.)(?<c>.)/;

ok !defined($&{a}),   '!defined($&{a})';
ok !defined($&{x}),   '!defined($&{x})';

ok "abc" =~ /$rx/,    "'abc' =~ /$rx/";
ok keys %{&} == 3,    'keys %{&} == 3';
is $1, 'a',           '$1 eq "a"';
is $2, 'b',           '$2 eq "b"';
is $3, 'c',           '$3 eq "c"';
is $&{a}, $1,         '$&{a} eq $1';
is $&{b}, $2,         '$&{b} eq $2';
is $&{c}, $3,         '$&{c} eq $3';

#
# nested captures
#

$rx = qr/(?<all> (?<a>.)(?<b>.)(?<c>.))/x;

ok "abc" =~ /$rx/,    "'abc' =~ /$rx/";
ok keys %{&} == 4,    'keys %{&} == 4';
is $1, 'abc',         '$1 eq "abc"';
is $2, 'a',           '$2 eq "a"';
is $3, 'b',           '$3 eq "b"';
is $4, 'c',           '$4 eq "c"';
is $&{all}, $1,       '$&{all} eq $1';
is $&{a}, $2,         '$&{a} eq $2';
is $&{b}, $3,         '$&{b} eq $3';
is $&{c}, $4,         '$&{c} eq $4';

#
# oblique modifications
#
{
    no warnings;
    $&{a} + 0;
    $&{b} | 0;
    $&{c} ^ 0;
}

is $&{a}, 'a',  '$&{a} eq "a" [after addition]'; 
is $&{b}, 'b',  '$&{b} eq "b" [after bitwise OR]';
is $&{c}, 'c',  '$&{c} eq "c" [after bitwise AND]';
