use Test::More tests => 5;

use utf8;
use strict;
use warnings;

use Encode;

use File::Basename qw(dirname);

use_ok('Net::AS2');
my $cert_dir = dirname(__FILE__);

my %config_1 = (
    CertificateDirectory => $cert_dir,
    MyId => 'Mr 1', MyKeyFile => 'test.1.key', MyCertificateFile => 'test.1.cert',
    PartnerId => 'Mr 2', PartnerCertificateFile => 'test.2.cert',
    PartnerUrl => 'http://example.com/dummy/a_2/msg',
    UserAgentClass => 'Mock::LWP::UserAgent',
);

my %config_2 = (
    CertificateDirectory => $cert_dir,
    MyId => 'Mr 2', MyKeyFile => 'test.2.key', MyCertificateFile => 'test.2.cert',
    PartnerId => 'Mr 1', PartnerCertificateFile => 'test.1.cert',
    PartnerUrl => 'http://example.com/dummy/a_1/msg',
    UserAgentClass => 'Mock::LWP::UserAgent',
);

my $test_async = sub {
    my ($mod) = @_;
    my $a1 = Net::AS2->new(%config_1,
        Mdn => 'async',
        MdnAsyncUrl => 'http://example.com/dummy/a_1/mdn',
        %{$mod}
    );

    my $a2 = Net::AS2->new(%config_2, %{$mod});

    my $data = "测试\nThis is a test\r\n\x01\x02\x00";
    my $message_id = rand . '@' . 'localhost';

    my ($mdn_temp, $mic1, $mic1_alg) = $a1->send($data, 'Type' => 'text/plain', 'MessageId' => $message_id);
    ok($mdn_temp->is_unparsable, 'ASYNC data unparsable');
    my $req = $Mock::LWP::UserAgent::last_request;

    my $msg = $a2->decode_message($req->headers, $req->content);

    ok($msg->is_success, 'Message received successfully');
    ok($msg->is_mdn_async, 'MDN is async');
    is($msg->async_url, 'http://example.com/dummy/a_1/mdn');
    is(decode('utf8', $msg->content), $data, 'Content matches');
    is($mic1, $msg->mic, 'MIC matches');

    $a2->send_async_mdn(Net::AS2::MDN->create_success($msg));

    my $mdn_req = $Mock::LWP::UserAgent::last_request;
    my $mdn = $a1->decode_mdn($mdn_req->headers, $mdn_req->content);
    ok($mdn->is_success, 'MDN is success');
    ok($mdn->match_mic($mic1, $mic1_alg), 'MDN MIC matches');
    is($mdn->original_message_id, $message_id, 'MDN message id matches');
};

subtest 'Send and Async - Signature + Encryption' => sub { $test_async->({}); };
subtest 'Send and Async - Signature Only ' => sub { $test_async->({ Encryption => 0 }); };
subtest 'Send and Async - Encryption Only' => sub { $test_async->({ Signature => 0 }); };
subtest 'Send and Async - Plain' => sub { $test_async->({ Encryption => 0, Signature => 0 }); };


package Mock::LWP::UserAgent;

use parent 'LWP::UserAgent';

use HTTP::Response;

our $response_handler;
our $last_request;

sub request
{
    my $class = shift;
    $last_request = shift;
    return $response_handler->($last_request)
        if $response_handler;
    return HTTP::Response->new(200, 'OK', ['Context-Text' => 'text/html'], '');
}

1;
