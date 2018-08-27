use Test2::V0 -no_srand => 1;
use NewRelic::Agent::FFI;
use Time::HiRes qw( sleep );

# NOTE: this test can be run in either DEAD or LIVE mode
#  - DEAD - make all the calls but do not actually send the data to NR
#           this is the default, and verifies that the NR agent class
#           at least won't CRASH when you instrament your application
#           with it.
#  - LIVE - if you set NEWRELIC_AGENT_FFI_TEST it will send metrics to NR
#           using the key as specified in that environment variable.
#           You can then login to your NR account and verify that stuff works.

my $license_key = $ENV{NEWRELIC_AGENT_FFI_TEST};
my $nr;

# TODO: test for set_transaction_category    ( newrelic_transaction_set_category )

subtest 'setup' => sub {

  $nr = NewRelic::Agent::FFI->new(
    license_key => $license_key || 'xxxx',
    app_name    => "NRAFFI (Test)",
  );
  isa_ok $nr, 'NewRelic::Agent::FFI';

  $nr->embed_collector;
  ok 1, 'embed_collector';
  
  is $nr->init, 0, 'init';
};

subtest 'metrics' => sub {

  is $nr->record_metric('furlongs per fortnight' => 0.235), 0, 'newrelic_record_metric';
  is $nr->record_cpu_usage(1.2,3.4), 0, 'record_cpu_usage';
  is $nr->record_memory_usage(42.43), 0, 'record_memory_usage';

};

subtest "transaction (web)" => sub {

  my $tx = $nr->begin_transaction;
  ok $tx, "begin_transaction";
  note "tx = $tx";
  
  is $nr->set_transaction_request_url($tx, 'http://127.0.0.1/foo/bar/baz'), 0, 'set_transaction_request_url';
  is $nr->set_transaction_type_web($tx), 0, 'set_transaction_type_web';
  is $nr->set_transaction_name($tx, "/foo/$$"), 0, 'set_transaction_name';
  is $nr->add_transaction_attribute($tx, user_id => 'blarpho'), 0, 'add_transaction_attribute';
  is $nr->set_transaction_max_trace_segments($tx, 1000), 0, 'set_transaction_max_trace_segments';
  
  subtest 'generic segment' => sub {

    my $seg = $nr->begin_generic_segment($tx, undef, 'genero-segment');
    ok $seg, 'begin_generic_segment';
    note "seg = $seg";

    sleep rand .5;

    is $nr->end_segment($tx, $seg), 0, 'end_segment';

  };

  subtest 'datastore segment' => sub {

    my $seg = $nr->begin_datastore_segment($tx, undef, 'users', 'selecting users', 'SELECT * FROM users WHERE id = ?', 'get_user_account');
    ok $seg, 'begin_datastore_segment';
    note "seg = $seg";

    sleep rand .5;

    is $nr->end_segment($tx, $seg), 0, 'end_segment';

  };

  subtest 'external segment' => sub {

    my $seg = $nr->begin_external_segment($tx, undef, 'http://frooble.test/api', 'call an api');
    ok $seg, 'begin_external_segment';
    note "seg = $seg";

    sleep rand .5;

    is $nr->end_segment($tx, $seg), 0, 'end_segment';

  };

  is $nr->end_transaction($tx), 0, 'end_transaction';
};

subtest 'transaction with error' => sub {

  my $tx = $nr->begin_transaction;
  ok $tx, "begin_transaction";
  note "tx = $tx";
  
  is $nr->set_transaction_request_url($tx, 'http://127.0.0.1/foo/bar/baz'), 0, 'set_transaction_request_url';
  is $nr->set_transaction_type_web($tx), 0, 'set_transaction_type_web';
  is $nr->set_transaction_name($tx, "/bar/$$"), 0, 'set_transaction_name';
  is $nr->add_transaction_attribute($tx, user_id => 'blarpho'), 0, 'add_transaction_attribute';

  is $nr->notice_transaction_error($tx, 'normal', 'ieeieieie something went wrong!', 'one:two:three', ':'), 0, 'notice_transaction_error';
  
  is $nr->end_transaction($tx), 0, 'end_transaction';
};

subtest "transaction (other)" => sub {

  my $tx = $nr->begin_transaction;
  ok $tx, "begin_transaction";
  note "tx = $tx";
  
  is $nr->set_transaction_type_other($tx), 0, 'set_transaction_type_other';
  is $nr->set_transaction_name($tx, "thingie and stuff"), 0, 'set_transaction_name';
  is $nr->add_transaction_attribute($tx, user_id => 'blarpho'), 0, 'add_transaction_attribute';

  sleep rand 1;

  is $nr->end_transaction($tx), 0, 'end_transaction';
};

done_testing;
