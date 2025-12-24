package HakkefuinTestMariaDb;
use Mojo::Base 'HakkefuinTestFullBase';

sub backend_label  {'mariadb'}
sub backend_config { {via => 'mariadb', dsn => $ENV{TEST_ONLINE_mariadb}} }

1;
