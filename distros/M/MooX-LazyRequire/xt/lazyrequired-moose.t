use strict;
use warnings;
use Test::More;
use Test::Fatal;
use File::Basename;
BEGIN { do(dirname(__FILE__).'/../t/lazyrequired.t'); die $@ if $@ }

{
  package MooseInhLazyRequire;
  use Moose;
  extends 'MooLazyRequire';
}

{
  package MooseWithLazyRequire;
  use Moose;
  with 'MooLazyRequireRole';
}

{
  package MooseInhLazyRequireOverride;
  use Moose;
  extends 'MooLazyRequire';
  has '+two' => (clearer => 'clear_two');
}

test_object(MooseInhLazyRequire->new);
test_object(MooseWithLazyRequire->new);
test_object(MooseInhLazyRequireOverride->new);

done_testing;
