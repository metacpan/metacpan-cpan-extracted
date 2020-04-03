use 5.012;
use warnings;
use lib 't'; use MyTest;

*gen_frame = \&MyTest::gen_frame;


my $create_parser = sub {
    my ($server_or_client) = @_;
    my $req = {
        uri    => "ws://crazypanda.ru",
        ws_key => "dGhlIHNhbXBsZSBub25jZQ==",
    };

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my $client = Protocol::WebSocket::XS::ClientParser->new;
    $client->no_deflate;

    my $server = Protocol::WebSocket::XS::ServerParser->new;
    my $str = $client->connect_request($req);
    my $creq = $server->accept($str) or die "should not happen";
    my $res_str = $creq->error ? $server->accept_error : $server->accept_response;
    ok !$server->is_deflate_active;

    $client->connect($res_str);
    ok $client->established;
    ok !$client->is_deflate_active;

    return $server_or_client == 0 ? $server : $client;
};

my $create_builder = sub {
    my ($server_or_client, $settings) = @_;
    return $create_parser->($server_or_client)->start_message(%$settings);
};

subtest 'small server2client frame' => sub {
    my $payload = "preved"; # must be <= 125
    my $bin = $create_builder->(0)->send($payload, 1);
    is(length($bin), 8, "frame length ok"); # 2 header + 6 payload
    is_bin($bin, gen_frame({mask => 0, fin => 1, opcode => OPCODE_BINARY, data => $payload}), "frame ok");
    is_bin($create_builder->(0)->send([qw/pr ev ed/], 1), $bin, "it mode ok");
};

subtest 'medium server2client frame' => sub {
    my $payload = "preved" x 100; # must be > 125
    my $bin = $create_builder->(0)->send($payload, 1);
    is(length($bin), 604, "frame length ok"); # 2 header + 2 length + 600 payload
    is_bin($bin, gen_frame({mask => 0, fin => 1, opcode => OPCODE_BINARY, data => $payload}), "frame ok");
};

subtest 'big server2client frame' => sub {
    my $payload = "preved!" x 10000; # must be > 65536
    my $bin = $create_builder->(0)->send($payload, 1);
    is(length($bin), 70010, "frame length ok"); # 2 header + 8 length + 70000 payload
    is_bin($bin, gen_frame({mask => 0, fin => 1, opcode => OPCODE_BINARY, data => $payload}), "frame ok");
};

subtest 'small client2server frame' => sub {
    my $builder = $create_builder->(1, {opcode => OPCODE_TEXT});
    my $payload = "preved"; # must be <= 125
    my $bin = $builder->send($payload, 1);
    is(length($bin), 12, "frame length ok"); # 2 header + 4 mask + 6 payload
    is_bin($bin, gen_frame({mask => substr($bin, 2, 4), fin => 1, opcode => OPCODE_TEXT, data => $payload}), "frame ok");
};

subtest 'medium client2server frame' => sub {
    my $builder = $create_builder->(1, {opcode => OPCODE_TEXT});
    my $payload = "preved" x 100; # must be > 125
    my $bin = $builder->send($payload, 1);
    is(length($bin), 608, "frame length ok"); # 2 header + 2 length + 4 mask + 600 payload
    is_bin($bin, gen_frame({mask => substr($bin, 4, 4), fin => 1, opcode => OPCODE_TEXT, data => $payload}), "frame ok");
};

subtest 'big client2server frame' => sub {
    my $builder = $create_builder->(1, {opcode => OPCODE_TEXT});
    my $payload = "preved!" x 10000; # must be > 65536
    my $bin = $builder->send($payload, 1);
    is(length($bin), 70014, "frame length ok"); # 2 header + 8 length + 4 mask + 70000 payload
    is_bin($bin, gen_frame({mask => substr($bin, 10, 4), fin => 1, opcode => OPCODE_TEXT, data => $payload}), "frame ok");
};

subtest 'empty frame still masked' => sub {
    my $builder = $create_builder->(1,{opcode => OPCODE_BINARY});
    my $bin = $builder->send("", 1);
    is(length($bin), 6, "frame length ok"); # 2 header + 4 mask
    is_bin($bin, gen_frame({mask => substr($bin, 2, 4), fin => 1, opcode => OPCODE_BINARY}), "frame ok");
};

subtest 'opcode CONTINUE is forced for fragment frames of message (including final frame)' => sub {
    my $builder = $create_builder->(0,{opcode => OPCODE_BINARY});
    my $bin = $builder->send("frame1");
    is_bin($bin, gen_frame({fin => 0, opcode => OPCODE_BINARY, data => "frame1"}), "initial frame ok");
    $bin = $builder->send("frame2");
    is_bin($bin, gen_frame({fin => 0, opcode => OPCODE_CONTINUE, data => "frame2"}), "fragment frame ok");
    $bin = $builder->send("frame3", 1);
    is_bin($bin, gen_frame({fin => 1, opcode => OPCODE_CONTINUE, data => "frame3"}), "final frame ok");

    $builder = $create_builder->(0,{opcode => OPCODE_TEXT});
    $bin = $builder->send("frame4");
    is_bin($bin, gen_frame({fin => 0, opcode => OPCODE_TEXT, data => "frame4"}), "first frame of next message ok");
    $bin = $builder->send("frame5", 1); # reset frame count
    is_bin($bin, gen_frame({fin => 1, opcode => OPCODE_CONTINUE, data => "frame5"}));
};

subtest 'control frame send' => sub {
    my $p = $create_parser->(0);
    my $bin = $p->send_control(OPCODE_PING, "myping");
    is_bin($bin, gen_frame({fin => 1, opcode => OPCODE_PING, data => "myping"}), "ping ok");
    $bin = $p->send_control(OPCODE_PONG, "mypong");
    is_bin($bin, gen_frame({fin => 1, opcode => OPCODE_PONG, data => "mypong"}), "pong ok");
    $bin = $p->send_control(OPCODE_CLOSE, "myclose");
    is_bin($bin, gen_frame({fin => 1, opcode => OPCODE_CLOSE, data => "myclose"}), "close ok");
    MyTest::reset($p);
};

subtest 'frame count survives control message in the middle' => sub {
    my $p = $create_parser->(0);
    my $builder = $p->start_message;
    my $bin = $builder->send("frame1");
    is_bin($bin, gen_frame({fin => 0, opcode => OPCODE_BINARY, data => "frame1"}), "initial frame ok");
    $bin = $p->send_control(OPCODE_PING, "");
    is_bin($bin, gen_frame({fin => 1, opcode => OPCODE_PING}), "control frame ok");
    $bin = $builder->send("frame2");
    is_bin($bin, gen_frame({fin => 0, opcode => OPCODE_CONTINUE, data => "frame2"}), "fragment frame ok");
    $bin = $p->send_control(OPCODE_PONG, "");
    is_bin($bin, gen_frame({fin => 1, opcode => OPCODE_PONG}), "control frame ok");
    $bin = $builder->send("frame3", 1);
    is_bin($bin, gen_frame({fin => 1, opcode => OPCODE_CONTINUE, data => "frame3"}), "final frame ok");
};

done_testing();
