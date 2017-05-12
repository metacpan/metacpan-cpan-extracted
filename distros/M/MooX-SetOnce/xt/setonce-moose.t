use strictures 1;
use Test::More;
use Test::Fatal;
use File::Basename;
BEGIN { do(dirname(__FILE__).'/../t/setonce.t'); die $@ if $@ }

{
  package MooseInhSetOnce;
  use Moose;
  extends 'MooSetOnce';
}

{
  package MooseWithSetOnce;
  use Moose;
  with 'MooSetOnceRole';
}

{
  package MooseInhSetOnceOverride;
  use Moose;
  extends 'MooSetOnce';
  has '+two' => (clearer => 'clear_two');
}

test_object(MooseInhSetOnce->new);
test_object(MooseWithSetOnce->new);
test_object(MooseInhSetOnceOverride->new);

done_testing;

