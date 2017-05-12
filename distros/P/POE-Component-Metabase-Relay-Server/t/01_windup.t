use strict;
use warnings;
use Test::More qw[no_plan];
use POE qw[Component::Metabase::Relay::Server];


POE::Session->create(
  inline_states => {
    _start => sub { 
      $poe_kernel->delay( '_exit', 10 );
      $_[HEAP]->{test_httpd} = POE::Component::Metabase::Relay::Server->spawn(
        id_file => 't/example_id.json',
        dsn     => 'dbi:SQLite:dbname=',
        uri     => 'https://metabase.example.foo/',
        debug   => 0,
        no_curl => 1, # disable PoCo-Curl-Multi during testing
      );
      isa_ok( $_[HEAP]->{test_httpd}, q[POE::Component::Metabase::Relay::Server] );
      return;
    },
    _exit  => sub { $_[HEAP]->{test_httpd}->shutdown; },
    _stop  => sub { pass('happy joy joy'); return; },
  },
);

$poe_kernel->run();
exit 0;
