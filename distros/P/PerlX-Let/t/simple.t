#!perl

use Test::Most;

use PerlX::Let;

my $x = 3;

is $x => 3, 'global';

{

    let $x = 1;

    is $x => 1, 'scope';

    dies_ok { $x++ } 'read-only';

    {
        let $x = 2;
        is $x => 2, 'inner scope';
    };

};

# deprecated syntax

let $x = 1 {

    is $x => 1, 'scope';

    dies_ok { $x++ } 'read-only';

    let $x = 2 {
        is $x => 2, 'inner scope';
    };

};

for (1..3) {
    let $x = 'string' {
        is $x => 'string', 'in loop';
        dies_ok { $x .= 'y' } 'read-only';

    }
}


let @x = (1,2),
    %y = ( a => 1, b => 2),
    $z = 3 {

        is $y{a} => $x[0], 'multiple symbols';
        is $y{b} => $x[1];
        is $x[0] + $x[1] => $z;

        dies_ok { $y{a}+= 1 } 'read-only';
        dies_ok { $x[0]+= 1 } 'read-only';
        dies_ok { $z++ } 'read-only';

};

foreach my $i (2..3) {

    my $obj = { this => { that => $i } };
    let $x = $obj->{this}{that} {

        is $x => $i, 'assigned to expression';

    }

}

subtest 'syntax errors' => sub {

    eval 'let =';
    like $@, qr/A variable name is required for let/, 'missing variable name';

    eval 'let x';
    like $@, qr/A variable name is required for let/, 'missing variable name';

    eval 'let $x';
    like $@, qr/An assignment is required for let/, 'missing assignment';

    eval 'let $x 1';
    like $@, qr/An assignment is required for let/, 'missing assignment';

    {
        no warnings;

        eval 'let $x => ';
        ok $@, 'syntax error';

      TODO: {
          local $TODO = "This error is identified elsewhere";
          like $@, qr/A value is required for let/, 'missing value';
        }

    }


};

no PerlX::Let;

done_testing;
