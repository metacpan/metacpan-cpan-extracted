# File automatically generated from BurntSushi/toml-test
use utf8;
use Test2::V0;
use TOML::Tiny;

binmode STDIN,  ':encoding(UTF-8)';
binmode STDOUT, ':encoding(UTF-8)';

ok dies(sub{
  from_toml(q{
[a]b]
zyx = 42

  }, strict_arrays => 1);
}), 'strict_mode dies on table-nested-brackets-close';

done_testing;