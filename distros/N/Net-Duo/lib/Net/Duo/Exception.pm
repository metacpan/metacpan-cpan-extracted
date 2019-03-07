# Rich exception object for Net::Duo actions.
#
# All Net::Duo APIs throw Net::Duo::Exception objects on any failure,
# including internal errors, protocol errors, HTTP errors, and failures
# returned by the Duo API.  This is a rich exception object that carries all
# available details about the failure and can be inspected by the caller to
# recover additional information.  If the caller doesn't care about the
# details, it provides a stringification that is suitable for simple error
# messages.
#
# SPDX-License-Identifier: MIT

package Net::Duo::Exception 1.02;

use 5.014;
use strict;
use warnings;

use HTTP::Response;

# Enable this object to be treated like a string scalar.
use overload '""' => \&to_string, 'cmp' => \&spaceship;

##############################################################################
# Constructors
##############################################################################

# Construct an exception from a Duo error reply.  If the provided object
# does not have a stat key with a value of FAIL, this call will be
# converted automatically to a call to protocol().
#
# $class   - Class of the exception to create
# $object  - The decoded JSON object representing the error reply
# $content - The undecoded content of the server reply
#
# Returns: Newly-constructed exception
sub api {
    my ($class, $object, $content) = @_;

    # Ensure that we have a valid stat key.
    if (!defined($object->{stat})) {
        return $class->protocol('missing stat value in JSON reply', $content);
    } elsif ($object->{stat} ne 'FAIL') {
        my $e = $class->protocol('invalid stat value', $content);
        $e->{detail} = $object->{stat};
        return $e;
    }

    # Set the exception information from the JSON object.
    my $self = {
        code    => $object->{code}    // 50000,
        message => $object->{message} // 'missing error message',
        detail  => $object->{message_detail},
        content => $content,
    };

    # Create the object and return it.
    bless($self, $class);
    return $self;
}

# Construct an exception from an HTTP::Response object.
#
# $class    - Class of the exception to create
# $response - An HTTP::Response object representing the failure
#
# Returns: Newly-constructed exception
sub http {
    my ($class, $response) = @_;
    my $self = {
        code    => $response->code() . '00',
        message => $response->message(),
        content => $response->decoded_content(),
    };
    bless($self, $class);
    return $self;
}

# Construct an exception for an internal error from a simple message.
#
# $class   - Class of the exception to create
# $message - The error message
#
# Returns: Newly-constructed exception
sub internal {
    my ($class, $message) = @_;
    my $self = {
        code    => 50000,
        message => $message,
    };
    bless($self, $class);
    return $self;
}

# Construct an exception that propagates another internal exception.
# Convert it to a string when propagating it, and remove the file and line
# information if present.
#
# $class     - Class of the exception to create
# $exception - Exception to propagate
#
# Returns: Newly-constructed exception
sub propagate {
    my ($class, $exception) = @_;
    $exception =~ s{ [ ] at [ ] \S+ [ ] line [ ] \d+[.]? \n+ \z }{}xms;
    return $class->internal($exception);
}

# Construct an exception for a protocol failure, where we got an HTTP
# success code but couldn't parse the result or couldn't find the JSON
# keys that we were expecting.
#
# $class   - Class of the exception to create
# $message - Error message indicating what's wrong
# $reply   - The content of the HTTP reply
#
# Returns: Newly-created exception
sub protocol {
    my ($class, $message, $reply) = @_;
    my $self = {
        code    => 50000,
        message => $message,
        content => $reply,
    };
    bless($self, $class);
    return $self;
}

##############################################################################
# Accessors and overloads
##############################################################################

# Basic accessors.
sub code    { my $self = shift; return $self->{code} }
sub content { my $self = shift; return $self->{content} }
sub detail  { my $self = shift; return $self->{detail} }
sub message { my $self = shift; return $self->{message} }

# The cmp implmenetation converts the exception to a string and then compares
# it to the other argument.
#
# $self  - Net::Duo::Exception object
# $other - The other object (generally a string) to which to compare it
# $swap  - True if the order needs to be swapped for a proper comparison
#
# Returns: -1, 0, or 1 per the cmp interface contract
sub spaceship {
    my ($self, $other, $swap) = @_;
    my $string = $self->to_string;
    if ($swap) {
        return ($other cmp $string);
    } else {
        return ($string cmp $other);
    }
}

# A verbose message with all the information from the exception except for
# the full content of the reply.
#
# $self - Net::Duo::Exception
#
# Returns: A string version of the exception information.
sub to_string {
    my ($self)  = @_;
    my $code    = $self->{code};
    my $detail  = $self->{detail};
    my $message = $self->{message};

    # Our verbose format is the message, followed by the detail in
    # parentheses if available, and then the error code in brackets.
    my $result = $message;
    if (defined($detail)) {
        $result .= " ($detail)";
    }
    $result .= " [$code]";
    return $result;
}

1;
__END__

=for stopwords
LWP libwww perl JSON CPAN API APIs stringification malformated unparsable
cmp sublicense MERCHANTABILITY NONINFRINGEMENT Allbery multifactor undecoded

=head1 NAME

Net::Duo::Exception - Rich exception object for Net::Duo failures

=head1 SYNOPSIS

    use 5.010;

    # Use by a caller of the Net::Duo API.
    my $duo = Net::Duo->new({ key_file => '/path/to/keys.json' });
    if (!eval { $duo->check() }) {
        my $e = $@;
        say 'Code: ', $e->code();
        say 'Message: ', $e->message();
        say 'Detail: ', $e->detail();
        print "\nFull reply content:\n", $e->content();
    }

    # Use internally by Net::Duo objects.
    die Net::Duo::Exception->propagate($@);
    die Net::Duo::Exception->internal('some error message');
    my $response = some_http_call();
    die Net::Duo::Exception->http($response);
    my $reply = some_duo_call();
    die Net::Duo::Exception->protocol('error message', $reply);
    die Net::Duo::Exception->api($reply);

=head1 REQUIREMENTS

Perl 5.14 or later and the module HTTP::Message, which is available from
CPAN.

=head1 DESCRIPTION

Net::Duo::Exception is a rich representation of errors from any Net::Duo
API.  All Net::Duo APIs throw Net::Duo::Exception objects on any failure,
including internal errors, protocol errors, HTTP errors, and failures
returned by the Duo API.  This object carries all available details about
the failure and can be inspected by the caller to recover additional
information.  If the caller doesn't care about the details, it provides a
stringification that is suitable for simple error messages.

=head1 CLASS METHODS

All class methods are constructors.  These are primarily for the internal
use of Net::Duo classes to generate the exception and will normally not be
called by users of Net::Duo.  Each correspond to a type of error and tell
Net::Duo::Exception what data to extract to flesh out the exception
object.

=over 4

=item api(OBJECT, CONTENT)

Creates an exception for a Duo API failure.  OBJECT should be the JSON
object (decoded as a hash) returned by the Duo API call, and CONTENT
should be the undecoded text.  This exception constructor should be used
whenever possible, since it provides the most useful information.

=item http(RESPONSE)

Creates an exception from an HTTP::Response object, RESPONSE.  This
exception constructor should be used for calls that fail at the HTTP
protocol level without getting far enough to return JSON.

=item internal(MESSAGE)

Creates an exception for some internal failure that doesn't involve an
HTTP request to the Duo API.  In this case, the code will always be set
to 50000: the normal 500 code for an internal server error plus the two
additional digits Duo normally adds to the code.

=item propagate(EXCEPTION)

Very similar to internal(), except that the argument is assumed to be
another exception.  The resulting error message will be cleaned of
uninteresting location information before being passed to internal().

=item protocol(MESSAGE, REPLY)

Creates an exception for a protocol failure.  This should be used when
a call returns unexpected or malformated data, such as invalid JSON or
JSON with missing data fields.  MESSAGE should be an informative error
message, and REPLY should be the content of the unparsable reply.

=back

=head1 INSTANCE METHODS

These are the methods most commonly called by programs that use the
Net::Duo module.  They return various information from the exception.

=over 4

=item code()

Returns the Duo error code for this error, or 50000 for internally
generated errors.  The Duo code is conventionally an HTTP code followed
by two additional digits to create a unique error code.

=item content()

The full content of the reply from the Duo API that triggered the error.
This is not included in the default string error message, but may be
interesting when debugging problems.

=item detail()

Any additional (generally short) detail that might clarify the error
message.  This corresponds to the C<message_detail> key in the Duo
error response.

=item message()

The error message.

=item spaceship([STRING], [SWAP])

This method is called if the exception object is compared to a string via
cmp.  It will compare the given string to the verbose error message and
return the result.  If SWAP is set, it will reverse the order to compare
the given string to the verbose error.  (This is the normal interface
contract for an overloaded C<cmp> implementation.)

=item to_string()

This method is called if the exception is interpolated into a string.  It
can also be called directly to retrieve the default string form of the
exception.

=back

=head1 AUTHOR

Russ Allbery <rra@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2014 The Board of Trustees of the Leland Stanford Junior
University

Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the "Software"),
to deal in the Software without restriction, including without limitation
the rights to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL
THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.

=head1 SEE ALSO

L<Net::Duo>

This module is part of the Net::Duo distribution.  The current version of
Net::Duo is available from CPAN, or directly from its web site at
L<https://www.eyrie.org/~eagle/software/net-duo/>.

=cut

# Local Variables:
# copyright-at-end-flag: t
# End:
