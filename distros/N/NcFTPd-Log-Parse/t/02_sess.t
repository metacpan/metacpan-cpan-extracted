use strict;
use warnings;
use lib 't/lib';

use Test::More tests => 6;
use TestHelper '$SESS_LOG'; 

BEGIN { use_ok('NcFTPd::Log::Parse::Session'); }

eval { NcFTPd::Log::Parse::Session->new('.') };
ok($@, 'should fail with a directory');

my $parser = NcFTPd::Log::Parse::Session->new($SESS_LOG);
my @entries = slurp_log($parser);

is(@entries, 3, 'should be 3 log entries');
is_deeply($entries[0], {
    time => '2011-01-13 00:03:11',
    process => '#u1',
    user => 'sshaw',
    email => '',
    host => '192.168.1.191',
    session_time => 11,
    time_between_commands => 1.2,
    bytes_retrieved => 0,
    bytes_stored => 0,
    number_of_commands => 5,
    retrieves => 0,
    stores => 0,
    chdirs => 0,
    nlists => 0,
    lists => 0,
    types => 1,
    port_pasv => 0,
    pwd => 0,
    size => 0,
    mdtm => 0,
    site => 0,
    logins => 0,
    failed_data_connections => 0,
    last_transfer_result => 'NONE',
    successful_downloads => 0,
    failed_downloads => 0,
    successful_uploads => 0,
    failed_uploads => 0,
    successful_listings => 0,
    failed_listings => 0,
    close_code => 0,
    session_id => 'TS6xtAABAAEA',
});

is_deeply($entries[1], {
    time => '2011-01-13 02:18:30',
    process => '#u3',
    user => 'anonymous',
    email => '!@#$!@#$',
    host => '"odd--host',
    session_time => 313,
    time_between_commands => 1.6,
    bytes_retrieved => 0,
    bytes_stored => 0,
    number_of_commands => 8,
    retrieves => 0,
    stores => 0,
    chdirs => 0,
    nlists => 1,
    lists => 0,
    types => 3,
    port_pasv => 1,
    pwd => 0,
    size => 0,
    mdtm => 0,
    site => 0,
    logins => 1,
    failed_data_connections => 0,
    last_transfer_result => 'NONE',
    successful_downloads => 0,
    failed_downloads => 0,
    successful_uploads => 0,
    failed_uploads => 0,
    successful_listings => 1,
    failed_listings => 1,
    close_code => 3,
    session_id => 'TS7QPQADAAEA',
});

is_deeply($entries[2], {
    time => '2011-01-18 03:40:53',
    process => '#u5',
    user => 'ass bass cass',
    email => '',
    host => 'somehost.example.com',
    session_time => 45,
    time_between_commands => '2.0',
    bytes_retrieved => 0,
    bytes_stored => 0,
    number_of_commands => 4,
    retrieves => 0,
    stores => 0,
    chdirs => 0,
    nlists => 0,
    lists => 0,
    types => 1,
    port_pasv => 0,
    pwd => 0,
    size => 0,
    mdtm => 0,
    site => 0,
    logins => 0,
    failed_data_connections => 0,
    last_transfer_result => 'NONE',
    successful_downloads => 0,
    failed_downloads => 0,
    successful_uploads => 0,
    failed_uploads => 0,
    successful_listings => 0,
    failed_listings => 0,
    close_code => 4,
    session_id => 'TTV8GAAFAAEA',
});


