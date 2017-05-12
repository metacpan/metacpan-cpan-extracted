use Mojo::Base -strict;
use Data::Dumper;
use Test::More; 
use lib 'lib';
 
use_ok 'Mojolicious::Command::migration';

my $config = do 't/mysql.conf';

my $migration = Mojolicious::Command::migration->new;
$migration->config($config);

ok $migration->description, 'has a description';

eval { $migration->run() };
like $@, qr/Usage/, 'right error';

eval { $migration->run('badcommand') };
like $@, qr/Usage/, 'right error';


done_testing;