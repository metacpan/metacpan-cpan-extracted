use 5.012;
use warnings;
use lib 't/lib';
use MyTest;
use Test::More;
use Test::Fatal;

subtest "attempt to send frame after sending final frame" => sub {
    my $server = MyTest::get_established_server();
    my $b = $server->start_message;
    my $bin = $b->send('payload', 1);
    ok $bin;
    like( exception { $b->send('beyond payload') }, qr/message has not been started/);
    like( exception { $b->send('beyond payload', 0) }, qr/message has not been started/);
};

subtest "attempt to start another message, having unfinished one" => sub {
    my $server = MyTest::get_established_server();
    $server->start_message;
    like( exception { $server->start_message }, qr/previous message wasn't finished/);
};

done_testing;
