use strict;
use warnings;
use Test::More;
use PAGI::Server::ConnectionState;

my $conn = PAGI::Server::ConnectionState->new;
is $conn->response_started, 0, 'not started initially';
$conn->_mark_response_started;
is $conn->response_started, 1, 'started after mark';
$conn->_mark_response_started;                # idempotent
is $conn->response_started, 1, 'still started';
done_testing;
