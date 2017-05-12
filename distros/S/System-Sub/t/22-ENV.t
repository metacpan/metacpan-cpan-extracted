use strict;
use warnings;

use Test::More tests => 2;
use File::Spec;

use System::Sub printenv => [ 0 => $^X,
                              ARGV => [ File::Spec->catfile(qw(t printenv.pl)) ],
                              ENV => {
                                Toto => 'Titi',
                                Lala => 'Lulu'
                              },
                            ];

is(scalar printenv('Toto'), 'Titi', 'scalar context');
is_deeply([ printenv(qw(Toto Lala)) ], [ qw(Titi Lulu) ], 'list context');

# vim:set et sw=4 sts=4:
