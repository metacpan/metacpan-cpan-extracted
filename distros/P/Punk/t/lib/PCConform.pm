package PCConform;

# The behavioural battery, run identically against every cache backend.
#
# This file is the contract's enforcement arm. The rule: no behavioural
# assertion about the backend contract may live outside it, and any difference
# between backends is a bug in one of them or in the contract - never
# something to paper over with a per-backend skip.
#
# A skip here would restore precisely the failure the suite exists to prevent:
# an application developed against the memory store that breaks on files, in
# production, on the one value that happened to be unusual.
#
# The pattern is Punk::Queue's PQConform, whose plan records that suite
# catching three real portability bugs - differences every other test had
# missed because every other test only ran against one backend.
#
# Usage:
#     conformance(\&make_store, 'memory');
#
# where make_store returns a fresh, empty backend every call.

use 5.010;
use strict;
use warnings;
use Exporter 'import';
use Test::More;

our @EXPORT = ('conformance');

sub conformance {
    my ($make, $name) = @_;

    subtest "$name: get and set" => sub {
        my $c = $make->();
        is($c->get('absent'), undef, 'an absent key is undef');
        is($c->set('k', 'v', 0), 1, 'set reports success');
        is($c->get('k'), 'v', 'and the value comes back');
    };

    subtest "$name: overwrite replaces" => sub {
        my $c = $make->();
        $c->set('k', 'first',  0);
        $c->set('k', 'second', 0);
        is($c->get('k'), 'second', 'the second value wins');
        my %s = $c->stats;
        is($s{entries}, 1, 'and it is still one entry, not two');
    };

    subtest "$name: delete" => sub {
        my $c = $make->();
        $c->set('k', 'v', 0);
        ok($c->delete('k'), 'delete reports it removed something');
        is($c->get('k'), undef, 'and the key is gone');
        ok(!$c->delete('k'), 'deleting it again reports nothing removed');
    };

    subtest "$name: clear" => sub {
        my $c = $make->();
        $c->set("k$_", 'v', 0) for 1 .. 5;
        $c->clear;
        is($c->get('k1'), undef, 'clear removed the entries');
        my %s = $c->stats;
        is($s{entries}, 0, 'and stats agrees');
        is($s{bytes},   0, 'including the byte total');
    };

    subtest "$name: ttl" => sub {
        my $c = $make->();

        # 0 means NO EXPIRY, not "expire immediately". The opposite reading is
        # the sort of thing that empties a cache in production, so it is
        # asserted rather than assumed.
        $c->set('eternal', 'v', 0);
        $c->set('brief',   'v', 1);
        is($c->get('eternal'), 'v', 'a ttl of 0 does not expire');
        is($c->get('brief'),   'v', 'and a live entry is returned');

        sleep 2;

        is($c->get('eternal'), 'v',   'still there after the window');
        is($c->get('brief'),   undef, 'while the expired one is gone');
    };

    subtest "$name: binary values" => sub {
        my $c = $make->();
        my $bin = join '', map { chr } 0 .. 255;

        $c->set('bin', $bin, 0);
        is($c->get('bin'), $bin, 'every byte round trips, NUL included');

        $c->set('empty', '', 0);
        is($c->get('empty'), '',
            'a zero-length value is a VALUE, not a miss - an empty string is '
          . 'something somebody deliberately cached');

        my $big = 'x' x 200_000;
        $c->set('big', $big, 0);
        is($c->get('big'), $big, 'and a large value survives whole');
    };

    subtest "$name: binary and awkward keys" => sub {
        my $c = $make->();
        my @keys = (
            "with\0nul",
            "new\nline",
            '../../etc/passwd',
            '/absolute/path',
            join('', map { chr } 1 .. 255),
            'x' x 4000,
        );

        for my $i (0 .. $#keys) {
            $c->set($keys[$i], "value$i", 0);
        }
        my @wrong = grep { ($c->get($keys[$_]) // '') ne "value$_" } 0 .. $#keys;
        is_deeply(\@wrong, [],
            'every key round trips to its own value - none collided, and a '
          . 'key that looks like a path is just a key');

        my %s = $c->stats;
        is($s{entries}, scalar @keys, 'and each is a distinct entry');
    };

    subtest "$name: oversize is refused, not stored" => sub {
        my $c = $make->(max_bytes => 8192);
        $c->set('keep', 'small', 0);

        is($c->set('huge', 'x' x 65536, 0), 0,
            'a value too big for the budget is refused');
        is($c->get('huge'), undef, 'and is not there');
        is($c->get('keep'), 'small',
            'and it did not empty the cache on its way past, which is what '
          . 'making room for it would have done');

        my %s = $c->stats;
        is($s{refused}, 1, 'the refusal is counted');
    };

    subtest "$name: stats count truthfully" => sub {
        my $c = $make->();
        $c->set('a', 'v', 0);
        $c->get('a');
        $c->get('a');
        $c->get('nope');

        my %s = $c->stats;
        is($s{hits},   2, 'a hit increments hits');
        is($s{misses}, 1, 'and a miss increments misses, not hits');
        cmp_ok($s{bytes}, '>', 0, 'bytes reports what is held');
        is($s{entries}, 1, 'and entries counts the entries');
        cmp_ok($s{max_bytes}, '>', 0, 'the budget is reported');
    };

    subtest "$name: the byte budget holds" => sub {
        my $cap = 128 * 1024;
        my $c = $make->(max_bytes => $cap);

        $c->set("k$_", 'x' x 4096, 0) for 1 .. 200;   # ~800KB into 128KB
        $c->_sweep if $c->can('_sweep');               # file store reconciles

        my %s = $c->stats;
        cmp_ok($s{bytes}, '<=', $cap,
            'the store never exceeds its budget - the assertion the whole '
          . 'component exists for')
            or diag "bytes=$s{bytes} cap=$cap";
        cmp_ok($s{evictions}, '>', 0, 'and the evictions are counted');
        cmp_ok($s{entries},   '>', 0, 'without emptying itself');
    };

    return;
}

1;
