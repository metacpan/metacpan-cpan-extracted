use Test2::V0;
use Types::Standard -all;
use Smart::Args::TypeTiny;

sub foo {
    args my $pi;
    return $pi;
}

sub bar {
    args_pos my $pi;
    return $pi;
}

is foo(pi => 3.14), 3.14;

my $args = {pi => 3.14};
is foo($args), 3.14;
is $args, {pi => 3.14};

is bar(3.14), 3.14;

done_testing;
