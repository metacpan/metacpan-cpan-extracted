use strict;
use warnings;

use Test::More tests => 5;
use File::Spec;

# Test common options and prototypes
use System::Sub [ 0 => $^X, ARGV => [ File::Spec->catfile(qw(t print.pl)) ] ],
                qw< print1($) print2($$) >,
                printenv => [
                    ENV  => { Toto => 'Lulu' },
                    '--' => File::Spec->catfile(qw(t printenv.pl)), 'Toto'
                ];

is(  scalar print1('x'),   'x', 'print1 (scalar)');
is_deeply([ print1('y') ], [ 'y' ], 'print1 (list)');

is(  scalar print2('x', 'y'),   'x',           'print2 (scalar)');
is_deeply([ print2('x', 'y') ], [ qw< x y > ], 'print2 (list)');

is_deeply([ printenv ], [ 'Lulu' ], 'printenv Toto');

# vim:set et sw=4 sts=4:
