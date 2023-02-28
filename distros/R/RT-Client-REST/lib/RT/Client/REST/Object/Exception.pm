#!perl
# PODNAME: RT::Client::REST::Object::Exception

use strict;
use warnings;

package RT::Client::REST::Object::Exception;
$RT::Client::REST::Object::Exception::VERSION = '0.72';
use parent qw(RT::Client::REST::Exception);

use RT::Client::REST::Exception (
    'RT::Client::REST::Object::OddNumberOfArgumentsException'   => {
        isa         => __PACKAGE__,
        description => 'This means that we wanted name/value pairs',
    },

    'RT::Client::REST::Object::InvalidValueException' => {
        isa         => __PACKAGE__,
        description => 'Object attribute was passed an invalid value',
    },

    'RT::Client::REST::Object::NoValuesProvidedException' => {
        isa         => __PACKAGE__,
        description => 'Method expected parameters, but none were provided',
    },

    'RT::Client::REST::Object::InvalidSearchParametersException' => {
        isa         => __PACKAGE__,
        description => 'Invalid search parameters provided',
    },

    'RT::Clite::REST::Object::InvalidAttributeException' => {
        isa         => __PACKAGE__,
        description => 'Invalid attribute name',
    },

    'RT::Client::REST::Object::IllegalMethodException' => {
        isa         => __PACKAGE__,
        description => 'Illegal method is called on the object',
    },

    'RT::Client::REST::Object::NoopOperationException' => {
        isa         => __PACKAGE__,
        description => 'The operation was a noop',
    },

    'RT::Client::REST::Object::RequiredAttributeUnsetException' => {
        isa         => __PACKAGE__,
        description => 'An operation failed because a required attribute ' .
            'was not set in the object',
    },
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

RT::Client::REST::Object::Exception

=head1 VERSION

version 0.72

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023, 2020 by Dmitri Tikhonov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
