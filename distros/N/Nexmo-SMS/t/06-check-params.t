#!perl -T

use strict;
use warnings;

use Test::More tests => 11;

use Nexmo::SMS::MockLWP;
use Nexmo::SMS;

my $nexmo = Nexmo::SMS->new(
    server   => 'http://rest.nexmo.com/sms/json',
    username => 'testuser',
    password => 'testpasswd',
);

ok( $nexmo->isa( 'Nexmo::SMS' ), '$nexmo is a Nexmo::SMS' );

my $error_wap = '';
my $wap = $nexmo->sms(
    type  => 'wappush',
    from  => 'Test05',
    to    => '452312432',
) or $error_wap = $nexmo->errstr;

ok $error_wap =~ /Check params/, 'Check params';
ok $error_wap =~ /title/, 'Check params: title is missing';
ok $error_wap =~ /url/, 'Check params: url is missing';

my $error_sms = '';
my $sms = $nexmo->sms(
    from  => 'Test05',
    to    => '452312432',
) or $error_sms = $nexmo->errstr;

ok $error_sms =~ /Check params text/, 'Check params';
ok $error_sms =~ /text/, 'Check params: text is missing';

my $error_binary = '';
my $binary = $nexmo->sms(
    type  => 'binary',
) or $error_binary = $nexmo->errstr;

ok $error_binary =~ /Check params/, 'Check params';
ok $error_binary =~ /from/, 'Check params: from is missing';
ok $error_binary =~ /to/, 'Check params: to is missing';
ok $error_binary =~ /udh/, 'Check params: to is missing';
ok $error_binary =~ /body/, 'Check params: to is missing';