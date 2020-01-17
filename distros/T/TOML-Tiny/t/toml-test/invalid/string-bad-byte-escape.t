# File automatically generated from BurntSushi/toml-test
use utf8;
use Test2::V0;
use TOML::Tiny;

binmode STDIN,  ':encoding(UTF-8)';
binmode STDOUT, ':encoding(UTF-8)';

ok dies(sub{
  from_toml(q{
naughty = "\\xAg"

  }, strict_arrays => 1);
}), 'strict_mode dies on string-bad-byte-escape';

done_testing;