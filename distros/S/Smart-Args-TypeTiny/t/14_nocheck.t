use Test2::V0;
use Types::Standard -all;
use Smart::Args::TypeTiny;

{
    no warnings 'redefine';
    *Smart::Args::TypeTiny::check_rule = \&Smart::Args::TypeTiny::Check::no_check_rule;
}

sub foo {
    args my $x => Int;
    return $x;
}

sub bar {
    args my $x => { isa => Str, default => 'bar!' };
    return $x;
}

sub baz {
    args my $x => { isa => Int, optional => 1 };
    return $x;
}

is foo(x => 1), 1;
is foo(x => 'A'), 'A';
is foo(x => []), [];
like dies { foo() }, qr/Required parameter 'x' not passed/, 'Required parameter not passed';

is bar(x => 1), 1;
is bar(x => 'A'), 'A';
is bar(x => []), [];
is bar(), 'bar!', 'Default value';

is baz(x => 1), 1;
is baz(x => 'A'), 'A';
is baz(x => []), [];
is baz(), undef, 'Optional parameter not passed';

done_testing;
