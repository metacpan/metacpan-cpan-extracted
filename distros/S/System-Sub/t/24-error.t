use strict;
use warnings;

use Test::More tests => 8;
use File::Spec;

use System::Sub exiterr => [
    0 => $^X,
    ARGV => [ File::Spec->catfile(qw(t exiterr.pl)) ],
    '()' => '$',
    '&?' => sub {
        my ($name, $code, $cmd) = @_;
        is($name, 'exiterr', 'name');
        is($cmd->[0], $^X, '$cmd[0]');
        is($?, $code, '$code == $?');
        is($? >> 8, $cmd->[2]);
    },
];

exiterr 4;
exiterr 5;

# vim:set et sw=4 sts=4:
