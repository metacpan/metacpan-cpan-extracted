#!/usr/bin/env perl
use Test::Most;
use Path::Class ();
use_ok('Net::Amazon::SNS::Signature');

my $message = {
    'Message' => 'I am a message',
    'SignatureVersion' => '1',
    'Signature' => 'IdWLjL+8QsLnm4zMEM6JMRcPyPNE4OxLbMxI8JUgjpLML4Ady2CnzLjBHEZgQzLd/SMbE2o0QSyB38qYeYU0OWdqdAsh6lBWggDLfTCBapmnVLavs2aMqCjR3lWVoMT+Q4iYVCLrUvvMtgH+7W5937hIxVi3PWpgJM1xuRb5jH/aQiGSpaKpzsc+6ENMpDQzJ7v94yX94fM6A8R0o8WGI+AH1/8C6dktJjoJ6mnZbaoRMLm4R+3YRdHFJ5OTYF11/aDhoYLmpJoqPTLNY/TPSCAdwVrR/SssjCC81NPINJ0LO8rrkI7OOJxc74kykgWs+YFwEhBSs4LslBDYtMpU+g==',
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
