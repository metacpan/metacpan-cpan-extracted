#!perl

use 5.010;
use strict;
use warnings;

BEGIN {
    use Test::More 0.96;
    use Perinci::Sub::Util qw(caller);
    eval "use Perinci::Sub::Wrapper qw(wrap_sub)";
    plan skip_all => 'Perinci::Sub::Wrapper needed for this test' if $@;
}

our %SPEC;

$SPEC{foo} = {
    v => 1.1,
};
sub foo {
    [200, "OK",
     [[caller(0)], [caller(1)], [caller(2)]]];
}

$SPEC{bar} = {
    v => 1.1,
};
sub bar {
    foow();
}

my $res = wrap_sub(sub=>\&foo, meta=>$SPEC{foo});
die "Can't wrap: $res->[0] - $res->[1]" unless $res->[0] == 200;
*foow = $res->[2]{sub};

$res = bar();
my $c0 = $res->[2][0];
my $c1 = $res->[2][1];
my $c2 = $res->[2][2];
is("$c0->[0]:$c0->[2]", "main:28");
is("$c1->[0]:$c1->[2]", "main:35");
ok(!@$c2);

$res = wrap_sub(sub=>\&foo, meta=>$SPEC{foo}, trap=>0);
die "Can't wrap: $res->[0] - $res->[1]" unless $res->[0] == 200;
{ no warnings 'redefine'; *foow = $res->[2]{sub}; }

$res = bar();
$c0 = $res->[2][0];
$c1 = $res->[2][1];
$c2 = $res->[2][2];
is("$c0->[0]:$c0->[2]", "main:28");
is("$c1->[0]:$c1->[2]", "main:47");
ok(!@$c2);

done_testing();
