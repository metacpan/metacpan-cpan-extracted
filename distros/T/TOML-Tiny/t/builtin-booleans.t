use utf8;
use Test2::V0;
use Test::Needs 'Types::Serialiser';
use TOML::Tiny;

plan skip_all => 'No builtin::is_bool' unless defined &builtin::is_bool;

# Real Perl booleans should serialize identically to the booleans
# produced by round-tripping TOML through Types::Serialiser. Without
# Types::Serialiser the round-trip yields 1/0, so this lives in its own
# Test::Needs-guarded file. See GH #46.

my $regenerated = to_toml(scalar from_toml("f = false\nt = true\n"));

# Both sides contain only the "t"/"f" keys; to_toml sorts keys, so the
# two serializations are directly comparable.
my $data = { t => !!1, f => !!0 };
is(to_toml($data), $regenerated, 'builtin booleans serialize like Types::Serialiser booleans');

done_testing;
