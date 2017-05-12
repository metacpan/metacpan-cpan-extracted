  use strict;
  use warnings;

  use POE qw[Component::Metabase::Relay::Server];

  my $test_httpd = POE::Component::Metabase::Relay::Server->spawn( 
    port    => 8080, 
    id_file => shift, 
    dsn     => 'dbi:SQLite:dbname=dbfile',
    uri     => 'https://metabase.example.foo/',
    debug   => 1,
  );

  $poe_kernel->run();
  exit 0;
