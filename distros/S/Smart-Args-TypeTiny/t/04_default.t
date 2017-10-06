use Test2::V0;
use Types::Standard -all;
use Smart::Args::TypeTiny;

sub foo {
    args my $p => { isa => Int, default => 99 };
    return $p;
}

sub bar {
    args_pos my $p => { isa => Int, default => 99 };
    return $p;
}

is foo(), 99;
is foo(p => 0), 0;

is bar(), 99;
is bar(0), 0;

done_testing;
