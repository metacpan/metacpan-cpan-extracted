use 5.012;
use warnings;
use lib 't'; use MyTest;
use Test::Fatal;
use Encode::Base2N qw/encode_base64pad decode_base64/;

my $create_pair = sub {
    my $configure = shift;
    my $req = {
        uri    => "ws://crazypanda.ru",
        ws_key => "dGhlIHNhbXBsZSBub25jZQ==",
    };

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my $client = Protocol::WebSocket::Fast::ClientParser->new;
    my $server = Protocol::WebSocket::Fast::ServerParser->new;

    $configure->($client, $server) if $configure;

    my $str = $client->connect_request($req);
    my $creq = $server->accept($str) or die "should not happen";
    my $res_str = $creq->error ? $server->accept_error : $server->accept_response;

    my $server_deflate = $client->deflate_config && $server->deflate_config;
    like $str, qr/permessage-deflate/ if($client->deflate_config);
    like $res_str, qr/permessage-deflate/ if($server->deflate_config);
    ok $server->is_deflate_active if ($server_deflate);

    $client->connect($res_str);
    ok $client->established;
    ok $client->is_deflate_active if ($server_deflate);

    return ($client, $server);
};

subtest 'empty payload frame' => sub {
    my $payload = "";
    my ($c, $s) = $create_pair->();
    my $bin = $s->start_message(final => 1, deflate => 1)->send($payload);
    my ($f) = $c->get_frames($bin);
    ok !$f->payload;
};

subtest 'tiny payload' => sub {
    my $payload = "preved";
    my ($c, $s) = $create_pair->();
    my $bin = $s->start_message(final => 1, deflate => 1)->send($payload);
    my ($f) = $c->get_frames($bin);
    is $f->payload, $payload;
};

subtest 'medium payload' => sub {
    my @payload = ('0') x (1923);
    my $payload = join('', @payload);
    my ($c, $s) = $create_pair->();
    my $bin = $s->start_message(final => 1, deflate => 1)->send($payload);
    my ($f) = $c->get_frames($bin);
    is $f->payload, $payload;
};

subtest 'medium payload (fragmented)' => sub {
    my @payload = ('0') x (1923);
    my $payload = join('', @payload);
    my ($c, $s) = $create_pair->();
    my $bin = $s->start_message(final => 1, deflate => 1)->send(\@payload);
    my ($f) = $c->get_frames($bin);
    is $f->payload, $payload;
};

subtest 'large payload' => sub {
    my @payload = ('0') x (1024 * 1024);
    my $payload = join('', @payload);
    my ($c, $s) = $create_pair->();
    my $bin = $s->start_message(final => 1, deflate => 1)->send($payload);
    my ($f) = $c->get_frames($bin);
    is $f->payload, $payload;
};

subtest '1-frame-message (tiny payload)' => sub {
    my $payload = "hello-world";
    my ($c, $s) = $create_pair->();
    my $bin = $s->start_message(deflate => 1)->send($payload, 1);
    my ($m) = $c->get_messages($bin);
    ok $m;
    is $m->payload, $payload;

};

subtest 'message, 2 frames, context_takeover = true, tiny payload' => sub {
    my @payload = ('a', 'b');
    my $payload = join('', @payload, @payload);
    my ($c, $s) = $create_pair->();
    my $builder = $s->start_message(deflate => 1);
    my $bin1 = $builder->send(\@payload);
    my $bin2 = $builder->send(\@payload, 1);
    my ($m) = $c->get_messages($bin1 . $bin2);
    ok $m;
    is $m->payload, $payload;
};

subtest 'message, 2 frames, context_takeover = true, medium payload' => sub {
    my @payload = ('0') x (1024);
    my $payload = join('', @payload, @payload);
    my ($c, $s) = $create_pair->();
    my $builder = $s->start_message(deflate => 1);
    my $bin1 = $builder->send(\@payload);
    my $bin2 = $builder->send(\@payload, 1);
    note "l1 = ", length($bin1), ", l2 = ", length($bin2);
    my ($m) = $c->get_messages($bin1 . $bin2);
    ok $m;
    is $m->payload, $payload;
};


subtest '2 messages, 2 frames, server_context_takeover = false, medium payload' => sub {
    my @payload = ('0') x (1024);
    my $payload = join('', @payload);
    my ($c, $s) = $create_pair->(sub {
        my ($c, $s) = @_;
        $c->configure({deflate => {server_no_context_takeover => 1}});
    });
    my $bin1 = $s->start_message(deflate => 1)->send(\@payload, 1);
    my $bin2 = $s->start_message(deflate => 1)->send(\@payload, 1);
    note "l1 = ", length($bin1), ", l2 = ", length($bin2);
    is length($bin1), length($bin2), "make sure there is no context takeover";
    my @m = $c->get_messages($bin1 . $bin2);
    is scalar(@m), 2;
    my ($m1, $m2) = @m;
    is $m1->payload, $payload;
    is $m2->payload, $payload;
};

subtest '2 messages, 2 frames, client_context_takeover = false, medium payload' => sub {
    my @payload = ('0') x (1024);
    my $payload = join('', @payload);
    my ($c, $s) = $create_pair->(sub {
        my ($c, $s) = @_;
        $c->configure({deflate => {client_no_context_takeover => 1}});
    });
    my $bin1 = $c->start_message(deflate => 1)->send(\@payload, 1);
    my $bin2 = $c->start_message(deflate => 1)->send(\@payload, 1);
    note "l1 = ", length($bin1), ", l2 = ", length($bin2);
    is length($bin1), length($bin2), "make sure there is no context takeover";
    my @m = $s->get_messages($bin1 . $bin2);
    is scalar(@m), 2;
    my ($m1, $m2) = @m;
    is $m1->payload, $payload;
    is $m2->payload, $payload;
};

subtest '2 messages, 2 frames, server_context_takeover = false = client_context_takeover = false, medium payload, custom windows' => sub {
    my @payload = ('0') x (1024 * 10);
    my $payload = join('', @payload);
    my ($c, $s) = $create_pair->(sub {
        my ($c, $s) = @_;
        $c->configure({deflate => {
            client_no_context_takeover => 1,
            server_no_context_takeover => 1,
            client_max_window_bits     => 10,
            server_max_window_bits     => 11,
            compression_level          => 1,
        }});
    });
    my $bin1 = $c->start_message(deflate => 1)->send(\@payload, 1);
    my $bin2 = $c->start_message(deflate => 1)->send(\@payload, 1);
    note "l1 = ", length($bin1), ", l2 = ", length($bin2);
    is length($bin1), length($bin2), "make sure there is no context takeover";
    my @m = $s->get_messages($bin1 . $bin2);
    is scalar(@m), 2;
    my ($m1, $m2) = @m;
    is $m1->payload, $payload;
    is $m2->payload, $payload;
};

subtest "multiframe message" => sub {
    my $payloads = [qw/first second third/];
    my ($c, $s) = $create_pair->();
    my $bin = $c->send_message_multiframe(deflate => 1, payload => $payloads);
    my ($m) = $s->get_messages($bin);
    is $m->payload, join('', @$payloads);
};


subtest "multiframe message (with empty pieces)" => sub {
    my $payloads = ['', 'hello', ''];
    my ($c, $s) = $create_pair->();
    my $bin = $c->send_message_multiframe(deflate => 1, payload => $payloads);
    my ($m) = $s->get_messages($bin);
    is $m->payload, join('', @$payloads);
};

subtest "multiframe message (empty)" => sub {
    my $payloads = ['', '', ''];
    my ($c, $s) = $create_pair->();
    my $bin = $c->send_message_multiframe(deflate => 1, payload => $payloads);
    my ($m) = $s->get_messages($bin);
    ok $m;
    ok !$m->payload;
};

subtest 'corrupted frame' => sub {
    my @payload = ('0') x (1923);
    my $payload = join('', @payload);
    my ($c, $s) = $create_pair->();
    my $bin             = $s->start_message(final => 1, deflate => 1)->send($payload);
    my $deflate_payload = substr($bin, 2);
    my $forged_bin      = substr($bin, 0, 2) . "xx" . substr($deflate_payload, 2);
    my ($f) = $c->get_frames($forged_bin);
    like $f->error, qr/zlib::inflate error/;
};

subtest 'corrupted 2nd frame from 3' => sub {
    my @payload = ('0') x (1923);
    my $payload = join('', @payload, @payload, @payload);
    my ($c, $s) = $create_pair->();
    my $builder = $s->start_message(deflate => 1);
    my $bin_1   = $builder->send(\@payload);
    my $bin_2   = $builder->send(\@payload);
    my $bin_3   = $builder->send(\@payload, 1);

    my $bin_2_payload = substr($bin_2, 2);
    my $bin_2_forged  = substr($bin_2, 0, 2) . substr($bin_2_payload, 0, 2) . 'xx' . substr($bin_2_payload, 4);
    my ($m) = $c->get_messages($bin_1 . $bin_2_forged . $bin_3);
    ok $m;
    like $m->error, qr/zlib::inflate error/;
};

subtest "compression threshold" => sub {
    my ($c, $s) = $create_pair->(sub {
        my ($c, $s) = @_;
        $s->configure({deflate => { compression_threshold => 5 }});
    });
    my $payload_1 = "1234";
    my $bin_1 = $s->send_message(payload => $payload_1);
    note $bin_1;
    is( substr($bin_1, 2), $payload_1);

    my $payload_2 = "12345";
    my $bin_2 = $s->send_message(payload => $payload_2, opcode => OPCODE_BINARY);
    note $bin_2;
    is( substr($bin_2, 2), $payload_2, "binary payload isn't compressed by default");

    my $bin_3 = $s->send_message(payload => $payload_2, opcode => OPCODE_TEXT);
    note $bin_3;
    isnt( substr($bin_3, 2), $payload_2, "text payload is compressed by default");
};

subtest "no_deflate" => sub {
    my ($c, $s) = $create_pair->(sub {
        my ($c, $s) = @_;
        $s->no_deflate;
    });
    my $payload = "1234";

    my $bin = $s->send_message(payload => $payload);
    note $bin;
    is( substr($bin, 2), $payload);
};

subtest "SRV-1236/12.3 inflate error" => sub {
    my $data = read_file(__FILE__);
    my ($c, $s) = $create_pair->(sub {
        my ($c, $s) = @_;
        $_->configure({client_no_context_takeover => 1}) for ($c, $s);
    });
    for(my $i = 1;  $i < 100; ++$i) {
        my $sample = substr($data, 1, 256);
        my $bin = $c->send_message(payload => $sample);
        my ($m) = $c->get_messages($bin);
        is $m->payload, $sample;
    }
};

subtest "zip-bomb prevention (check max_message_size)" => sub {
    subtest "single frame/message exceeds limit" => sub {
        my ($c, $s) = $create_pair->(sub {
            my ($c, $s) = @_;
            $_->configure({max_message_size => 100, deflate => { compression_threshold => 0 }}) for ($c, $s);
        });

        my $payload = join("", ('0') x (101));
        my $bin = $s->send_message(payload => $payload, opcode => OPCODE_TEXT);
        note "payload length: ", length($bin);
        my ($m) = $c->get_messages($bin);
        ok $m;
        is $m->error, Protocol::WebSocket::Fast::Error::max_message_size;
    };

    subtest "multi-frame/message exceeds limit" => sub {
        my ($c, $s) = $create_pair->(sub {
            my ($c, $s) = @_;
            $_->configure({max_message_size => 100, deflate => { compression_threshold => 0 }}) for ($c, $s);
        });

        my $payload_1 = join("", ('0') x (60));
        my $payload_2 = $payload_1;
        my $builder = $s->start_message(final => 0, deflate => 1);
        my $bin_1 = $builder->send($payload_1);
        my $bin_2 = $builder->send($payload_2, 1);
        my $bin = $bin_1 . $bin_2;
        note "payload lengths: ", length($bin_1) , " and ", length($bin_2);
        my ($m) = $c->get_messages($bin);
        ok $m;
        is $m->error, Protocol::WebSocket::Fast::Error::max_message_size;
    };

    subtest "exact message size is allowed" => sub {
        my ($c, $s) = $create_pair->(sub {
            my ($c, $s) = @_;
            $_->configure({max_message_size => 100, deflate => { compression_threshold => 0 }}) for ($c, $s);
        });

        my $payload = join("", ('0') x (100));
        my $bin = $s->send_message(payload => $payload, opcode => OPCODE_TEXT);
        note "payload length: ", length($bin);
        my ($m) = $c->get_messages($bin);
        ok $m;
        ok !$m->error;
        ok $m->payload, $payload;
    };

};

subtest "windowBits == 8 zlib tests" => sub {
    # https://github.com/faye/permessage-deflate-node/wiki/Denial-of-service-caused-by-invalid-windowBits-parameter-passed-to-zlib.createDeflateRaw()
    # https://github.com/madler/zlib/commit/049578f0a1849f502834167e233f4c1d52ddcbcc

    subtest "8-bit config" => sub {
        my $req = {
            uri    => "ws://crazypanda.ru",
            ws_key => "dGhlIHNhbXBsZSBub25jZQ==",
        };

        my $client = Protocol::WebSocket::Fast::ClientParser->new;
        my $server = Protocol::WebSocket::Fast::ServerParser->new;

        my $config = { deflate => {
            compression_threshold  => 0,
            server_max_window_bits => 8,
            client_max_window_bits => 8,
        }};
        $_->configure($config) for($client, $server);

        my $str = $client->connect_request($req);
        my $creq = $server->accept($str) or die "should not happen";
        my $res_str = $creq->error ? $server->accept_error : $server->accept_response;

        my $server_deflate = $client->deflate_config && $server->deflate_config;
        like $str, qr/permessage-deflate/ if($client->deflate_config);
        unlike $res_str, qr/permessage-deflate/ if($server->deflate_config);
        ok !$server->is_deflate_active;

        $client->connect($res_str);
        ok $client->established;
        ok !$client->is_deflate_active;
    };

    subtest "9-bit config is allowed" => sub {
        my ($c, $s) = $create_pair->(sub {
            my ($c, $s) = @_;
            $_->configure({deflate => {
                compression_threshold  => 0,
                server_max_window_bits => 9,
                client_max_window_bits => 9,
            }}) for ($c, $s);
        });
        ok $c;
        ok $s;
    };
};

sub read_file {
    my $file = shift;
    open my $fh, '<', $file or die "cannot open $file: $!";
    local $/ = undef;
    my $ret = <$fh>;
    close $fh;
    return $ret;
} 

done_testing;
