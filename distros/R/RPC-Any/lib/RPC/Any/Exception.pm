package RPC::Any::Exception;
use Moose;

use overload '""' => \&stringify;

has code    => (is => 'rw', isa => 'Int', required => 1);
has message => (is => 'rw', isa => 'Str', required => 1);

# This is used in case an exception ever propagates all the way to the user
# without being translated properly by the server.
sub stringify {
    my $self = shift;
    return $self->code . ": " . $self->message;
}

__PACKAGE__->meta->make_immutable;

# All the error codes in standard exceptions are from
# http://xmlrpc-epi.sourceforge.net/specs/rfc.fault_codes.php

package RPC::Any::Exception::PerlError;
use Moose;
extends 'RPC::Any::Exception';
has '+code' => (default => -32603);
__PACKAGE__->meta->make_immutable;

package RPC::Any::Exception::HTTPError;
use Moose;
extends 'RPC::Any::Exception';
has '+code' => (default => -32300);
__PACKAGE__->meta->make_immutable;

package RPC::Any::Exception::ParseError;
use Moose;
extends 'RPC::Any::Exception';
has '+code' => (default => -32700);
__PACKAGE__->meta->make_immutable;

package RPC::Any::Exception::NoSuchMethod;
use Moose;
extends 'RPC::Any::Exception';
has '+code' => (default => -32601);
__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

RPC::Any::Exception - A throwable exception object for RPC::Any

=head1 SYNOPSIS

 use RPC::Any::Exception;
 die RPC::Any::Exception(code => 1234, message => "I'm dead!");

=head1 DESCRIPTION

This object represents an exception that an RPC::Any::Server can throw.
See L<RPC::Any::Server/ERROR HANDLING> for information about how to use
this in your own code.

=head1 BUILT-IN ERRORS

There are various types of built-in errors that an RPC::Any::Server
can throw. They have specific error codes that correlate with the
error codes specified at
L<http://xmlrpc-epi.sourceforge.net/specs/rfc.fault_codes.php> (which
are valid for both JSON-RPC and XML-RPC).

What follows is a brief description of each type of error (which is
a subclass of RPC::Any::Exception) and its numeric code:

=head2 RPC::Any::Exception::PerlError

B<Code>: -32603

Something called "die" with something that wasn't an RPC::Any::Exception.
This is just a basic Perl error. The message will be the error that "die"
threw.

=head2 RPC::Any::Exception::HTTPError

B<Code:> -32300

There was a problem with the HTTP protocol on the input. The
message will have more details.

=head2 RPC::Any::Exception::ParseError

B<Code>: -32700

There was an error parsing the input for the RPC protocol. The
message will have more details.

=head2 RPC::Any::Exception::NoSuchMethod

B<Code>: -32601

The RPC request contained an invalid method. The message will
have more details.