#!/usr/bin/env perl
use Test::Most;
use Path::Class ();
use_ok('Net::Amazon::SNS::Signature');

my $message = {
    'Message' => 'I am a message',
    'SignatureVersion' => '1',
    'Signature' => 'JhYKG76+i5nzYJ4YJhrXJWQhaBb8SwDeESscpzdCGZ4SBMrscoTLKjigsJawqN98/GiyJI+rpNXnNIahX/PlE7xZ/l48T4DCC097wtgOjcvqRqPer2pH4sRjM/pWkpyg4gGOiQY6a1kqo71FkzsjLI6hBsr6btn3ryNv0C6LiCna3MojLep/dd4x6wwJpAPLFMkMnDVCGW7UX75mw08Aup1Jum5ACn19be09CEREAh6ZH18/Nachesx7hnTZr8NsBdh5IjcJi6ot3VzeK96Hbm+OIN5iSXfKma4ypTBAL+6O8hnUQXFz1zxVsMAYZs8VX2/GpRkW/7SvtUr0d+HoTA==',
    'Timestamp' => '2016-03-15T12:08:48.856Z',
    'TopicArn' => 'arn:aws:sns:eu-west-1:12345:test',
    'Subject' => 'This is the subject',
    'MessageId' => '12345-abcdef',
    'Type' => 'Notification',
    'UnsubscribeURL' => 'http://www.example.com',
    'SigningCertURL' => 'http://www.example.com',
};

my $sns_sign = Net::Amazon::SNS::Signature->new();
my $string = Path::Class::file('t/share/cert.pem')->slurp();
is ( $sns_sign->verify( $message, $string ), 1 );

done_testing();
