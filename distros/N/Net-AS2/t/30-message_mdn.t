use Test::More tests => 9;

use utf8;
use strict;
use warnings;

use Encode;
use_ok('Net::AS2');
use_ok('Net::AS2::MDN');
use_ok('Net::AS2::Message');


my $original_message_id = 'some-random@example.com';
my $async_url = 'https://example.com:8081/hey';
my $mic = 'TESTBASE64++=';
my $data = "测试\x01\x02\r\nGood";

my $msg_success = Net::AS2::Message->new($original_message_id, $async_url, 1, $mic, $data, 'sha1');
my $msg_error   = Net::AS2::Message->create_error_message($original_message_id, $async_url, 0, 'error-status', 'error-plain');
my $msg_failure = Net::AS2::Message->create_failure_message($original_message_id, undef, 1, 'failure-status', 'failure-plain');

sub check_pair {
    my ($msg, $mdn) = @_;
    is(defined $mdn->async_url ? 1 : 0, $msg->is_mdn_async ? 1 : 0);
    is($mdn->async_url, $msg->async_url);
    is($mdn->should_sign, $msg->should_mdn_sign);
    is($mdn->original_message_id, $msg->message_id);
    if (defined $msg->mic) {
        is($mdn->{mic_hash}, $msg->mic);
        is($mdn->{mic_alg},  $msg->mic_alg);
    }
    if (defined $msg->error_status_text) {
        is($mdn->{status_text}, $msg->error_status_text);
        is($mdn->{plain_text}, $msg->error_plain_text);
    }
    mdn_self_check($mdn);
    message_self_check($msg);
}

sub mdn_self_check {
    my ($mdn) = @_;

    $mdn->recipient('TEST ""');
    my $new_mdn = Net::AS2::MDN->parse_mdn($mdn->as_mime->stringify);

    foreach (qw(
        success warning error failure unparsable
        recipient
        status_text plain_text original_message_id mic_hash mic_alg
    ))
    {
        is($new_mdn->{$_}, $mdn->{$_}, "Self duplicated MDN: $_")
            unless
                # The text is hardcoded
                $mdn->is_success && $_ eq 'status_text';
    }
}

sub message_self_check
{
    my ($msg) = @_;
    my $new_msg =
        Net::AS2::Message->create_from_serialized_state(
            $msg->serialized_state()
        );

    foreach (qw(success error failure message_id mic status_text should_mdn_sign plain_text async_url))
    {
        is($new_msg->{$_} // '', $msg->{$_} // '', "Self duplicated message: $_")
    }
}

subtest 'MDN Success' => sub {
    my $mdn = Net::AS2::MDN->create_success($msg_success, 'success');
    ok($mdn->is_success); ok(!$mdn->with_warning);
    ok(!$mdn->is_failure); ok(!$mdn->is_error); ok(!$mdn->is_unparsable);
    check_pair($msg_success, $mdn);
};

subtest 'MDN Error From Message' => sub {
    my $mdn = Net::AS2::MDN->create_from_unsuccessful_message($msg_error);
    ok(!$mdn->is_success); ok(!$mdn->with_warning);
    ok(!$mdn->is_failure); ok($mdn->is_error); ok(!$mdn->is_unparsable);
    check_pair($msg_error, $mdn);
};

subtest 'MDN Failure From Message' => sub {
    my $mdn = Net::AS2::MDN->create_from_unsuccessful_message($msg_failure);
    ok(!$mdn->is_success); ok(!$mdn->with_warning);
    ok($mdn->is_failure); ok(!$mdn->is_error); ok(!$mdn->is_unparsable);
    check_pair($msg_failure, $mdn);
};

subtest 'MDN Warning' => sub {
    my $mdn = Net::AS2::MDN->create_warning($msg_success, 'warning');
    ok($mdn->is_success); ok($mdn->with_warning);
    ok(!$mdn->is_failure); ok(!$mdn->is_error); ok(!$mdn->is_unparsable);
    mdn_self_check($mdn);
};

subtest 'MDN Error' => sub {
    my $mdn = Net::AS2::MDN->create_error($msg_success, 'error human');
    ok(!$mdn->is_success); ok(!$mdn->with_warning);
    ok(!$mdn->is_failure); ok($mdn->is_error); ok(!$mdn->is_unparsable);
    mdn_self_check($mdn);
};

subtest 'MDN Failure' => sub {
    my $mdn = Net::AS2::MDN->create_failure($msg_success, 'failure robot', 'failure human');
    ok(!$mdn->is_success); ok(!$mdn->with_warning);
    ok($mdn->is_failure); ok(!$mdn->is_error); ok(!$mdn->is_unparsable);
    mdn_self_check($mdn);
};


1;
