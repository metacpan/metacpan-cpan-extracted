use strict;
use Test::More tests => 3;
use Config;

my @fibs;

unlink 't/.fib.pl.pl';

my $path_sep = $Config{path_sep} || ':';

for (1 .. 5) {
    local $ENV{PERL5LIB} = join $path_sep, @INC;
    push @fibs, `$^X t/fib.pl`;
}

is_deeply \@fibs, [ 1, 1, 2, 3, 5 ];

for (1 .. 5) {
    local $ENV{PERL5LIB} = join $path_sep, @INC;
    push @fibs, `$^X t/fib.pl`;
}

is_deeply \@fibs, [ 1, 1, 2, 3, 5, 8, 13, 21, 34, 55 ];

ok -e 't/.fib.pl.pl';

unlink 't/.fib.pl.pl';
