package RedisDB::Parser;

use strict;
use warnings;
our $VERSION = "2.22";
$VERSION = eval $VERSION;

use Try::Tiny;

my $implementation;

unless ( $ENV{REDISDB_PARSER_PP} ) {
    try {
        require RedisDB::Parser::XS;
        $implementation = "RedisDB::Parser::XS";
    }
}

unless ($implementation) {
    require RedisDB::Parser::PP;
    $implementation = "RedisDB::Parser::PP";
}

=head1 NAME

RedisDB::Parse::Redis - redis protocol parser for RedisDB

=head1 SYNOPSIS

    use RedisDB::Parser;
    my $parser = RedisDB::Parser->new( master => $ref );
    $parser->push_callback(\&cb);
    $parser->parse($data);

=head1 DESCRIPTION

This module provides methods to build redis requests and parse replies from
the server.

=head1 METHODS

=head2 $class->new(%params)

Creates new parser object. Following parameters may be specified:

=over 4

=item B<master>

Arbitrary reference. It is passed to callbacks as the first argument. Normally
it would be a reference to the object managing connection to redis-server.
Reference is weakened.

=item B<default_callback>

Module allows you to set a separate callback for every new message. If there
are no callbacks in queue, default_callback will be used.

=item B<utf8>

If this parameter is set all data will be encoded as UTF-8 when building
requests, and decoded from UTF-8 when parsing replies. By default module
expects all data to be octet sequences.

=item B<error_class>

If parsed message is an error message, parser will create object of the
specified class with the message as the only constructor argument, and pass
this object to the callback. By default L<RedisDB::Parser::Error> class is
used.

=back

=cut

sub new {
    shift;
    return $implementation->new(@_);
}

=head2 $class->implementation

Returns name of the package that actually implements parser functionality. It
may be either L<RedisDB::Parser::PP> or L<RedisDB::Parser::XS>.

=cut

sub implementation {
    return $implementation;
}

=head2 $self->build_request($command, @arguments)

Encodes I<$command> and I<@arguments> as redis request.

=head2 $self->push_callback(\&cb)

Pushes callback to the queue of callbacks.

=head2 $self->set_default_callback(\&cb)

Set callback to invoke when there are no callbacks in queue.

=head2 $self->callbacks

Returns true if there are callbacks in queue

=head2 $self->propagate_reply($reply)

Invoke every callback from queue and the default callback with the given
I<$reply>. Can be used e.g. if connection to server has been lost to invoke
every callback with error message.

=head2 $self->parse($data)

Process new data received from the server. For every new reply method will
invoke callback, either the one from the queue that was added using
I<push_callback> method, or default callback if the queue is empty. Callback
passed two arguments: master value, and decoded reply from the server.

Method returns the number of parsed replies.

=cut

=head1 PARSING

Here's how the parser represents replies from redis-server:

=head2 Status reply

Status replies are represented by string values without the initial plus sign
and final end of the line symbols. I.e. "+OK" reply from the server will be
parsed into "OK" string that will be passed to callback.

=head2 Error reply

Error replies are represents as objects of I<error_class>, which is by default
L<RedisDB::Parser::Error>. If parser detects error reply, it strips it off
initial minus sign and final end of the line, and then passes result as sole
argument to the I<new> method of the I<error_class>. This is the only case when
parser produces blessed reference, and so callback may easily detect error
condition by checking this.

=head2 Integer reply

Parser represents integer reply as a scalar value

=head2 Bulk reply

Parser represents bulk replies as scalar values. By default it treats result as
a sequence of bytes, but if I<utf8> options is set it decodes result from UTF-8
and may croak if result is not a valid UTF-8 sequence. NULL bulk reply is
represented as undefined value.

=head2 Multi-bulk reply

Multi-bulk replies are returned as array references. Empty multi-bulk reply is
represented as reference to empty array. Null multi-bulk reply is represented
as undefined scalar.

=cut

1;

__END__

=head1 SEE ALSO

Redis protocol specification: L<http://redis.io/topics/protocol>

Redis client library that uses this parser: L<RedisDB>

Other Perl modules that parse redis protocol:
L<Protocol::Redis>, L<Protocol::Redis::XS>, L<Redis::Parser::XS>

=head1 AUTHOR

Pavel Shaydo C<< <zwon at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2011-2015 Pavel Shaydo.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
