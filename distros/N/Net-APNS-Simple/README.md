# NAME

Net::APNS::Simple - APNS Perl implementation

# DESCRIPTION

A Perl implementation for sending notifications via APNS using Apple's new HTTP/2 API.
This library uses Protocol::HTTP2::Client as http2 backend.
And it also supports multiple stream at one connection.
(It does not correspond to parallel stream because APNS server returns SETTINGS\_MAX\_CONCURRENT\_STREAMS = 1.)

# SYNOPSIS

    use Net::APNS::Simple;

    # With provider authentication tokens
    my $apns = Net::APNS::Simple->new(
        # enable if development
        # development => 1,
        auth_key => '/path/to/auth_key.p8',
        key_id => 'AUTH_KEY_ID',
        team_id => 'APP_PREFIX',
        bundle_id => 'APP_ID',
    );

    # With SSL certificates
    my $apns = Net::APNS::Simple->new(
        # enable if development
        # development => 1,
        cert_file => '/path/to/cert.pem',
        key_file => '/path/to/key.pem',
        passwd_cb => sub { return 'key-password' },
        bundle_id => 'APP_ID',
    );

    # 1st request
    $apns->prepare('DEVICE_ID',{
            aps => {
                alert => 'APNS message: HELLO!',
                badge => 1,
                sound => "default",
                # SEE: https://developer.apple.com/jp/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/Chapters/TheNotificationPayload.html,
            },
        }, sub {
            my ($header, $content) = @_;
            require Data::Dumper;
            print Dumper $header;

            # $VAR1 = [
            #           ':status',
            #           '200',
            #           'apns-id',
            #           '791DE8BA-7CAA-B820-BD2D-5B12653A8DF3'
            #         ];

            print Dumper $content;

            # $VAR1 = undef;
        }
    );

    # 2nd request
    $apns->prepare(...);

    # also supports method chain
    # $apns->prepare(1st request)->prepare(2nd request)....

    # send notification
    $apns->notify();

# METHODS

## my $apns = Net::APNS::Simple->new(%arg)

- development : bool

    Switch API's URL to 'api.sandbox.push.apple.com' if enabled.

- auth\_key : string

    Private key file for APNS obtained from Apple.

- team\_id : string

    Team ID (App Prefix)

- bundle\_id : string

    Bundle ID (App ID)

- cert\_file : string

    SSL certificate file.

- key\_file : string

    SSL key file.

- passwd\_cb : sub reference

    If the private key is encrypted, this should be a reference to a subroutine that should return the password required to decrypt your private key.

- apns\_id : string

    Canonical UUID that identifies the notification (apns-id header).

- apns\_expiration : number

    Sets the apns-expiration header.

- apns\_priority : number

    Sets the apns-priority header. Default 10.

- apns\_collapse\_id : string

    Sets the apns-collapse-id header.

- apns\_push\_type : string

    Sets the apns-push-type header.

- proxy : string

    URL of a proxy server. Default $ENV{https\_proxy}. Pass undef to disable proxy.

    All properties can be accessed as Getter/Setter like `$apns->development`.

## $apns->prepare($DEVICE\_ID, $PAYLOAD);

Prepare notification.
It is possible to specify more than one. Please do before invoking notify method.

    $apns->prepare(1st request)->prepare(2nd request)....

Payload please refer: https://developer.apple.com/library/content/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/PayloadKeyReference.html#//apple\_ref/doc/uid/TP40008194-CH17-SW1.

## $apns->notify();

Execute notification.
Multiple notifications can be executed with one SSL connection.

# LICENSE

Copyright (C) Tooru Tsurukawa.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Tooru Tsurukawa &lt;rockbone.g at gmail.com>
