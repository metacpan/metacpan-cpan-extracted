# NAME

SMS::Send::NANP::Twilio - SMS::Send driver for Twilio

# SYNOPSIS

    Configure /etc/SMS-Send.ini

    [NANP::Twilio]
    AccountSid=AccountSid
    AuthToken=AuthToken
    MessagingServiceSid=String
    ;From=+12025550123
    ;StatusCallback=URL
    ;ApplicationSid=String
    ;MaxPrice=USD
    ;ProvideFeedback=true|false
    ;ValidityPeriod=14400

    use SMS::Send;
    my $sms     = SMS::Send->new('NANP::Twilio');
    my $success = $sms->send_sms(text=> 'Hello World!', to =>'+17035550123');

    use SMS::Send::NANP::Twilio;
    my $sms     = SMS::Send::NANP::Twilio->new;
    my $success = $sms->send_sms(text=> 'Hello World!', to =>'+17035550123');
    my $json    = $sms->{__content};
    my $href    = $sms->{__data};

# DESCRIPTION

SMS::Send driver for Twilio

# METHODS

## send\_sms

Sends SMS Message via Twilio web service and returns 1 or 0. Method dies on critical error.

    my $status = $sms->send_sms(to =>'+17035550123', text=> 'Hello World!');
    my $status = $sms->send_sms(to =>'+17035550123', text=> 'Image Attached', MediaUrl=>'https://...');

- to

    Passed as "To" in the posted form data. The destination phone number for SMS/MMS or a Channel user address for other 3rd party channels. Destination phone numbers should be formatted with a '+' and country code e.g., +16175550123 (E.164 format).

        to => "+17035550123"

- text

    Passed as "Body" in the posted form data. The text of the message you want to send, limited to 1600 characters.

        text => "My Message Body"

- MediaUrl

    The URL of the media you wish to send out with the message. gif, png, and jpeg content is currently supported and will be formatted correctly on the recipient's device. Other types are also accepted by the API. The media size limit is 5MB. If you wish to send more than one image in the message body, please provide multiple MediaUrls values in an array reference. You may include up to 10 MediaUrls per message.

        MediaUrl => "https://...."
        MediaUrl => [$url1, $url2, ...]

# PROPERTIES

Properties may be stored in Current Directory, /etc/SMS-Send.ini or C:\\Windows\\SMS-Send.ini. See [SMS::Send::Driver::WebService](https://metacpan.org/pod/SMS::Send::Driver::WebService)->cfg\_path

## url

Returns the url for the Twilio versioned service.

    Default: https://api.twilio.com/2010-04-01

## AccountSid

The "AccountSID" is passed on the URL and sent as the username for basic authentication credentials

## AuthToken

The "AuthToken" sent as password for basic authentication credentials

## From

The "From" parameter passed in the posted form

A Twilio phone number (in E.164 format), alphanumeric sender ID or a Channel Endpoint address enabled for the type of message you wish to send. Phone numbers or short codes purchased from Twilio work here. You cannot (for example) spoof messages from your own cell phone number.

## MessagingServiceSid

The "MessagingServiceSid" parameter passed in the posted form

The 34 character unique id of the Messaging Service you want to associate with this Message. Set this parameter to use the Messaging Service Settings and Copilot Features you have configured. When only this parameter is set, Twilio will use your enabled Copilot Features to select the from phone number for delivery.

## StatusCallback

The "StatusCallback" parameter passed in the posted form

A URL where Twilio will POST each time your message status changes to one of the following: queued, failed, sent, delivered, or undelivered. Twilio will POST the MessageSid along with the other standard request parameters as well as MessageStatus and ErrorCode. If this parameter passed in addition to a MessagingServiceSid, Twilio will override the Status Callback URL of the Messaging Service. URLs must contain a valid hostname (underscores are not allowed).

## ApplicationSid

The "ApplicationSid" parameter passed in the posted form

Twilio will POST MessageSid as well as MessageStatus=sent or MessageStatus=failed to the URL in the MessageStatusCallback property of this Application. If the StatusCallback parameter above is also passed, the Application's MessageStatusCallback parameter will take precedence.

## MaxPrice

The "MaxPrice" parameter passed in the posted form

The total maximum price up to the fourth decimal (0.0001) in US dollars acceptable for the message to be delivered. All messages regardless of the price point will be queued for delivery. A POST request will later be made to your Status Callback URL with a status change of "Sent" or "Failed". When the price of the message is above this value the message will fail and not be sent. When MaxPrice is not set, all prices for the message is accepted.

## ProvideFeedback

The "ProvideFeedback" parameter passed in the posted form

Set this value to true if you are sending messages that have a trackable user action and you intend to confirm delivery of the message using the Message Feedback API. This parameter is set to false by default.

## ValidityPeriod

The "ValidityPeriod" parameter passed in the posted form

The number of seconds that the message can remain in a Twilio queue. After exceeding this time limit, the message will fail and a POST request will later be made to your Status Callback URL. Valid values are between 1 and 14400 seconds (the default). Please note that Twilio cannot guarantee that a message will not be queued by the carrier after they accept the message. We do not recommend setting validity periods of less than 5 seconds.

# SEE ALSO

[SMS::Send::Driver::WebService](https://metacpan.org/pod/SMS::Send::Driver::WebService), [SMS::Send](https://metacpan.org/pod/SMS::Send), [https://www.twilio.com/docs/api/messaging/send-messages](https://www.twilio.com/docs/api/messaging/send-messages)

# AUTHOR

Michael R. Davis

# COPYRIGHT AND LICENSE

MIT License

Copyright (c) 2022 Michael R. Davis
