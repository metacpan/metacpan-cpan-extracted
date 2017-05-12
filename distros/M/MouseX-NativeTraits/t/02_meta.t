#!perl -w

use strict;
use Test::More;
use Test::Fatal;

use Any::Moose;

is exception {
    has foo => (
        traits  => [qw(Array)],
        default => sub{ [] },
        handles => { mypush0 => 'push' },
    );
}, undef, '"is" parameter can be omitted';

#throws_ok {
#    has bar1 => (
#        traits  => [qw(Array)],
#        handles => { mypush1 => 'push' },
#    );
#} qr/default .* is \s+ required/xms;

my $e = exception {
    has bar2 => (
        traits  => [qw(Array)],
        default => sub{ [] },
        handles => { push => 'mypush2' },
    );
};
like $e, qr/\b unsupported \b/xms, 'wrong use of handles';

like exception {
    has bar3 => (
        traits  => [qw(Array)],
        isa     => 'HashRef',
        default => sub{ [] },
        handles => { mypush3 => 'push' },
    );
}, qr/must be a subtype of ArrayRef/;

done_testing;
