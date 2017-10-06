use Test2::V0;
use Types::Standard -all;
use Smart::Args::TypeTiny;

{
    package MyClass;
    sub new { bless {} }
}

sub foo {
    args my $x => ArrayRef[Int];
    return $x;
}

sub bar {
    args my $x => 'MyClass';
    return $x;
}

is foo(x => [10]), [10];
isa_ok bar(x => MyClass->new()), 'MyClass';

like dies {
	foo(x => {foo => 42});
}, qr/Type check failed in binding to parameter '\$x'; Reference \{"foo" => 42\} did not pass type constraint "ArrayRef\[Int\]"/;

like dies {
	foo(x => [3.14]);
}, qr/Type check failed in binding to parameter '\$x'; Reference \["3\.14"\] did not pass type constraint "ArrayRef\[Int\]"/;

like dies {
	foo(x => bless {}, 'Foo');
}, qr/Type check failed in binding to parameter '\$x'; Reference bless\( \{\}, 'Foo' \) did not pass type constraint "ArrayRef\[Int\]"/;

done_testing;
