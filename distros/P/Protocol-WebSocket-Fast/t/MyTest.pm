package MyTest;
use 5.012;
use warnings;
use Test::Catch;
use Test::More;
use Test::Deep;
use Test::Exception;
use Test::Fatal;
use Protocol::WebSocket::Fast;
use Encode::Base2N 'decode_base64';

XS::Loader::load();

init();

sub init {
    if ($ENV{LOGGER}) {
        require Panda::Lib::Logger;
        Panda::Lib::Logger::set_native_logger(sub {
            my ($level, $code, $msg) = @_;
            say "$level $code $msg";
        });
        Panda::Lib::Logger::set_log_level(Panda::Lib::Logger::LOG_VERBOSE_DEBUG());
    }
}

sub import {
    my $class = shift;

    my $caller = caller();
    foreach my $sym_name (qw/
        plan is is_deeply cmp_deeply ok done_testing skip isnt pass fail cmp_ok like isa_ok unlike ignore code all any noneof methods subtest dies_ok note
        exception
        is_bin catch_run
        OPCODE_CONTINUE OPCODE_TEXT OPCODE_BINARY OPCODE_CLOSE OPCODE_PING OPCODE_PONG
        CLOSE_DONE CLOSE_AWAY CLOSE_PROTOCOL_ERROR CLOSE_INVALID_DATA CLOSE_UNKNOWN CLOSE_ABNORMALLY CLOSE_INVALID_TEXT
        CLOSE_BAD_REQUEST CLOSE_MAX_SIZE CLOSE_EXTENSION_NEEDED CLOSE_INTERNAL_ERROR CLOSE_TLS
    /) {
        no strict 'refs';
        *{"${caller}::$sym_name"} = *$sym_name;
    }
}

sub accept_packet {
    my @data = (
        "GET /?encoding=text HTTP/1.1\r\n",
        "Host: dev.crazypanda.ru:4680\r\n",
        "Connection: Upgrade\r\n",
        "Pragma: no-cache\r\n",
        "Cache-Control: no-cache\r\n",
        "Upgrade: websocket\r\n",
        "Origin: http://www.websocket.org\r\n",
        "Sec-WebSocket-Version: 13\r\n",
        "User-Agent: Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/55.0.2883.87 Safari/537.36\r\n",
        "Accept-Encoding: gzip, deflate, sdch\r\n",
        "Accept-Language: ru-RU,ru;q=0.8,en-US;q=0.6,en;q=0.4\r\n",
        "Cookie: _ga=GA1.2.1700804447.1456741171\r\n",
        "Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==\r\n",
        #"Sec-WebSocket-Extensions: permessage-deflate; client_max_window_bits\r\n",
        "Sec-WebSocket-Protocol: chat\r\n",
        "\r\n",
    );
    return wantarray ? @data : join('', @data);
}

sub accept_parsed {
    return methods(
        headers => {
            'pragma' => 'no-cache',
            'sec-websocket-protocol' => 'chat',
            'upgrade' => 'websocket',
            #'sec-websocket-extensions' => 'permessage-deflate; client_max_window_bits',
            'accept-encoding' => 'gzip, deflate, sdch',
            'origin' => 'http://www.websocket.org',
            'cache-control' => 'no-cache',
            'connection' => 'Upgrade',
            'cookie' => '_ga=GA1.2.1700804447.1456741171',
            'sec-websocket-key' => 'dGhlIHNhbXBsZSBub25jZQ==',
            'host' => 'dev.crazypanda.ru:4680',
            'sec-websocket-version' => '13',
            'user-agent' => 'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/55.0.2883.87 Safari/537.36',
            'accept-language' => 'ru-RU,ru;q=0.8,en-US;q=0.6,en;q=0.4'
        },
        uri           => methods(to_string => '/?encoding=text'),
        #ws_extensions => [ [ 'permessage-deflate', { 'client_max_window_bits' => '' } ] ],
        ws_key        => 'dGhlIHNhbXBsZSBub25jZQ==',
        ws_protocol   => 'chat',
        ws_version    => 13,
    );
}

sub connect_request {
    return {
        uri           => URI::XS->new("ws://crazypanda.ru:4321/path?a=b"),
        ws_protocol   => 'fuck',
        ws_extensions => [ [ 'permessage-deflate', { 'client_max_window_bits' => '' } ] ],
        ws_version    => 13,
        headers       => {
            'Accept-Encoding' => 'gzip, deflate, sdch',
            'Origin'          => 'http://www.crazypanda.ru',
            'Cache-Control'   => 'no-cache',
            'User-Agent'      => 'PWS-Test',
        },
    };
}

sub connect_response {
    return all(
       qr/^GET \/path?a=b HTTP\/1.1$/,
    );
}

sub get_established_server {
    my $p = new Protocol::WebSocket::Fast::ServerParser;
    _establish_server($p);
    return $p;
}

sub _establish_server {
    my $p = shift;
    $p->accept(scalar accept_packet()) or die "should not happen";
    $p->accept_response;
    die "should not happen" unless $p->established;
}

sub reset {
    my $p = shift;
    $p->reset;
    die "should not happen" if $p->established;
    $p->isa("Protocol::WebSocket::Fast::ServerParser") ? _establish_server($p) : _establish_client($p);
}

sub get_established_client {
    my $p = new Protocol::WebSocket::Fast::ClientParser;
    _establish_client($p);
    return $p;
}

sub _establish_client {
    my $p = shift;
    my $cstr = $p->connect_request({uri => "ws://jopa.ru"});
    my $sp = new Protocol::WebSocket::Fast::ServerParser;
    $sp->accept($cstr) or die "should not happen";
    $sp->accepted or die "should not happen";
    my $rstr = $sp->accept_response;
    $p->connect($rstr) or die "should not happen";
    $p->established or die "should not happen";
    return $p;
}

sub gen_frame {
    my $params = shift;

    my $first  = 0;
    my $second = 0;

    foreach my $p (qw/fin rsv1 rsv2 rsv3/) {
        $first |= ($params->{$p} ? 1 : 0);
        $first <<= 1;
    }
    $first <<= 3;
    $first |= ($params->{opcode} & 15);
    $first = pack("C", $first);

    $second |= ($params->{mask} ? 1 : 0);

    $second <<= 7;
    my $data = $params->{data} // '';

    if ($params->{close_code} && !ref $params->{close_code}) {
        $data = pack("S>", $params->{close_code}).$data;
    }

    my $dlen = length($data);
    my $extlen = '';
    if ($dlen < 126) {
        $second |= $dlen;
    }
    elsif ($dlen < 65536) {
        $second |= 126;
        $extlen = pack "S>", $dlen;
    }
    else {
        $second |= 127;
        $extlen = pack "Q>", $dlen;
    }
    $second = pack("C", $second);

    my $mask = $params->{mask} || '';
    my $payload;

    if ($mask) {
        $mask = (length($mask) == 4) ? $mask : pack("L>", int rand(2**32-1));
        $payload = crypt_xor($data, $mask);
    } else {
        $payload = $data;
    }

    my $frame = $first.$second.$extlen.$mask.$payload;
    return $frame;
}

sub gen_message {
    my $params = shift;

    my $nframes = $params->{nframes} || 1;
    my $payload = $params->{data} // '';
    my $opcode  = $params->{opcode} // OPCODE_TEXT;

    my $frame_len = int(length($payload) / $nframes);
    my @bin;

    my $frames_left = $nframes;
    while ($frames_left) {
        my $curlen = (length($payload) / $frames_left--);
        my $chunk = substr($payload, 0, $curlen, '');
        push @bin, gen_frame({
            opcode => $opcode,
            data   => $chunk,
            fin    => !length($payload),
            mask   => $params->{mask},
        });
        $opcode = OPCODE_CONTINUE;
    }

    return wantarray ? @bin : join('', @bin);
}


sub is_bin {
    my ($got, $expected, $name) = @_;
    return if our $leak_test;
    state $has_binary = eval { require Test::BinaryData; Test::BinaryData->import(); 1 };
    $has_binary ? is_binary($got, $expected, $name) : is($got, $expected, $name);
}

sub crypt_xor {
    my ($data, $mask) = @_;
    my @key = unpack("C*", $mask);

    my $result = pack("C*", map { my $c = shift @key; push @key, $c; $_ ^ $c } unpack("C*", $data));
    return $result;
}

1;
