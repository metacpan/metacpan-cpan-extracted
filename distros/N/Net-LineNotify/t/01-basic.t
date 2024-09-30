use strict;
use warnings;
use Test::More tests => 2;
use Net::LineNotify;

# テストモードでNet::LineNotifyオブジェクトの作成
my $line = Net::LineNotify->new(access_token => 'dummy_token', test_mode => 1);
isa_ok($line, 'Net::LineNotify', 'Object creation in test mode');

# テストモードでメッセージ送信
ok($line->send_message('Test message in test mode'), 'Message send in test mode succeeds');

