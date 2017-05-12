#!perl -T

use Test::More tests => 2;
use Script::Daemonizer qw/:NOCHDIR :NOUMASK/;

# new() croaks if odd number of elemets was passed
eval q(
    my $daemon = new Script::Daemonizer(
        name => 'Test',
        workdir =>
    );
);

like($@, qr/Odd number/, 'new() must croak() if odd number of elements in config');

# new() croaks if unknown parameter passed
eval q(
    my $daemon = new Script::Daemonizer(
        name => 'Test',
        unknown_param => 'bla',
    );
);

like($@, qr/Invalid argument/, 'new() must croak() if config contains an unknown parameter');
