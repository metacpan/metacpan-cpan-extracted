use strict;
use warnings;
package SMS::Send::Retarus;
$SMS::Send::Retarus::VERSION = '0.001';
# ABSTRACT: SMS::Send driver for the Retarus SMS for Applications webservice

use Carp;
use HTTP::Tiny;
use URI::Escape qw( uri_escape );
use JSON::MaybeXS qw( decode_json encode_json JSON );
use Try::Tiny;
use Exception::Class (
    'SMS::Send::Retarus::Exception' => {
        fields  => [ 'response', 'status' ]
    },
);

use base 'SMS::Send::Driver';


sub new {
    my $class = shift;
    my $self = { @_ };

    $self->{$_}
        or croak "$_ missing"
            for qw( _login _password );

    return bless $self, $class;
}


sub send_sms {
    my ($self, %args) = @_;

    my $http = HTTP::Tiny->new(
        default_headers => {

            # to ensure the response is JSON
            'accept' => 'application/json; charset=utf-8',
            'content-type' => 'application/json; charset=utf-8',
        },
        timeout => 3,
        verify_ssl => 1,
    );

    my %message = (
        messages => [
            {
                text => $args{text},
                recipients => [
                    {
                        dst => $args{to},
                    }
                ],
            }
        ],
    );

    # add all underscore args without the underscore
    $message{$_} = $args{"_$_"}
        for map { $_ =~ s/^_//; $_; }
            grep { $_ =~ /^_/ } keys %args;

    my $response = $http->post(
        'https://'
        . uri_escape( $self->{_login} )
        . ':'
        . uri_escape( $self->{_password} )
        . '@sms4a.retarus.com/rest/v1/jobs',
        {
            content => encode_json(\%message),
        }
    );

    if ( $response->{success} ) {
        my $content;
        try {
            $content = decode_json( $response->{content} );
        }
        catch {
            SMS::Send::Retarus::Exception->throw(
                error => 'decoding of API response failed: ' . $_
            );
        };

        # return the API response which is a hashref which is always true and
        # conforms to the SMS::Send::Driver API but still enables a user to
        # get at additional data like the jobId
        return $content;
    }

    SMS::Send::Retarus::Exception->throw(
        error   => $response->{content},
        status  => $response->{status},
        # try to decode the body as it might contain an API error
        try { ( response => decode_json( $response->{content} ) ) },
    );
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SMS::Send::Retarus - SMS::Send driver for the Retarus SMS for Applications webservice

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    use SMS::Send;
    use Try::Tiny;
    my $sender = SMS::Send->new('Retarus',
        _login    => 'foo',
        _password => 'bar',
    );

    try {
        # $sent is always true because we throw exceptions on all failures
        my $sent = $sender->send_sms(
            to      => '+43123123456789',
            text    => 'This is a test message',
            # this becomes options in the REST call
            _options => {
                src => '+12345678901234567890' || 'CUSTOM_TEXT',
            }
        );

        # if you still want to conform to the SMS::Send::Driver API for the
        # case you change the driver
        if ( $sent ) {
            # $sent is a hashref containing everything the API returns
            print "Message sent ok: " . $sent->{jobId} . "\n";
        } else {
            # this API doesn't allow to know the reason of the failure
            # which is why this driver always throws exceptions as objects
            print "Failed to send message\n";
        }
    }
    catch {
        # $_ is a SMS::Send::Retarus::Exception object that stringifies to the
        # error message
        print "Failed to send message: $_\n";
    };

=head1 DESCRIPTION

This module currently uses the JSON REST API according to the Retarus
documentation from the 23rd March 2016.

=head1 METHODS

=head2 send_sms

Is called by L<SMS::Send/send_sms> and passes all arguments starting with an
underscore to the request having the first underscore removed as shown in the
SYNOPSIS above.
The list of supported options can be found in the Retarus SMS for Applications
documentation which sadly isn't publicly available.

Returns true if the message was successfully sent.

Throws a L</SMS::Send::Retarus::Exception> object if any error like a timeout
in the underlying connection occurred or the API didn't respond with a success
http status code.

=head1 SMS::Send::Retarus::Exception

All exceptions thrown are SMS::Send::Retarus::Exception objects subclassed
from L<Exception::Class>.
They stringify to the error message, which is also returned by the I<error>
and I<message> methods.
The other methods are I<response>, which contains the API response if it was
decodeable, and I<status> which is the status code of the HTTP response.

=head1 AUTHOR

Alexander Hartmaier <abraxxa@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Alexander Hartmaier.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
