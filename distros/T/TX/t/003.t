use strict;
use warnings;
use Test::More qw/tests 7/;
#use Test::More qw/no_plan/;
use TX;

my $tmpl={filename=>'//tmpl', template=><<'EOF'};
[% define m1 %]
  [m1]G=[%$G{x}%], V=[%$V{x}%], L=[%$L{x}%][/m1]
[% /define %]

[% define m2 %]
  [m2]
    G=[%$G{x}%], V=[%$V{x}%], L=[%$L{x}%]
    [%$G{x}++; $V{x}++; $L{x}++; include '#m1', x=>1000; ''%]
    G=[%$G{x}%], V=[%$V{x}%], L=[%$L{x}%]
    [%$G{x}++; $V{x}++; $L{x}++; include '#m1', {VMODE=>'keep'}, x=>1000; ''%]
    G=[%$G{x}%], V=[%$V{x}%], L=[%$L{x}%]
  [/m2]
[% /define %]

[%$G{x}=$L{x}=10;''%]G=[%$G{x}%], V=[%$V{x}%], L=[%$L{x}%]
[%$G{x}++; $V{x}++; $L{x}++; include '#m2', x=>100; ''%]
G=[%$G{x}%], V=[%$V{x}%], L=[%$L{x}%]
[%$G{x}++; $V{x}++; $L{x}++; include '#m2', {VMODE=>'keep'}, x=>100; ''%]
G=[%$G{x}%], V=[%$V{x}%], L=[%$L{x}%]
EOF

my $T=TX->new(delimiters=>[qw/[% %]/],
	      path=>[qw!t/tmpl!],
	      evalcache=>1,
	      output=>'');

#warn $T->include( $tmpl, x=>10 );

$TX::TX=15;			# check it later

is $T->include( $tmpl, x=>10 ), <<'EOF', '%V, %G, %L';
G=10, V=10, L=10
  [m2]
    G=11, V=100, L=
      [m1]G=12, V=1000, L=[/m1]

    G=12, V=101, L=1
      [m1]G=13, V=102, L=[/m1]

    G=13, V=102, L=2
  [/m2]

G=13, V=11, L=11
  [m2]
    G=14, V=12, L=
      [m1]G=15, V=1000, L=[/m1]

    G=15, V=13, L=1
      [m1]G=16, V=14, L=[/m1]

    G=16, V=14, L=2
  [/m2]

G=16, V=14, L=12
EOF

is_deeply $T->G, {x=>16}, '$T->G result';
cmp_ok $TX::TX, '==', 15, '$TX::TX has not changed';

$T->G=\my %G;
$T->include( $tmpl, x=>10 );
cmp_ok $T->G, '!=', \%G, '$T->G has been replaced by an anonymous hash';
is_deeply \%G, {}, 'pass in $T->G';

$T->preserve_G=1;
$T->G=\%G;
$G{mark}=42;
$T->include( $tmpl, x=>10 );
cmp_ok $T->G, '==', \%G, '$T->G has not changed';
is_deeply \%G, {mark=>42, x=>16}, 'pass data in and out via $T->G';

# Local Variables:
# mode: cperl
# End:
