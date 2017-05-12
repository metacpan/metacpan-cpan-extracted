#!perl -T

use strict;
use warnings;
use lib 't/lib';

use Test::More tests => 7;

BEGIN {
  use_ok('Sub::Pipeline');
  use_ok("Test::SubPipeline::Class");
  use_ok("Test::SubPipeline::Subclass");
}

{
  my $data = {};

  my $v = Test::SubPipeline::Class->call($data);

  is_deeply(
    $data,
    { first => 1, second => 2, third => 3 },
    "pipeline did its thing",
  );

  is($v, "OK!!", "correct return");
}

{
  my $data = {};

  my $v = Test::SubPipeline::Subclass->call($data);

  is_deeply(
    $data,
    { first => 1, second => 'two', third => 3 },
    "subclass pipeline did its thing",
  );

  is($v, "OK!!", "correct return");
}
