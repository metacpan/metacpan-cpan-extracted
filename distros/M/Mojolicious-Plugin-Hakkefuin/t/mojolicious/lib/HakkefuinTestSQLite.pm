package HakkefuinTestSQLite;
use Mojo::Base 'HakkefuinTestFullBase';

sub backend_label  {'sqlite'}
sub backend_config { {via => 'sqlite'} }

1;
