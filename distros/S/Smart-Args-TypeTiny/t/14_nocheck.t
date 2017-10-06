use Test2::V0;
use Types::Standard -all;
use Smart::Args::TypeTiny;

{
    no warnings 'redefine';
    sub Smart::Args::TypeTiny::check_rule {
        my ($rule, $value, $exists, $name) = @_;
        return $value;
    }
}

sub foo {
    Smart::Args::TypeTiny::args(my $x => Int);
    return $x;
}

is foo(x => 1), 1;
is foo(x => 'A'), 'A';
is foo(x => []), [];

done_testing;
