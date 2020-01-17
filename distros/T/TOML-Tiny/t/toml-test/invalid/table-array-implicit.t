# File automatically generated from BurntSushi/toml-test
use utf8;
use Test2::V0;
use TOML::Tiny;

binmode STDIN,  ':encoding(UTF-8)';
binmode STDOUT, ':encoding(UTF-8)';

ok dies(sub{
  from_toml(q{
# This test is a bit tricky. It should fail because the first use of
# `[[albums.songs]]` without first declaring `albums` implies that `albums`
# must be a table. The alternative would be quite weird. Namely, it wouldn't
# comply with the TOML spec: "Each double-bracketed sub-table will belong to 
# the most *recently* defined table element *above* it."
#
# This is in contrast to the *valid* test, table-array-implicit where
# `[[albums.songs]]` works by itself, so long as `[[albums]]` isn't declared
# later. (Although, `[albums]` could be.)
[[albums.songs]]
name = "Glory Days"

[[albums]]
name = "Born in the USA"

  }, strict_arrays => 1);
}), 'strict_mode dies on table-array-implicit';

done_testing;