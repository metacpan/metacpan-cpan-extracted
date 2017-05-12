package SimpleDB::Client::Exception;
{
  $SimpleDB::Client::Exception::VERSION = '1.0600';
}

=head1 NAME

SimpleDB::Client::Exception - Exceptions thrown by SimpleDB::Client.

=head1 VERSION

version 1.0600

=head1 DESCRIPTION

A submclass of L<Exception::Class> that defines expcetions to be thrown through-out L<SimpleDB::Client> ojbects.

=head1 EXCEPTIONS

The following exceptions are available from this class.

=head2 SimpleDB::Client::Exception

A general error. Isa Exception::Class.

=head2 SimpleDB::Client::Exception::Connection

Thrown when exceptions occur connecting to the SimpleDB database at Amazon, or the memcached server. Isa SimpleDB::Client::Exception.

=head3 status_code

The HTTP status code returned.

=head2 SimpleDB::Client::Exception::Response

Isa SimpleDB::Client::Exception::Connection. Thrown when SimpleDB reports an error.

=head3 error_code

The error code returned from SimpleDB.

=head3 request_id

The request id as returned from SimpleDB.

=head3 box_usage

The storage usage in your SimpleDB.

=head3 response

The L<HTTP::Response> object as retrieved from the SimpleDB request.

=cut

use strict;
use Exception::Class (

    'SimpleDB::Client::Exception' => {
        description     => "A general error occured.",
        },
    'SimpleDB::Client::Exception::Connection' => {
        isa             => 'SimpleDB::Client::Exception',
        description     => "There was a problem establishing a connection.",
        fields          => ['status_code'],
        },
    'SimpleDB::Client::Exception::Response' => {
        isa             => 'SimpleDB::Client::Exception::Connection',
        description     => "The database reported an error.",
        fields          => ['error_code','request_id','box_usage','response'],
        },

);

=head1 LEGAL

SimpleDB::Client is Copyright 2009-2010 Plain Black Corporation (L<http://www.plainblack.com/>) and is licensed under the same terms as Perl itself.

=cut

1;
