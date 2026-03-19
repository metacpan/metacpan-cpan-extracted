use strict;
use warnings;
use Test::Most;

use Syntax::Feature::With qw(with_hash);

# -------------------------------------------------------------------------
# Declare ALL lexicals ONCE, before any coderef is compiled
# -------------------------------------------------------------------------

my ($host, $port, $debug, $h, $p, $foo);

# -------------------------------------------------------------------------
# Test data
# -------------------------------------------------------------------------

my %H = (
    host     => 'localhost',
    port     => 3306,
    debug    => 1,
    'bad-key' => 123,   # invalid identifier
);

# -------------------------------------------------------------------------
# strict_keys: missing lexical should croak
# -------------------------------------------------------------------------

dies_ok {
    with_hash
        -strict_keys,
        \%H,
        sub { };
} 'strict_keys: missing lexical causes error (debug missing)';

# -------------------------------------------------------------------------
# strict_keys: all lexicals present
# -------------------------------------------------------------------------

lives_ok {
    with_hash
        -strict_keys,
        \%H,
        sub {
            is $host,  'localhost';
            is $port,  3306;
            is $debug, 1;
        };
} 'strict_keys: all lexicals declared';

# -------------------------------------------------------------------------
# strict_keys + rename
# -------------------------------------------------------------------------

lives_ok {
    with_hash
        -strict_keys,
        -rename => { host => 'h', port => 'p' },
        \%H,
        sub {
            is $h, 'localhost';
            is $p, 3306;
            $debug;    # force closure over $debug
        };
} 'strict_keys + rename works';

# -------------------------------------------------------------------------
# strict_keys + rename: missing renamed lexical should croak
# -------------------------------------------------------------------------

dies_ok {
    with_hash
        -strict_keys,
        -rename => { host => 'h' },   # port not renamed
        \%H,
        sub { };
} 'strict_keys + rename: missing renamed lexical dies';

# -------------------------------------------------------------------------
# strict_keys ignores invalid identifiers (bad-key)
# -------------------------------------------------------------------------

lives_ok {
    with_hash
        -strict_keys,
        \%H,
        sub {
            () = $host;     # force closure
            () = $port;     # force closure
            $debug;    # force closure
            # bad-key is ignored as invalid identifier
        };
} 'strict_keys: invalid identifiers are ignored';

# -------------------------------------------------------------------------
# strict_keys + only: only selected keys must have lexicals
# -------------------------------------------------------------------------

lives_ok {
    with_hash
        -strict_keys,
        -only => [qw/host/],
        \%H,
        sub {
            is $host, 'localhost';
        };
} 'strict_keys + only: only selected keys required';

dies_ok {
    with_hash
        -strict_keys,
        -only => [qw/host port/],
        \%H,
        sub { };
} 'strict_keys + only: missing lexical for port dies';

# -------------------------------------------------------------------------
# strict_keys + except: excluded keys do not require lexicals
# -------------------------------------------------------------------------

lives_ok {
    with_hash
        -strict_keys,
        -except => [qw/debug/],
        \%H,
        sub {
            is $host, 'localhost';
            is $port, 3306;
        };
} 'strict_keys + except: excluded keys not required';

# -------------------------------------------------------------------------
# strict_keys + readonly
# -------------------------------------------------------------------------

lives_ok {
    with_hash
        -strict_keys,
        -readonly,
        \%H,
        sub {
            is $host, 'localhost';
            () = $port;     # force closure
            dies_ok { $host = 'x' } 'readonly still enforced';
        };
} 'strict_keys + readonly works';

done_testing();
