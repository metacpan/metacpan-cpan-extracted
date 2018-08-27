use Test2::V0 -no_srand => 1;
use NewRelic::Agent::FFI;

subtest 'init' => sub {
  my $nr = NewRelic::Agent::FFI->new;
  $nr->embed_collector;
  $nr->init;
  pass 'embed_collector; init did not crash';
};

done_testing

