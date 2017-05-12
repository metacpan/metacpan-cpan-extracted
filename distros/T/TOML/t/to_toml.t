use strict;
use warnings;
use utf8;
use Test::More;

use TOML;

test(
    +{
        foo => 'bar',
    }
, <<'...', 'str');
foo = "bar"
...

test(
    +{
        foo => 3,
    }
, <<'...', 'int');
foo = 3
...

test(
    +{
        foo => {
            bar => 'baz',
            iya => 'aan',
        },
    }
, <<'...', 'nest');
[foo]
bar = "baz"
iya = "aan"
...

test(
    +{
        foo => {
            bar => 'baz',
            iya => 'aan',
        },
        ya => [1,2,'3'],
    }
, <<'...', 'array');
ya = [1, 2, "3"]
[foo]
bar = "baz"
iya = "aan"
...

test(
    +{
        foo => { },
    }
, <<'...', 'Empty HashRef');
[foo]
...

is(to_toml(+{ foo => \1 }), <<'...');
foo = true
...

is(to_toml(+{ bar => \0 }), <<'...');
bar = false
...

test(
    +{
        path => 'foo/bar',
    }
, <<'...', 'filesystem path');
path = "foo/bar"
...

done_testing;

sub test {
    my ($perl, $toml, $desc) = @_;
    is(to_toml($perl), $toml, $desc);
    my ($ret, $err) = from_toml(to_toml($perl));
    is_deeply($ret, $perl, $desc);
    ok(!$err) or diag $err;
}

