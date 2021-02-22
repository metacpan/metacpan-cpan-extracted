use strict;
use warnings;

use Test2::V0;
use TOML::Tiny;

my $tt = TOML::Tiny->new(strict_arrays => 1);

subtest 'string containing int recognized as type=integer' => sub{
  my $toml = q{
[test]
array = ["u", "u2"]
  };

  ok lives{ $tt->decode($toml) }, 'parse succeeds';
};

done_testing;
