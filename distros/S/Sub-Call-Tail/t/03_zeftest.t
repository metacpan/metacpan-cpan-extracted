use warnings;
use strict;

use Test::More 0.88;

$SIG{__WARN__} = sub { fail "WARNING: $_[0]" };

BEGIN { use_ok "Sub::Call::Tail", qw(tail); }

our @activity;

sub t0r { [ "r0", @_, "r1" ] }
sub t0a {
    my $a = $_[0]+2;
    tail t0r($a+3, 17);
    return "x";
}
is_deeply t0a(100), [ "r0", 105, 17, "r1" ];

sub t1r { [ "r0", @_, "r1" ] }
sub t1a {
    if($_[0]) {
        tail t1r("x");
    } else {
        tail t1r("y");
    }
}
is_deeply t1a(0), [ "r0", "y", "r1" ];
is_deeply t1a(1), [ "r0", "x", "r1" ];

sub t2r {
    push @activity, [
        wantarray ? "ARRAY" : defined(wantarray) ? "SCALAR" : "VOID",
        @_,
    ];
    return "z", "zz";
}
sub t2a {
    tail t2r("x", @_, "y");
}
sub t2b {
    push @activity, "wibble";
    tail t2r("x", @_, "y");
    push @activity, "wobble";
}
@activity = ();
t2a(1,2,3);
is_deeply \@activity, [[ "VOID", "x", 1, 2, 3, "y" ]];
@activity = ();
is_deeply [ scalar t2a(1,2,3) ], [ "zz" ];
is_deeply \@activity, [[ "SCALAR", "x", 1, 2, 3, "y" ]];
@activity = ();
is_deeply [ t2a(1,2,3) ], [ "z", "zz" ];
is_deeply \@activity, [[ "ARRAY", "x", 1, 2, 3, "y" ]];
@activity = ();
t2b(1,2,3);
is_deeply \@activity, [ "wibble", [ "VOID", "x", 1, 2, 3, "y" ] ];
@activity = ();
is_deeply [ scalar t2b(1,2,3) ], [ "zz" ];
is_deeply \@activity, [ "wibble", [ "SCALAR", "x", 1, 2, 3, "y" ] ];
@activity = ();
is_deeply [ t2b(1,2,3) ], [ "z", "zz" ];
is_deeply \@activity, [ "wibble", [ "ARRAY", "x", 1, 2, 3, "y" ] ];

our @t3l = qw(x y z);
sub t3rs($) { [@_] }
sub t3ra(@) { [@_] }
sub t3rn { [@_] }
sub t3as { tail t3rs(@t3l) }
sub t3aa { tail t3ra(@t3l) }
sub t3an { tail t3rn(@t3l) }
is_deeply t3as(), [3];
is_deeply t3aa(), [qw(x y z)];
is_deeply t3an(), [qw(x y z)];

sub t4r(&) { $_[0]->(123) }
sub t4a { tail t4r { [ "x", @_ ] } }
is_deeply t4a(), [ "x", 123 ];

sub t5r { [ "t5r", @_ ] }
sub t5a {
    my $a = $_[0] ? tail(t5r(123)) : 2;
    return $a + 10;
}
is_deeply t5a(0), 12;
is_deeply t5a(1), [ "t5r", 123 ];

sub t6c { push @activity, "t6c"; }
sub t6d { push @activity, "t6d"; }
sub t6r { push @activity, "t6r"; return 123; }
sub t6a { [ t6c(), tail(t6r()), t6d() ] }
@activity = ();
is_deeply t6a(), 123;
is_deeply \@activity, [ "t6c", "t6r" ];

sub t7r { [ "r0", @_, "r1" ] }
sub t7a {
    tail &t0r("x", @_, "y");
    return "x";
}
sub t7b {
    tail &t0r();
    return "x";
}
sub t7c {
    tail &t0r;
    return "x";
}
is_deeply t7a("a"), [ "r0", "x", "a", "y", "r1" ];
is_deeply t7b("a"), [ "r0", "r1" ];
is_deeply t7c("a"), [ "r0", "a", "r1" ];

done_testing();

1;
