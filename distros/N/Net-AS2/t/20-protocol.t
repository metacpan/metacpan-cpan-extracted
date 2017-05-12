use Test::More tests => 19;

use utf8;
use strict;
use warnings;

use Encode;
use HTTP::Response;
use_ok('Net::AS2');

my %config_1 = (
    MyId => 'Mr 1', MyKey => key(1), MyCertificate => cert(1), 
    PartnerId => 'Mr 2', PartnerCertificate => cert(2),
    PartnerUrl => 'http://example.com/dummy/a_2/msg');

my %config_2 = (
    MyId => 'Mr 2', MyKey => key(2), MyCertificate => cert(2), 
    PartnerId => 'Mr 1', PartnerCertificate => cert(1),
    PartnerUrl => 'http://example.com/dummy/a_1/msg');

my $test_async = sub {
    my ($mod) = @_;
    my $a1 = Mock::Net::AS2->new(%config_1,
        Mdn => 'async',
        MdnAsyncUrl => 'http://example.com/dummy/a_1/mdn',
        %{$mod}
    );

    my $a2 = Mock::Net::AS2->new(%config_2, %{$mod});

    my $data = "测试\nThis is a test\r\n\x01\x02\x00";
    my $message_id = rand . '@' . 'localhost';

    my ($mdn_temp, $mic1) = $a1->send($data, 'Type' => 'text/plain', 'MessageId' => $message_id);
    ok($mdn_temp->is_unparsable, 'ASYNC data unparsable');
    my $req = $Mock::LWP::UserAgent::last_request;

    my $msg = $a2->decode_message(extract_headers($req), $req->content);

    ok($msg->is_success, 'Message received sucessfully');
    ok($msg->is_mdn_async, 'MDN is async');
    is($msg->async_url, 'http://example.com/dummy/a_1/mdn');
    is(decode('utf8', $msg->content), $data, 'Content matches');
    is($mic1, $msg->mic, 'MIC matches');

    $a2->send_async_mdn(Net::AS2::MDN->create_success($msg));

    my $mdn_req = $Mock::LWP::UserAgent::last_request;
    my $mdn = $a1->decode_mdn(extract_headers($mdn_req), $mdn_req->content);
    ok($mdn->is_success, 'MDN is success');
    ok($mdn->match_mic($mic1, 'sha1'), 'MDN MIC matches');
    is($mdn->original_message_id, $message_id, 'MDN message id matches');
};

subtest 'Send and Async - Signature + Encryption' => sub { $test_async->({}); };
subtest 'Send and Async - Signature Only ' => sub { $test_async->({ Encryption => 0 }); };
subtest 'Send and Async - Encryption Only' => sub { $test_async->({ Signature => 0 }); };
subtest 'Send and Async - Plain' => sub { $test_async->({ Encryption => 0, Signature => 0 }); };

my $test_sync = sub {
    my ($mod) = @_;
    my $a1 = Mock::Net::AS2->new(%config_1,
        Mdn => 'sync',
        %{$mod}
    );

    my $a2 = Mock::Net::AS2->new(%config_2, %{$mod});

    my $data = "测试\nThis is a test\r\n\x01\x02\x00";
    my $message_id = rand . '@' . 'localhost';

    local $Mock::LWP::UserAgent::response_handler = sub {
        my $req = shift;
        my $msg = $a2->decode_message(extract_headers($req), $req->content);
        ok($msg->is_success, 'Message received sucessfully');
        ok(!$msg->is_mdn_async, 'MDN is sync');
        is(decode('utf8', $msg->content), $data, 'Content matches');

        my ($h, $c) = $a2->prepare_sync_mdn(Net::AS2::MDN->create_success($msg));
        my $r = HTTP::Response->new(200, 'OK', $h, $c);
        return $r;
    };

    my ($mdn, $mic1) = $a1->send($data, 'Type' => 'text/plain', 'MessageId' => $message_id);

    use Data::Dumper;

    ok($mdn->is_success, 'MDN is success');
    ok($mdn->match_mic($mic1, 'sha1'), 'MDN MIC matches');
    is($mdn->original_message_id, $message_id, 'MDN message id matches');
};

subtest 'Send and Sync - Signature + Encryption' => sub { $test_sync->({}); };
subtest 'Send and Sync - Signature Only ' => sub { $test_sync->({ Encryption => 0 }); };
subtest 'Send and Sync - Encryption Only' => sub { $test_sync->({ Signature => 0 }); };
subtest 'Send and Sync - Plain' => sub { $test_sync->({ Encryption => 0, Signature => 0 }); };

subtest 'Encryption required check' => sub {
    my $a1 = Mock::Net::AS2->new(%config_1, Mdn => 'sync', Encryption => 0);
    my $a2 = Mock::Net::AS2->new(%config_2);

    local $Mock::LWP::UserAgent::response_handler = sub {
        my $req = shift;
        my $msg = $a2->decode_message(extract_headers($req), $req->content);
        ok($msg->is_error, 'Message received with error');
        is($msg->error_status_text, 'insufficient-message-security');
        ok($msg->error_plain_text =~ /encryption/i);

        my $r = HTTP::Response->new(200, 'OK', [], '');
        return $r;
    };
    $a1->send("Test", 'Type' => 'text/plain');
};

subtest 'Encryption optional pass' => sub {
    my $a1 = Mock::Net::AS2->new(%config_1, Mdn => 'sync');
    my $a2 = Mock::Net::AS2->new(%config_2, Encryption => 0);

    local $Mock::LWP::UserAgent::response_handler = sub {
        my $req = shift;
        my $msg = $a2->decode_message(extract_headers($req), $req->content);
        ok($msg->is_success, 'Message received sucessfully');

        my $r = HTTP::Response->new(200, 'OK', [], '');
        return $r;
    };
    $a1->send("Test", 'Type' => 'text/plain');
};

subtest 'Encryption failed' => sub {
    my $a1 = Mock::Net::AS2->new(%config_1);
    my $a2 = Mock::Net::AS2->new(%config_1, 
        MyId => $config_2{MyId}, PartnerId => $config_2{PartnerId},
        Signature => 0
        );

    local $Mock::LWP::UserAgent::response_handler = sub {
        my $req = shift;
        my $msg = $a2->decode_message(extract_headers($req), $req->content);
        ok($msg->is_error, 'Message received with error');
        is($msg->error_status_text, 'decryption-failed');
        ok($msg->error_plain_text =~ /decrypt/i);

        my $r = HTTP::Response->new(200, 'OK', [], '');
        return $r;
    };
    $a1->send("Test", 'Type' => 'text/plain');
};

subtest 'Signature required check' => sub {
    my $a1 = Mock::Net::AS2->new(%config_1, Mdn => 'sync', Signature => 0);
    my $a2 = Mock::Net::AS2->new(%config_2);

    local $Mock::LWP::UserAgent::response_handler = sub {
        my $req = shift;
        my $msg = $a2->decode_message(extract_headers($req), $req->content);
        ok($msg->is_error, 'Message received with error');
        is($msg->error_status_text, 'insufficient-message-security');
        ok($msg->error_plain_text =~ /signature/i);

        my $r = HTTP::Response->new(200, 'OK', [], '');
        return $r;
    };
    $a1->send("Test", 'Type' => 'text/plain');
};

subtest 'Signature optional pass' => sub {
    my $a1 = Mock::Net::AS2->new(%config_1, Mdn => 'sync');
    my $a2 = Mock::Net::AS2->new(%config_2, Signature => 0);

    local $Mock::LWP::UserAgent::response_handler = sub {
        my $req = shift;
        my $msg = $a2->decode_message(extract_headers($req), $req->content);
        ok($msg->is_success, 'Message received sucessfully');

        my $r = HTTP::Response->new(200, 'OK', [], '');
        return $r;
    };
    $a1->send("Test", 'Type' => 'text/plain');
};

subtest 'Signature failed' => sub {
    my $a1 = Mock::Net::AS2->new(%config_1, Encryption => 0);
    my $a2 = Mock::Net::AS2->new(%config_1, 
        MyId => $config_2{MyId}, PartnerId => $config_2{PartnerId},
        Encryption => 0);

    local $Mock::LWP::UserAgent::response_handler = sub {
        my $req = shift;
        my $msg = $a2->decode_message(extract_headers($req), $req->content);
        ok($msg->is_error, 'Message received with error');
        is($msg->error_status_text, 'insufficient-message-security');
        ok($msg->error_plain_text =~ /unable to verify/i);

        my $r = HTTP::Response->new(200, 'OK', [], '');
        return $r;
    };
    $a1->send("Test", 'Type' => 'text/plain');
};

subtest 'Missing headers' => sub {
    my $a1 = Mock::Net::AS2->new(%config_1);

    my $msg = $a1->decode_message({}, '');
    ok($msg->is_error, 'Message received with error');
    is($msg->error_status_text, 'unexpected-processing-error');
    ok($msg->error_plain_text =~ /headers/i);
};

subtest 'Mismatch AS2 Id' => sub {
    my $a1 = Mock::Net::AS2->new(%config_1,);
    my $a2 = Mock::Net::AS2->new(%config_2, MyId => '_x', PartnerId => '_y');

    local $Mock::LWP::UserAgent::response_handler = sub {
        my $req = shift;
        my $msg = $a2->decode_message(extract_headers($req), $req->content);
        ok($msg->is_error, 'Message received with error');
        is($msg->error_status_text, 'authentication-failed');
        ok($msg->error_plain_text =~ /AS2-/i);

        my $r = HTTP::Response->new(200, 'OK', [], '');
        return $r;
    };
    $a1->send("Test", 'Type' => 'text/plain');
};

subtest 'Async MDN' => sub {
    my $a1 = Mock::Net::AS2->new(%config_1);
    my $a2 = Mock::Net::AS2->new(%config_2);

    my $msg = Net::AS2::Message->new("orig-id", "http://example.com/async_url", 1, "mic", "data");

    local $Mock::LWP::UserAgent::response_handler = sub {
        my $req = shift;
        my $mdn = $a1->decode_mdn(extract_headers($req), $req->content);
        ok($mdn->match_mic('mic', 'sha1'));
        ok($mdn->is_success, 'Message received with error');
        is($mdn->original_message_id, 'orig-id');

        my $r = HTTP::Response->new(200, 'OK', [], '');
        return $r;
    };
    $a2->send_async_mdn(Net::AS2::MDN->create_success($msg), "MDN ID");
};

subtest 'Async MDN Unparsable' => sub {
    my $a1 = Mock::Net::AS2->new(%config_1);

    my $mdn = $a1->decode_mdn({}, '');
    ok($mdn->is_unparsable, 'Message received with error');
};


sub key {
    my $i = shift;

    local $/;
    open my $fh, '<', "t/test.$i.key";
    return <$fh>;
}

sub cert {
    my $i = shift;

    local $/;
    open my $fh, '<', "t/test.$i.cert";
    return <$fh>;
}

sub extract_headers
{
    my $req = shift;
    return
    { 
        map { 
            my $key = uc($_);
            $key =~ s/-/_/g;
            $key = 'HTTP_' . $key
                unless $key ~~ [qw(CONTENT_TYPE)];

            ( $key => $req->header($_) )
        } ($req->header_field_names) 
    };
}

package Mock::Net::AS2;
use base 'Net::AS2';

sub create_useragent
{
    return new Mock::LWP::UserAgent;
}

package Mock::LWP::UserAgent;
use base 'LWP::UserAgent';

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
