use Mojo::Base -strict;
use Test::More;
use Test::Exception;
use Mojo::DB::Connector;

throws_ok
    { Mojo::DB::Connector->new->scheme('bogus')->new_connection }
    qr/unknown scheme 'bogus'. Supported schemes are: mariadb, mysql, postgresql/,
    'unknown scheme throws';

done_testing;