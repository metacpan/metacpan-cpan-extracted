use Test::More tests => 5;

use utf8;
use strict;
use warnings;

use File::Basename qw(dirname);
use Cwd            qw(abs_path);

use Encode;
use HTTP::Response;

use_ok('Net::AS2');

my $cert_dir = abs_path(dirname(__FILE__) . '/certificates');

my %config_1 = (
    MyId => 'Mr 1', MyKey => key(1), MyCertificate => cert(1),
    PartnerId => 'Mr 2', PartnerCertificate => cert(2),
    PartnerUrl => 'http://example.com/dummy/a_2/msg',
    Signature => 'sha256',
);

my %config_2 = (
    MyId => 'Mr 2', MyKey => key(2), MyCertificate => cert(2),
    PartnerId => 'Mr 1', PartnerCertificate => cert(1),
    PartnerUrl => 'http://example.com/dummy/a_1/msg',
    Signature => 'sha256',
);

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

    my ($mdn_temp, $mic1, $mic1_alg) = $a1->send($data, 'Type' => 'text/plain', 'MessageId' => $message_id);
    ok($mdn_temp->is_unparsable, 'ASYNC data unparsable');
    my $req = $Mock::LWP::UserAgent::last_request;

    my $msg = $a2->decode_message(extract_headers($req), $req->content);

    ok($msg->is_success, 'Message received successfully');
    ok($msg->is_mdn_async, 'MDN is async');
    is($msg->async_url, 'http://example.com/dummy/a_1/mdn');
    is(decode('utf8', $msg->content), $data, 'Content matches');
    is($msg->filename, 'payload', 'default Content-Disposition filename');
    is($mic1, $msg->mic, 'MIC matches');

    $a2->send_async_mdn(Net::AS2::MDN->create_success($msg));

    my $mdn_req = $Mock::LWP::UserAgent::last_request;
    my $mdn = $a1->decode_mdn(extract_headers($mdn_req), $mdn_req->content);
    ok($mdn->is_success, 'MDN is success');
    ok($mdn->match_mic($mic1, $mic1_alg), 'MDN MIC matches');
    is($mdn->original_message_id, $message_id, 'MDN message id matches');
};

subtest 'Send and Async - Signature + Encryption' => sub { $test_async->({}); };
subtest 'Send and Async - Signature Only ' => sub { $test_async->({ Encryption => 0 }); };
subtest 'Send and Async - Encryption Only' => sub { $test_async->({ Signature => 0 }); };
subtest 'Send and Async - Plain' => sub { $test_async->({ Encryption => 0, Signature => 0 }); };

sub key {
    my $i = shift;

    local $/;
    open my $fh, '<', "$cert_dir/test.$i.key";
    return <$fh>;
}

sub cert {
    my $i = shift;

    local $/;
    open my $fh, '<', "$cert_dir/test.$i.cert";
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
                unless $key eq 'CONTENT_TYPE';

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
