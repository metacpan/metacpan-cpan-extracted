use 5.010;
use Test2::V0 -no_srand => 1;
use NewRelic::Agent::FFI::Procedural;
use FFI::Platypus;
use FFI::Platypus::Memory qw( strdup free );

my $license_key = $ENV{NEWRELIC_AGENT_FFI_TEST};

subtest 'diag' => sub {

  diag '';
  diag '';
  diag '';

  diag "lib=$_" for @NewRelic::Agent::FFI::Procedural::lib;

  diag '';
  diag '';

  pass 'good stuff';
};

subtest 'export' => sub {

  imported_ok 'newrelic_init';
  
  note "also imported: $_" for @NewRelic::Agent::FFI::Procedural::EXPORT;
  
  ok(newrelic_message_handler, "address of newrelic_message_handler: @{[ newrelic_message_handler ]}");

};

subtest embedded => sub {

  skip_all 'test requires license key' unless $license_key;  
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

subtest 'newrelic_segment_datastore_begin' => sub {

  my $tx = newrelic_transaction_begin;
  ok $tx, 'newrelic_transaction_begin';

  our $sql_in;
  sub myobfuscator
  {
    ($sql_in) = @_;
    note "myobfuscator($sql_in)";
    my $sql_out = 'select * from users where password = ?';
    state $ptr = 0;
    free($ptr) if $ptr;
    $ptr = strdup $sql_out;
  }
  
  my $ffi = FFI::Platypus->new;
  $ffi->type('(string)->opaque' => 'ob');
  my $myobfuscator_closure = $ffi->closure(\&myobfuscator);
  my $myobfuscator_ptr = $ffi->cast(ob => opaque => $myobfuscator_closure);
  note "\$myobfuscator_ptr = $myobfuscator_ptr";
  
  my $seg = newrelic_segment_datastore_begin $tx, NEWRELIC_ROOT_SEGMENT, 'mytable', 'select', "select * from users where password = 'secret'", 'get_user_pw', $myobfuscator_ptr;
  ok $seg, 'newrelic_segment_datastore_begin';

  is $sql_in, "select * from users where password = 'secret'", 'myobfuscator called';
  
  sleep rand .5;
  
  my $rc = newrelic_segment_end $tx, $seg;
  is $rc, 0, 'newrelic_segment_end';
  
  newrelic_transaction_end $tx;
  ok 1, 'newrelic_transaction_end';
};

subtest 'newrelic_request_shutdown' => sub {

  #our $status;
  #sub status_cb {
  #  $status = shift;
  #};
  #note 'here1';
  #newrelic_register_status_callback \&status_cb;
  #note 'here2';

  my $rc = newrelic_request_shutdown 'Because I said so';
  
  is $rc, 0;
  note "rc     = $rc";
  #note "status = $status";

};

done_testing;
