use strict;
use warnings;

use Config;
BEGIN {
    if (! $Config{useithreads} || $] < 5.008) {
        print("1..0 # Skip Threads not supported\n");
        exit(0);
    }
}


use threads;
use threads::shared;

if ($] == 5.008) {
    require 't/test.pl';   # Test::More work-alike for Perl 5.8.0
} else {
    require Test::More;
}
Test::More->import();
plan('tests' => 4);


package My::Obj; {
    use Object::InsideOut ':SHARED';

    my @s :Field :All(s);
    my @a :Field :All(a);
    my @h :Field :All(h);
    my @r :Field :All(r);
}

package main;

MAIN:
{
    my $s = \do{ my $anon = 321; };
    my $a = [ 1..3, [ qw(foo bar) ], { 'qux' => 99 } ];
    my $h = { 'foo' => [ 99..101 ], 'bar' => { 'bork' => 5 } };
    my $x = [ $s, $h, $a ];
    my $y = \$x;
    my $z = \$y;
    my $r = \$z;

    my $obj = My::Obj->new(
        's' => $s,
        'a' => $a,
        'h' => $h,
        'r' => $r,
    );

    threads->create(sub {
            is_deeply($obj->s(), $s, 'scalar');
            is_deeply($obj->a(), $a, 'array');
            is_deeply($obj->h(), $h, 'hash');
            my $ii = $obj->r();
            is_deeply($$$$ii, $$$$r, 'ref');
        })->join();
}

exit(0);

# EOF
