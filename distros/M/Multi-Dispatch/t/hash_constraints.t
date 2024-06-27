use v5.22;
use warnings;
use Test::More;

BEGIN {
    if (!eval {require Types::Standard}) {
        plan skip_all => 'Test required Types::Standard module';
        exit;
    }
    else {
        plan tests => 8;
        Types::Standard->import(':all');
    }
}

use Multi::Dispatch;

multi foo({
    w => Str $w =~ /w/ :where({length($w) == 3}),
    x => Num $x = 1.1,
    y =>     $y        :where(/Y/),
    z =>     $z > 0
}) {
    ok $w eq 'www' || $w eq 'vwx' => 'w correct'; 
    ok $x == 24.24 || $x == 1.1   => 'x correct';
    is $y, 'YYY'                  => 'y correct';
    ok $z > 0                     => 'z correct';
}

foo {z=>1,   y=>'YYY', x=>24.24, w=>'www'};
foo {z=>9.9, y=>'YYY',           w=>'vwx'};

done_testing();

