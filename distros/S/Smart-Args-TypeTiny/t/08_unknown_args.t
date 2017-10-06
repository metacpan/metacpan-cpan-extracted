use Test2::V0;
use Types::Standard -all;
use Smart::Args::TypeTiny;

sub foo {
    args my $x => Num, my $y => Num;
}

sub bar {
    args_pos my $x => Num, my $y => Num;
}

like dies { foo(x => 1, y => 2, qux => 30) },
    qr/Unexpected parameter 'qux' passed/;

like dies { foo(bbb => 3, aaa => 4, x => 1, y => 2) },
    qr/Unexpected parameter 'aaa' passed/;

like dies { bar(1, 2, 30) },
    qr/Too many parameters passed/;

done_testing;
