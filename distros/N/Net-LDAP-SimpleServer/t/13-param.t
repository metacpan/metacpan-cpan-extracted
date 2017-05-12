use Test::More tests => 10;

use lib 't/lib';
use Helper qw(server_ok server_nok);

# undef or empty hash
server_nok( undef, 'should not work without parameters' );
server_nok( {}, 'should not work with empty has as parameter' );

# configuration file
diag('Net::Server error below:');
server_nok( { conf_file => '/no/such/file.conf' },
    'should not work with non-existing configuration file' );
server_nok(
    { conf_file => 'examples/empty.conf' },
    'should not work with empty configuration file'
);
server_ok(
    { conf_file => 'examples/single-entry.conf' },
    'should work with proper configuration file'
);

# data file
server_nok(
    { data_file => 'examples/test1.ldif' },
    'should not work with non-existing data file'
);
server_ok(
    { data_file => 'examples/single-entry.ldif' },
    'should work with existing data file'
);

# other tests
server_ok(
    {
        port      => 20000,
        data_file => 'examples/single-entry.ldif',
    },
    'should work with proper data file and port'
);
server_nok(
    {
        host    => 'localhost',
        port    => '10389',
        root_pw => 'testpw',
    }
);
server_ok(
    {
        host      => 'localhost',
        port      => '10389',
        data_file => 'examples/single-entry.ldif',
        root_pw   => 'testpw',
    },
    'should work specifying different parameters'
);

