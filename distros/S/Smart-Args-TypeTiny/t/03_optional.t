use Test2::V0;
use Types::Standard -all;
use Smart::Args::TypeTiny;

sub foo {
    args my $p => { isa => Int },
         my $q => { isa => Int, optional => 1 };
    return $q ? $q : $p;
}

sub bar {
    args_pos my $p => { isa => Int, },
             my $q => { isa => Int, optional => 1 };
    return $q ? $q : $p;
}

is foo(p => 3, q => 2), 2;
is foo(p => 3), 3;
is foo(p => 3, q => undef), 3;
like dies { foo(q => 2) }, qr/Required parameter 'p' not passed/;

is bar(3, 2), 2;
is bar(3), 3;
is bar(3, undef), 3;
like dies { bar() }, qr/Required parameter 'p' not passed/;

done_testing;
