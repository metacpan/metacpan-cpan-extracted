# NAME

Net::Amazon::SNS::Signature

# DESCRIPTION

For the verification of Amazon SNS messages

# USAGE

    # Will download the signature certificate from SigningCertURL attribute of $message_ref
    # use LWP::UserAgent
    my $sns_signature = Net::Amazon::SNS::Signature->new();
    if ( $sns_signature->verify( $message_ref ) ){ ... }

    # Will automatically download the certificate using your own user_agent ( supports ->get returns HTTP::Response )
    my $sns_signature = Net::Amazon::SNS::Signature->new( user_agent => $my_user_agent );
    if ( $sns_signature->verify( $message_ref ) ){ ... }

    # Provide the certificate yourself
    my $sns_signature = Net::Amazon::SNS::Signature->new()
    if ( $sns_signature->verify( $message_ref, $x509_cert ) ) { ... }

## verify

Call to verify the message, `$message_ref` is required as first parameter and should be
a hash ref, `$x509_cert` is optional and should be a raw x509 certificate as downloaded 
from Amazon.

See [http://docs.aws.amazon.com/sns/latest/dg/SendMessageToHttp.verify.signature.html](http://docs.aws.amazon.com/sns/latest/dg/SendMessageToHttp.verify.signature.html) for
information on the content of a message

Usage:

    my $is_verified = $this->verify({
        Message         => 'My Test Message',
        MessageId       => '4d4dc071-ddbf-465d-bba8-08f81c89da64',
        Subject         => 'My subject',
        Timestamp       => '2012-06-05T04:37:04.321Z',
        TopicArn        => 'arn:aws:sns:us-east-1:123456789012:s4-MySNSTopic-1G1WEFCOXTC0P',
        Type            => 'Notification',
        Signature       => 'EXAMPLElDMXvB8r9R83tGoNn0ecwd5UjllzsvSvbItzfaMpN2nk5HVSw7XnOn',
        SigningCertURL  => 'https://sns.us-west-2.amazonaws.com/SimpleNotificationService-f3e'
    });

## build\_sign\_string

Given a `$message_ref` will return a formatted string ready to be signed.

Usage:

    my $sign_string = $this->build_sign_string({
        Message     => 'Hello',
        MessageId   => '12345',
        Subject     => 'I am a message',
        Timestamp   => '2016-01-20T14:37:01Z',
        TopicArn    => 'xyz123',
        Type        => 'Notification'
    });
