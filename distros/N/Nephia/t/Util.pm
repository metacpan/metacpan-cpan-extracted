package t::Util;
use strict;
use warnings;
use parent 'Exporter';

our @EXPORT_OK = qw/mock_env/;

sub mock_env {
    +{
        'SERVER_NAME' => 'localhost',
        'SCRIPT_NAME' => '',
        'PATH_INFO' => '/',
        'CONTENT_LENGTH' => 0,
        'REQUEST_METHOD' => 'GET',
        'REMOTE_PORT' => 19783,
        'QUERY_STRING' => 'name=ytnobody',
        'SERVER_PORT' => 80,
        'REMOTE_ADDR' => '127.0.0.1',
        'SERVER_PROTOCOL' => 'HTTP/1.1',
        'REQUEST_URI' => '/?name=ytnobody',
        'REMOTE_HOST' => 'localhost',
        'HTTP_HOST' => 'localhost',
    };
}

1;
