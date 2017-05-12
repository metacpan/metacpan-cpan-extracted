use Test::More tests => 13;
use strict;
use warnings;
use Net::Proxy;

my $proxy;

# test constructor
eval { $proxy = Net::Proxy->new(); };
like( $@, qr/^Argument to new\(\) must be a HASHREF/, 'new( HASHREF )' );

eval { $proxy = Net::Proxy->new(1); };
like( $@, qr/^Argument to new\(\) must be a HASHREF/, 'new( HASHREF )' );

# in argument
eval { $proxy = Net::Proxy->new( {} ); };
like( $@, qr/^'in' connector required/, 'in arg required' );

eval { $proxy = Net::Proxy->new( { in => 'in' } ); };
like( $@, qr/^'in' connector must be a HASHREF/, 'in must be a HASHREF');

eval { $proxy = Net::Proxy->new( { in => {} } ); };
like(
    $@,
    qr/^'type' key required for 'in' connector/,
    'type required for in arg'
);

eval {
    $proxy = Net::Proxy->new( { in => { type => 'zlonk', hook => {} } } );
};
like(
    $@,
    qr/^'hook' key is not a CODE reference for 'in' connector/,
    'hook must be a CODE reference'
);

eval { $proxy = Net::Proxy->new( { in => { type => 'zlonk' } } ); };
like(
    $@,
    qr/^Couldn't load Net::Proxy::Connector::zlonk for 'in' connector/,
    q{NPC::zlonk doesn't exist}
);

# out argument
eval { $proxy = Net::Proxy->new( { in => { type => 'tcp' } } ); };
like( $@, qr/^'out' connector required/, 'out arg required' );

eval { $proxy = Net::Proxy->new( { in => { type => 'tcp' }, out => 'out' } ) };
like( $@, qr/^'out' connector must be a HASHREF/, 'in must be a HASHREF');

eval { $proxy = Net::Proxy->new( { in => { type => 'tcp' }, out => {} } ); };
like(
    $@,
    qr/^'type' key required for 'out' connector/,
    'type required for out arg'
);

eval {
    $proxy = Net::Proxy->new(
        {   in  => { type => 'tcp' },
            out => { type => 'zlonk', hook => bless {}, 'CODE' }
        }
    );
};
like(
    $@,
    qr/^'hook' key is not a CODE reference for 'out' connector/,
    'hook must be a CODE reference'
);

eval {
    $proxy = Net::Proxy->new(
        { in => { type => 'tcp' }, out => { type => 'zlonk' } } );
};
like(
    $@,
    qr/^Couldn't load Net::Proxy::Connector::zlonk for 'out' connector/,
    q{NPC::zlonk doesn't exist}
);

# ok
eval {
    $proxy = Net::Proxy->new(
        { in => { type => 'tcp' }, out => { type => 'tcp' } } );
};
is( $@, '', 'Net::Proxy->new()' );

