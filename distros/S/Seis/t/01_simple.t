use strict;
use warnings;
use utf8;
use Test::More;
use Seis;
use Seis::Bool;

sub true()  { !!1 }
sub false() { !!0 }

my @result = (
    '4649' => 4649,
    '3+2' => 5,
    '3-2' => 1,
    '3*2' => 6,
    '4/2' => 2,
    '"hoge"' => 'hoge',
    '"a\n\tb"' => "a\n\tb",
    '1 ?? 2 !! 3' => 2,
    '4**8' => 65536,
    '8%3' => 2,
    '[1,2,3]' => [1,2,3],
    '4==5' => false,
    '4==4' => true,
    '4==5 ?? 1 !! 0' => 0,
    '5==5 ?? 1 !! 0' => 1,
    '4!=5' => true,
    '4!=4' => false,
    '4<5' => true,
    '5<5' => false,
    '5<6' => true,
    '4>5' => false,
    '5>5' => false,
    '6>5' => true,
    '4>=5' => false,
    '5>=5' => true,
    '6>=5' => true,
    '4<=5' => true,
    '5<=5' => true,
    '6<=5' => false,
    'my $i=0; $i' => 0,
    'my $i=0; $i++' => 0,
    'my $i=0; $i++; $i' => 1,
    'my $i=0; ++$i' => 1,
    'my $i=0; ++$i; $i' => 1,
    'my $i=0; $i--' => 0,
    'my $i=0; $i--; $i' => -1,
    'my $i=0; --$i' => -1,
    'my $i=0; --$i; $i' => -1,
    '"hoge"~"fuga"' => 'hogefuga',
    '"hoge"~"fuga"~"moge"' => 'hogefugamoge',
    'my @a=1,2,3; @a[1]' => 2,
    'my @a=1,2,3; @a.pop' => 3,
    'my %a =( "a" => 2, "b" => 4); %a<a>' => 2,
    'my %a =( "a" => 2, "b" => 4); %a<a>' => 2,
    '3 && 2' => 2,
    '0 && 2' => 0,
    '3 || 2' => 3,
    '0 || 2' => 2,
    '3 ^^ 2' => false,
    '0 ^^ 2' => 2,
    '2 ^^ 0' => 2,
    '0 ^^ 0' => false,
    '(-> $n { $n*2 })(3)' => 6,
    '"hoge{3+2}"' => 'hoge5',
    '775 +| 1' => 775,
    '775 +& 1' => 1,
    '775 +^ 1' => 774,
    '{ 3 }' => 3,
    'my $i=0; for 1,2,3 { $i+=$_ }; $i ' => 6,
    'my $i=0; for 1,2,3 -> $x { $i+=$x }; $i' => 6,
    'my $i=3; while $i-- { }; $i' => -1,
    'my $a =[ 5,9,6,3]; $a[2]' => 6,
    'use Time::Piece; 1' => 1,
    'class Foo1 { }; 1' => 1,
    'class Foo2 { method bar() { } }; 1' => 1,
    'class Foo3 { method bar() { 3 } }; Foo3.bar' => 3,
    'class Foo4 { method bar() { 3 } }; Foo4.new.bar' => 3,
    'class Foo5 { method bar($n) { $n*3 } }; Foo5.new.bar(4)' => 12,
    'sub x($n) { $n*2 }; x(3)' => 6,
    'sub yy($n) { return $n*2 }; yy(3)' => 6,
    '(1..3)[2]' => 3,
    'my $i=0; my $y=[4,9,3]; for @$y -> $x { $i+=$x }; $i' => 16,
    '$*OUT' => *STDOUT,
    '$*ERR' => *STDERR,
    '3.14' => 3.14,
    'if 1 { 5 } else { 4 }' => 5,
    'my $n=0; if 1 { $n=9; } $n' => 9,
    'my $n=0; if 0 { $n=9; } else { $n=8 } $n' => 8,
    'my $n=0; if 0 { $n=9; } elsif 1 { $n= 4 } else { $n=8 } $n' => 4,
    'my $n=0; unless 0 { $n=9; } $n' => 9,
    'my $n=0; unless 1 { $n=9; } $n' => 0,
    '[{a => 1, b => 2}.keys]' => ['a', 'b'],
    '"a" eq "b"' => false,
    '"a" eq "a"' => true,
    '"a" ne "b"' => true,
    '"a" ne "a"' => false,
    'my $i=4; $i+=4; $i' => 8,
    'my $i=4; $i-=2; $i' => 2,
    '"x" x 3' => 'xxx',
    '+3' => +3,
    '-(3)' => -3,
    '3+<2' => 12,
    '256+>1' => 128,
    'my $n="a"; $n~="b";$n' => 'ab',
    '?1' => Bool::True,
    '?0' => Bool::False,
    '[(class { }).^methods]' => [],
    '[(class { method foo() { } }).^methods]' => ['foo'],
    'my $i=0; for 1..10 { $i+=$_; last if $_==5}; $i' => 15,
    '!1' => Bool::False,
    'sub add($x, $y) { $x+$y } add(4,3)' => 7,
    'class Foo6 { method bar() { $?CLASS } }; Foo6.bar' => Seis::MetaClass->new(name => 'Foo6'),
    'class Foo7 { method bar() { 5963 } };  class Foo8 is Foo7 { } Foo8.bar' => 5963,
    '(6,7,8).elems' => 3,
    '1 < 2 < 2 or "hoge"' => 'hoge',
    'class {  }; 1' => 1,
    q{my $b=3; 'x $b'} => 'x $b',
    q{my @a="a".."e"; @a[0]} => 'a',
    # 'my $i=0;for 1,2,3 { $i+=$_; last if $_==2 }; $i ' => 3.14,
);

for (my $i=0; $i<@result; $i+=2) {
    my $code     = $result[$i];
    my $expected = $result[$i+1];

    my $compiler = Seis::Compiler->new();
    my $compiled = $compiler->compile($code);
    note 'code: ' . $code;
    note 'compiled: ' .  $compiled;
    my $result = eval $compiled;
    ok !$@ or do {
        diag $code;
        diag $@;
    };
    is_deeply($result, $expected) or do {
        eval { diag(Perl6::PVIP->new->parse_string($code)->as_sexp) };
        diag $code;
    };
    warn $@ if $@;
}

done_testing;

