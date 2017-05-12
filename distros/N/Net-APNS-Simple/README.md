# NAME

Net::APNS::Simple - APNS Perl implementation

# DESCRIPTION

A Perl implementation for sending notifications via APNS using Apple's new HTTP/2 API.
This library uses Protocol::HTTP2::Client as http2 backend.
And it also supports multiple stream at one connection.
(It does not correspond to parallel stream because APNS server returns SETTINGS\_MAX\_CONCURRENT\_STREAMS = 1.)

    You can not use the key obtained from Apple at the moment, see the item of Caution below.

# SYNOPSIS

    use Net::APNS::Simple;

    my $apns = Net::APNS::Simple->new(
        # enable if development
        # development => 1,
        auth_key => '/path/to/auth_key.p8',
        key_id => 'AUTH_KEY_ID',
        team_id => 'APP_PREFIX',
        bundle_id => 'APP_ID',
        apns_expiration => 0,
        apns_priority => 10,
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

    Switch API's URL to 'api.development.push.apple.com' if enabled.

- auth\_key : string

    Private key file for APNS obtained from Apple.

- team\_id : string

    Team ID (App Prefix)

- bundle\_id : string

    Bundle ID (App ID)

- apns\_expiration : number

    Default 0.

- apns\_priority : number

    Default 10.

    All properties can be accessed as Getter/Setter like `$apns->development`.

## $apns->prepare($DEVICE\_ID, $PAYLOAD);

Prepare notification.
It is possible to specify more than one. Please do before invoking notify method.

    $apns->prepare(1st request)->prepare(2nd request)....

Payload please refer: https://developer.apple.com/library/content/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/PayloadKeyReference.html#//apple\_ref/doc/uid/TP40008194-CH17-SW1.

## $apns->notify();

Execute notification.
Multiple notifications can be executed with one SSL connection.

# CAUTION

Crypt::PK::ECC can not import the key obtained from Apple as it is. This is currently being handled as Issue. Please use the openssl command to specify the converted key as follows until the modified version appears.

    openssl pkcs8 -in APNs-apple.p8 -inform PEM -out APNs-resaved.p8 -outform PEM -nocrypt

# LICENSE

Copyright (C) Tooru Tsurukawa.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Tooru Tsurukawa &lt;rockbone.g at gmail.com>
