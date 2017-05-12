#!perl -T

use strict;
use warnings;
use lib 't/lib';

use Test::More 'no_plan';

BEGIN { use_ok('Sub::Pipeline'); }

use Test::SubPipeline::PipePkg;

{
  my $sub = Sub::Pipeline->new({ order => [ qw(begin check init run end) ] });
  $sub->load_from_package('Test::SubPipeline::PipePkg');

  local $Test::SubPipeline::PipePkg::value = 0;

  my $r = eval { $sub->call };
  is($r, 5, 'correct return value');

  is($Test::SubPipeline::PipePkg::value, 5, "variable changed by pipe");
}
