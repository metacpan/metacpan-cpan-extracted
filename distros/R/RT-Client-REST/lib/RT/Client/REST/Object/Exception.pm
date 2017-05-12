# RT::Client::REST::Object::Exception

package RT::Client::REST::Object::Exception;
use base qw(RT::Client::REST::Exception);

use strict;
use warnings;

use vars qw($VERSION);
$VERSION = '0.05';

use RT::Client::REST::Exception (
    'RT::Client::REST::Object::OddNumberOfArgumentsException'   => {
        isa         => __PACKAGE__,
        description => "This means that we wanted name/value pairs",
    },

    'RT::Client::REST::Object::InvalidValueException' => {
        isa         => __PACKAGE__,
        description => "Object attribute was passed an invalid value",
    },

    'RT::Client::REST::Object::NoValuesProvidedException' => {
        isa         => __PACKAGE__,
        description => "Method expected parameters, but none were provided",
    },

    'RT::Client::REST::Object::InvalidSearchParametersException' => {
        isa         => __PACKAGE__,
        description => "Invalid search parameters provided",
    },

    'RT::Clite::REST::Object::InvalidAttributeException' => {
        isa         => __PACKAGE__,
        description => "Invalid attribute name",
    },

    'RT::Client::REST::Object::IllegalMethodException' => {
        isa         => __PACKAGE__,
        description => "Illegal method is called on the object",
    },

    'RT::Client::REST::Object::NoopOperationException' => {
        isa         => __PACKAGE__,
        description => "The operation was a noop",
    },

    'RT::Client::REST::Object::RequiredAttributeUnsetException' => {
        isa         => __PACKAGE__,
        description => "An operation failed because a required attribute " .
            "was not set in the object",
    },
);

1;
