package SimpleDB::Class::Exception;
BEGIN {
  $SimpleDB::Class::Exception::VERSION = '1.0503';
}

=head1 NAME

SimpleDB::Class::Exception - Exceptions thrown by SimpleDB::Class.

=head1 VERSION

version 1.0503

=head1 DESCRIPTION

A submclass of L<Exception::Class> that defines expcetions to be thrown through-out L<SimpleDB::Class> ojbects.

=head1 EXCEPTIONS

The following exceptions are available from this class.

=head2 SimpleDB::Class::Exception

A general error. Isa Exception::Class.

=head2 SimpleDB::Class::Exception::ObjectNotFound

Thrown when a request object is not found.

=head3 id

The id of the requested object.

=head2 SimpleDB::Class::Exception::InvalidParam

Thrown when a parameter isn't passed when it should have been, or if it's left undefined. Isa SimpleDB::Class::Exception::ObjectNotFound.

=head2 SimpleDB::Class::Exception::InvalidObject

Thrown when a request object is found, but is corrupt. Isa SimpleDB::Class::Exception::ObjectNotFound.

=head2 SimpleDB::Class::Exception::Connection

Thrown when exceptions occur connecting to the SimpleDB database at Amazon, or the memcached server. Isa SimpleDB::Class::Exception.

=head3 status_code

The HTTP status code returned.

=cut

use strict;
use Exception::Class (

    'SimpleDB::Class::Exception' => {
        description     => "A general error occured.",
        },
    'SimpleDB::Class::Exception::InvalidParam' => {
        isa             => 'SimpleDB::Class::Exception',
        description     => 'This method should be overridden by subclasses.',
        fields          => ['name', 'value'],
        },
    'SimpleDB::Class::Exception::ObjectNotFound' => {
        isa             => 'SimpleDB::Class::Exception',
        description     => "The object you were trying to retrieve does not exist.",
        fields          => ['id'],
        },
    'SimpleDB::Class::Exception::InvalidObject' => {
        isa             => 'SimpleDB::Class::Exception::ObjectNotFound',
        description     => "The object you were trying to retrieve does not exist.",
        },
    'SimpleDB::Class::Exception::Connection' => {
        isa             => 'SimpleDB::Class::Exception',
        description     => "There was a problem establishing a connection.",
        fields          => ['status_code'],
        },

);

=head1 LEGAL

SimpleDB::Class is Copyright 2009-2010 Plain Black Corporation (L<http://www.plainblack.com/>) and is licensed under the same terms as Perl itself.

=cut

1;