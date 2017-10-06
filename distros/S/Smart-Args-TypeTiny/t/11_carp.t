use Test2::V0;
use Types::Standard -all;
use Smart::Args::TypeTiny;

sub foo {
    args my $x => Num, my $y => Num;
}

sub bar {
    args_pos my $x => Num, my $y => Num;
}

my $file = quotemeta __FILE__;

like dies { foo(x => 1, y => 2, z => 3) }, qr/Unexpected parameter 'z' passed at $file line 6/;
like dies { foo(x => 1) }, qr/Required parameter 'y' not passed at $file line 6/;
like dies { foo(x => 1, y => 'foo') }, qr/Type check failed in binding to parameter '\$y'; Value "foo" did not pass type constraint "Num" at $file line 6/;

like dies { bar(1, 2, 3) }, qr/Too many parameters passed at $file line 10/;
like dies { bar(1) }, qr/Required parameter 'y' not passed at $file line 10/;
like dies { bar(1, 'foo') }, qr/Type check failed in binding to parameter '\$y'; Value "foo" did not pass type constraint "Num" at $file line 10/;

done_testing;
