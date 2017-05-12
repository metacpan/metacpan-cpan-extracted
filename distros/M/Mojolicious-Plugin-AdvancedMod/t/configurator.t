use Mojo::Base -strict;

use FindBin;
use lib "$FindBin::Bin/lib";

use Test::Mojo;
use Test::More;

my $t = Test::Mojo->new( 'MyApp' );
my $am_cfg = $t->app->defaults( 'am_config' );

is $am_cfg->{secrets}, '0514eb3b7d219eddc82d403d53e1a6ba', 'Overall "secrets" key';
is $am_cfg->{db_slave}{dbname}, 'test', 'db_slave dbname';
is $am_cfg->{db_slave}{dsn}, 'dbi:Pg:dbname=test;host=127.0.0.1;port=5432', 'Config encapsulate';

done_testing();