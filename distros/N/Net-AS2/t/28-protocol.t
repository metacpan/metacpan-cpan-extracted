use Test::More tests => 5;

use utf8;
use strict;
use warnings;

use Encode;
use HTTP::Response;
use HTTP::Headers;

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


subtest 'Missing headers' => sub {
    my $a1 = Net::AS2->new(%config_1);

    my $msg = $a1->decode_message(HTTP::Headers->new(), '');
    ok($msg->is_error, 'Message received with error');
    is($msg->error_status_text, 'unexpected-processing-error');
    ok($msg->error_plain_text =~ /headers/i);
};

subtest 'Mismatch AS2 Id' => sub {
    my $a1 = Net::AS2->new(%config_1,);
    my $a2 = Net::AS2->new(%config_2, MyId => '_x', PartnerId => '_y');

    local $Mock::LWP::UserAgent::response_handler = sub {
        my $req = shift;
        my $msg = $a2->decode_message($req->headers, $req->content);
        ok($msg->is_error, 'Message received with error');
        is($msg->error_status_text, 'authentication-failed');
        ok($msg->error_plain_text =~ /AS2-/i);

        my $r = HTTP::Response->new(200, 'OK', [], '');
        return $r;
    };
    $a1->send("Test", 'Type' => 'text/plain');
};

subtest 'Async MDN' => sub {
    my $a1 = Net::AS2->new(%config_1);
    my $a2 = Net::AS2->new(%config_2);

    my $msg = Net::AS2::Message->new("orig-id", "http://example.com/async_url", 1, "mic", "data", 'sha1');

    local $Mock::LWP::UserAgent::response_handler = sub {
        my $req = shift;
        my $mdn = $a1->decode_mdn($req->headers, $req->content);
        ok($mdn->match_mic('mic', 'sha1'));
        ok($mdn->is_success, 'Message received with error');
        is($mdn->original_message_id, 'orig-id');

        my $r = HTTP::Response->new(200, 'OK', [], '');
        return $r;
    };
    $a2->send_async_mdn(Net::AS2::MDN->create_success($msg), "MDN ID");
};

subtest 'Async MDN Unparsable' => sub {
    my $a1 = Net::AS2->new(%config_1);

    my $mdn = $a1->decode_mdn(HTTP::Headers->new(), '');
    ok($mdn->is_unparsable, 'Message received with error');
};


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
