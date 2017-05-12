use strict;
use warnings;
package SMS::Send::WebSMS;
$SMS::Send::WebSMS::VERSION = '0.001';
# ABSTRACT: SMS::Send driver for the WebSMS service

use Carp;
use HTTP::Tiny;
use URI::Escape qw( uri_escape );
use JSON::MaybeXS qw( decode_json encode_json JSON );

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

            # to ensure the response is JSON and not the XML default
            'accept' => 'application/json; charset=utf-8',
            'content-type' => 'application/json; charset=utf-8',
        },
        timeout => 3,
        verify_ssl => 1,
    );

    # remove leading +
    ( my $recipient = $args{to} ) =~ s/^\+//;

    my %message = (
        messageContent          => $args{text},
        recipientAddressList    => [ $recipient ],
    );

    # add all underscore args
    $message{$_} = $args{"_$_"}
        for map { $_ =~ s/^_//; $_; }
            grep { $_ =~ /^_/ } keys %args;

    my $response = $http->post(
        'https://'
        . uri_escape( $self->{_login} )
        . ':'
        . uri_escape( $self->{_password} )
        . '@api.websms.com/rest/smsmessaging/text',
        {
            content => encode_json(\%message),
        }
    );

    # for example a timeout error
    die $response->{content}
        unless $response->{success};

    my $response_message = decode_json( $response->{content} );

    # https://websms.at/entwickler/apis/rest-sms-api#dev-rest-statuscodes
    return 1
        if $response_message->{statusCode} =~ /^20\d\d/;

    $@ = $response_message;

    return 0;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SMS::Send::WebSMS - SMS::Send driver for the WebSMS service

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    use SMS::Send;
    my $sender = SMS::Send->new('WebSMS',
        _login    => 'foo',
        _password => 'bar',
    );

    my $sent = $sender->send_sms(
        'to'             => '+43123123456789',
        'text'           => 'This is a test message',
        '_senderAddress' => '43321987654321',
    );

    # Did the send succeed.
    if ( $sent ) {
        print "Message sent ok\n";
    } else {
        print 'Failed to send message: ', $@->{error_content}, "\n";
    }

=head1 DESCRIPTION

This module currently uses the L<REST API|https://websms.at/entwickler/apis/rest-sms-api> with JSON.

=head1 METHODS

=head2 send_sms

Is called by L<SMS::Send/send_sms> and passes all arguments starting with an
underscore to the request having the first underscore removed as shown in the
SYNOPSIS above.
The list of supported parameters can be found on the
L<WebSMS REST API website|https://websms.at/entwickler/apis/rest-sms-api#dev-rest-text-sms-senden-json-beispiel>.

Returns true if the message was successfully sent.

Returns false if an error occurred and $@ is set to a hashref of the following info:

    {
        clientMessageId => "...",
        transferId      => "...",
        statusMessage   => "...",
        statusCode      => "...",
    }

Throws an exception if a fatal error like a http timeout in the underlying
connection occurred.

=head1 AUTHOR

Alexander Hartmaier <abraxxa@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Alexander Hartmaier.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
