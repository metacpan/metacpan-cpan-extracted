use Test2::V0 -no_srand => 1;
use NewRelic::Agent::FFI::Procedural;
use FFI::Platypus;

subtest 'export' => sub {

  imported_ok 'newrelic_init';
  
  note "also imported: $_" for @NewRelic::Agent::FFI::Procedural::EXPORT;
  
  ok(newrelic_message_handler, "address of newrelic_message_handler: @{[ newrelic_message_handler ]}");

};

subtest 'newrelic_basic_literal_replacement_obfuscator' => sub {

  my $ffi = FFI::Platypus->new;
  my $f = $ffi->function( newrelic_basic_literal_replacement_obfuscator, ['string'] => 'string' );
  
  my $hidden = $f->("SELECT * FROM user WHERE password = 'secret'");
  pass "didn't crash";
  note $hidden;

};

subtest 'init' => sub {

  newrelic_init;
  
  pass "didn't crash";

};

subtest 'newrelic_request_shutdown' => sub {

  my $status = newrelic_request_shutdown 'Because I said so';
  
  is $status, 0;
  note "status = $status";

};

done_testing;
