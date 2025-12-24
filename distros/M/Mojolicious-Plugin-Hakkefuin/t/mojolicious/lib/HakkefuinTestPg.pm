package HakkefuinTestPg;
use Mojo::Base 'HakkefuinTestFullBase';

sub backend_label  {'pg'}
sub backend_config { {via => 'pg', dsn => $ENV{TEST_ONLINE_pg}} }

1;
