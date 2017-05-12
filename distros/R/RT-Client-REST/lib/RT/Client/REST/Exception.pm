# We are going to throw exceptions, because we're cool like that.
package RT::Client::REST::Exception;
use base qw(Exception::Class);

use strict;
use warnings;

use vars qw($VERSION);
$VERSION = '0.19';

use Error;

use Exception::Class (
    'RT::Client::REST::OddNumberOfArgumentsException'   => {
        isa         => __PACKAGE__,
        description => "This means that we wanted name/value pairs",
    },

    'RT::Client::REST::InvaildObjectTypeException'   => {
        isa         => __PACKAGE__,
        description => "Invalid object type was specified",
    },

    'RT::Client::REST::MalformedRTResponseException'    => {
        isa         => __PACKAGE__,
        description => "Malformed RT response received from server",
    },

    'RT::Client::REST::InvalidParameterValueException'  => {
        isa         => __PACKAGE__,
        description => "This happens when you feed me bad values",
    },

    'RT::Client::REST::CannotReadAttachmentException'  => {
        isa         => __PACKAGE__,
        description => "Cannot read attachment",
    },

    'RT::Client::REST::RequiredAttributeUnsetException' => {
        isa         => __PACKAGE__,
        description => "An operation failed because a required attribute " .
                       "was not set in the object",
    },


    'RT::Client::REST::RTException' => {
        isa         => __PACKAGE__,
        fields      => ['code'],
        description => "RT server returned an error code",
    },

    'RT::Client::REST::ObjectNotFoundException' => {
        isa         => 'RT::Client::REST::RTException',
        description => 'One or more of the specified objects was not found',
    },

    'RT::Client::REST::CouldNotCreateObjectException' => {
        isa         => 'RT::Client::REST::RTException',
        description => 'Object could not be created',
    },

    'RT::Client::REST::AuthenticationFailureException'  => {
        isa         => 'RT::Client::REST::RTException',
        description => "Incorrect username or password",
    },

    'RT::Client::REST::UpdateException' => {
        isa         => 'RT::Client::REST::RTException',
        description => 'Error updating an object.  Virtual exception',
    },

    'RT::Client::REST::UnknownCustomFieldException' => {
        isa         => 'RT::Client::REST::RTException',
        description => 'Unknown custom field',
    },

    'RT::Client::REST::InvalidQueryException' => {
        isa         => 'RT::Client::REST::RTException',
        description => 'Invalid query (server could not parse it)',
    },

    'RT::Client::REST::CouldNotSetAttributeException' => {
        isa         => 'RT::Client::REST::UpdateException',
        description => 'Attribute could not be updated with a new value',
    },

    'RT::Client::REST::InvalidEmailAddressException' => {
        isa         => 'RT::Client::REST::UpdateException',
        description => 'Invalid e-mail address',
    },

    'RT::Client::REST::AlreadyCurrentValueException' => {
        isa         => 'RT::Client::REST::UpdateException',
        description => 'The attribute you are trying to update already has '.
                       'this value',
    },

    'RT::Client::REST::ImmutableFieldException' => {
        isa         => 'RT::Client::REST::UpdateException',
        description => 'Trying to update an immutable field',
    },

    'RT::Client::REST::IllegalValueException' => {
        isa         => 'RT::Client::REST::UpdateException',
        description => 'Illegal value',
    },

    'RT::Client::REST::UnauthorizedActionException' => {
        isa         => 'RT::Client::REST::RTException',
        description => 'You are not authorized to perform this action',
    },

    'RT::Client::REST::AlreadyTicketOwnerException' => {
        isa         => 'RT::Client::REST::RTException',
        description => 'The owner you are trying to assign to a ticket ' .
            'is already the owner',
    },

    'RT::Client::REST::RequestTimedOutException' => {
        isa         => 'RT::Client::REST::RTException',
        description => 'Request timed out',
    },

    'RT::Client::REST::UnknownRTException' => {
        isa         => 'RT::Client::REST::RTException',
        description => 'Some other RT error',
    },

    'RT::Client::REST::HTTPException'   => {
        isa         => __PACKAGE__,
        fields      => ['code'],
        description => "Error in the underlying protocol (HTTP)",
    },
);

sub _get_exception_class {
    my ($self, $content) = @_;

    if ($content =~ /not found|\d+ does not exist|[Ii]nvalid attachment id/) {
        return 'RT::Client::REST::ObjectNotFoundException';
    } elsif ($content =~ /not create/) {
        return 'RT::Client::REST::CouldNotCreateObjectException';
    } elsif ($content =~ /[Uu]nknown custom field/) {
        return 'RT::Client::REST::UnknownCustomFieldException';
    } elsif ($content =~ /[Ii]nvalid query/) {
        return 'RT::Client::REST::InvalidQueryException';
    } elsif ($content =~ /could not be set to/) {
        return 'RT::Client::REST::CouldNotSetAttributeException';
    } elsif ($content =~ /not a valid email address/) {
        return 'RT::Client::REST::InvalidEmailAddressException';
    } elsif ($content =~ /is already the current value/) {
        return 'RT::Client::REST::AlreadyCurrentValueException';
    } elsif ($content =~ /[Ii]mmutable field/) {
        return 'RT::Client::REST::ImmutableFieldException';
    } elsif ($content =~ /[Ii]llegal value/) {
        return 'RT::Client::REST::IllegalValueException';
    } elsif ($content =~ /[Yy]ou are not allowed/) {
        return 'RT::Client::REST::UnauthorizedActionException';
    } elsif ($content =~ /[Yy]ou already own this ticket/ ||
             $content =~ /[Tt]hat user already owns that ticket/)
    {
        return 'RT::Client::REST::AlreadyTicketOwnerException';
    } else {
        return 'RT::Client::REST::UnknownRTException';
    }
}

sub _rt_content_to_exception {
    my ($self, $content) = @_;

    (my $message = $content) =~ s/^#\s*//;
    chomp($message);

    return $self->_get_exception_class($content)->new(
        message => $message,
    );
}

# Some mildly weird magic to fix up inheritance (see Exception::Class POD).
{
    no strict 'refs';
    push @{__PACKAGE__ . '::ISA'}, 'Exception::Class::Base';
    push @Exception::Class::Base::ISA, 'Error'
        unless Exception::Class::Base->isa('Error');
}

1;

__END__

=head1 NAME

RT::Client::REST::Exception -- exceptions thrown by RT::Client::REST
methods.

=head1 DESCRIPTION

These are exceptions that are thrown by various L<RT::Client::REST>
methods.

=head1 EXCEPTION HIERARCHY

=over 2

=item B<RT::Client::REST::Exception>

This exception is virtual -- it is never thrown.  It is used to group
all the exceptions in this category.

=over 2

=item B<RT::Client::REST::OddNumberOfArgumentsException>

This means that the method you called wants key-value pairs.

=item B<RT::Client::REST::InvaildObjectTypeException>

Thrown when you specify an invalid type to C<show()>, C<edit()>, or
C<search()> methods.

=item B<RT::Client::REST::RequiredAttributeUnsetException>

An operation failed because a required attribute was not set in the object.

=item B<RT::Client::REST::MalformedRTResponseException>

RT server sent response that we cannot parse.  This may very well mean
a bug in this client, so if you get this exception, some debug information
mailed to the author would be appreciated.

=item B<RT::Client::REST::InvalidParameterValueException>

Invalid value for comments, link types, object IDs, etc.

=item B<RT::Client::REST::CannotReadAttachmentException>

Cannot read attachment (thrown from methods "comment()" and "correspond").

=item B<RT::Client::REST::RTException>

This is a virtual exception and is never thrown.  It is used to group
exceptions thrown because RT server returns an error.

=over 2

=item B<RT::Client::REST::ObjectNotFoundException>

One or more of the specified objects was not found.

=item B<RT::Client::REST::AuthenticationFailureException>

Incorrect username or password.

=item B<RT::Client::REST::UpdateException>

This is a virtual exception.  It is used to group exceptions thrown when
RT server returns an error trying to update an object.

=over 2

=item B<RT::Client::REST::CouldNotSetAttributeException>

For one or another reason, attribute could not be updated with the new
value.

=item B<RT::Client::REST::InvalidEmailAddressException>

Invalid e-mail address specified.

=item B<RT::Client::REST::AlreadyCurrentValueException>

The attribute you are trying to update already has this value.  I do not
know why RT insists on treating this as an exception, but since it does so,
so should the client.  You can probably safely catch and throw away this
exception in your code.

=item B<RT::Client::REST::ImmutableFieldException>

Trying to update an immutable field (such as "last_updated", for
example).

=item B<RT::Client::REST::IllegalValueException>

Illegal value for attribute was specified.

=back

=item B<RT::Client::REST::UnknownCustomFieldException>

Unknown custom field was specified in the request.

=item B<RT::Client::REST::InvalidQueryException>

Server could not parse the search query.

=item B<RT::Client::REST::UnauthorizedActionException>

You are not authorized to perform this action.

=item B<RT::Client::REST::AlreadyTicketOwnerException>

The owner you are trying to assign to a ticket is already the owner.
This exception is usually thrown by methods C<take()>, C<untake>, and
C<steal>, if the operation is a noop.

=item B<RT::Client::REST::RequestTimedOutException>

Request timed out.

=item B<RT::Client::REST::UnknownRTException>

Some other RT exception that the driver cannot recognize.

=back

=back

=back

=head1 METHODS

=over 2

=item B<_get_exception_class>

Figure out exception class based on content returned by RT.

=item B<_rt_content_to_exception>

Translate error string returned by RT server into an exception object
ready to be thrown.

=back

=head1 SEE ALSO

L<Exception::Class>,
L<RT::Client::REST>.

=head1 AUTHOR

Dmitri Tikhonov <dtikhonov@yahoo.com>

=cut
