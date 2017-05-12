#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

use Protocol::WebSocket::Handshake::Client;
use Protocol::WebSocket::Frame;
use IO::Socket::INET;

my $child;
sub cleanup { kill 9 => $child if $child && $child > 0 }
$SIG{ALRM} = sub { cleanup; die "test timed out\n"; };
alarm(10);

my $listen = IO::Socket::INET->new(Listen => 2, Proto => 'tcp', Timeout => 5) or die "$!";

sub accursed_win32_pipe_simulation {
  my $listen = IO::Socket::INET->new(Listen => 2, Proto => 'tcp', Timeout => 5, Blocking => 0) or die "$!";
  my $port = $listen->sockport;
  my $a = IO::Socket::INET->new(PeerPort => $port, Proto => 'tcp', PeerAddr => '127.0.0.1', Blocking => 0)
          or die "failed to connect to 127.0.0.1: $!";
  my $b = $listen->accept;
  $a->blocking(1);
  $b->blocking(1);
  return ($a, $b);
}

my ($read_test_out, $read_test_in, $write_test_out, $write_test_in);
if ($^O eq 'MSWin32' || $^O eq 'cygwin') {
  ($read_test_out, $read_test_in) = accursed_win32_pipe_simulation();
  ($write_test_out, $write_test_in) = accursed_win32_pipe_simulation();
} else {
  pipe $read_test_out, $read_test_in;
  pipe $write_test_out, $write_test_in;
}
$read_test_in->autoflush(1);
$write_test_in->autoflush(1);
$write_test_in->blocking(0);
#fill write pipe so it's not ready for writing yet
my $write_pipe_size = 0;
while (1) {
  my $w = syswrite($write_test_in, "a" x 1024);
  $write_pipe_size += $w if defined $w;
  last if !defined $w || $w < 1024;
}
$write_test_in->blocking(1);

unless ($child = fork) {
  delete $SIG{ALRM};
  require Net::WebSocket::Server;

  Net::WebSocket::Server->new(
    listen => $listen,
    watch_readable => [
      $read_test_out => sub {
        my ($serv, $fh) = @_;
        my $data;
        sysread($fh, $data, 1);
        $_->send_binary("read_test_out(".length($data).") = $data") for $serv->connections;
        $serv->unwatch_readable($fh);
      },
    ],
    watch_writable => [
      $write_test_in => sub {
        my ($serv, $fh) = @_;
        syswrite($fh, "W");
        $serv->unwatch_writable($fh);
      },
    ],
    on_connect => sub {
      my ($serv, $conn) = @_;
      $conn->on(
        handshake => sub {
          my ($conn, $hs) = @_;
          die "bad handshake origin: " . $hs->req->origin unless $hs->req->origin eq 'http://localhost';
          die "bad subprotocol: " . $hs->req->subprotocol unless $hs->req->subprotocol eq 'test subprotocol';
        },
        ready => sub {
          my ($conn) = @_;
          $conn->send_binary("ready");
        },
        utf8 => sub {
          my ($conn, $msg) = @_;
          $conn->send_utf8("utf8(".length($msg).") = $msg");
        },
        binary => sub {
          my ($conn, $msg) = @_;
          $conn->send_binary("binary(".length($msg).") = $msg");
        },
        pong => sub {
          my ($conn, $msg) = @_;
          $conn->send_binary("pong(".length($msg).") = $msg");
        },
        disconnect => sub {
          my ($conn, $code, $reason) = @_;
          die "bad disconnect code" unless defined $code && $code == 4242;
          die "bad disconnect reason" unless defined $reason && $reason eq 'test server shutdown cleanly';
          $serv->shutdown();
        },
      );
    },
  )->start;

  exit;
}

my ($port, $sock);

subtest "initialize client socket" => sub {
  $port = $listen->sockport;
  $sock = IO::Socket::INET->new(PeerPort => $port, Proto => 'tcp', PeerAddr => '127.0.0.1')
          or die "failed to connect to 127.0.0.1: $!";
  ok(1);
};

my $buf = "";
my $hs;

subtest "handshake send" => sub {
  $hs = Protocol::WebSocket::Handshake::Client->new(url => 'ws://localhost/testserver');
  $hs->req->subprotocol("test subprotocol");
  print $sock $hs->to_string;
  ok(1);
};

subtest "handshake recv" => sub {
  while(sysread($sock, $buf, 8192, length($buf))) {
    $hs->parse($buf);
    last if $hs->is_done;
  }

  ok(!$hs->error, "completed handshake with server without error");
};

my $parser;

subtest "initialize parser" => sub {
  $parser = new Protocol::WebSocket::Frame();
  $parser->append($buf);
  ok(1);
};

subtest "ready message" => sub {
  my $bytes = _recv($sock => $parser);
  ok($parser->is_binary, "expected binary message");
  is($bytes, "ready", "expected welcome 'ready' message");
};

subtest "echo utf8" => sub {
  foreach my $msg ("simple", "", ("a" x 32768), "unicode \u2603 snowman", "hiragana \u3072\u3089\u304c\u306a null \x00 ctrls \cA \cF \n \e del \x7f end") {
    print $sock Protocol::WebSocket::Frame->new(type=>'text', buffer=>$msg)->to_bytes;
    my $bytes = _recv($sock => $parser);
    ok($parser->is_text, "expected text message");
    is($bytes, "utf8(" . length($msg) . ") = $msg");
  }
};

subtest "echo binary" => sub {
  foreach my $msg ("simple", "", ("a" x 32768), "unicode \u2603 snowman", "hiragana \u3072\u3089\u304c\u306a null \x00 ctrls \cA \cF \n \e del \x7f end", join("", map{chr($_)} 0..255)) {
    print $sock Protocol::WebSocket::Frame->new(type=>'binary', buffer=>$msg)->to_bytes;
    my $bytes = _recv($sock => $parser);
    ok($parser->is_binary, "expected binary message");
    is($bytes, "binary(" . length($msg) . ") = $msg");
  }
};

subtest "echo pong" => sub {
  foreach my $msg ("simple", "", ("a" x 32768), "unicode \u2603 snowman", "hiragana \u3072\u3089\u304c\u306a null \x00 ctrls \cA \cF \n \e del \x7f end", join("", map{chr($_)} 0..255)) {
    print $sock Protocol::WebSocket::Frame->new(type=>'pong', buffer=>$msg)->to_bytes;
    my $bytes = _recv($sock => $parser);
    ok($parser->is_binary, "expected binary message");
    is($bytes, "pong(" . length($msg) . ") = $msg");
  }
};

subtest "watch_readable" => sub {
  syswrite($read_test_in, "R");
  my $bytes = _recv($sock => $parser);
  ok($parser->is_binary, "expected binary message");
  is($bytes, "read_test_out(1) = R");
};

subtest "watch_writable" => sub {
  my ($bytes_read, $scratch, $value);
  while ($write_pipe_size) {
    $bytes_read = sysread($write_test_out, $scratch, $write_pipe_size > 8192 ? 8192 : $write_pipe_size);
    die "watch_writable sysread: $!" unless defined $bytes_read;
    $write_pipe_size -= $bytes_read;
  }
  sysread($write_test_out, $value, 1);
  is($value, "W");
};

subtest "server shutdown" => sub {
  ok((kill 0 => $child), "child should still be alive");
  print $sock Protocol::WebSocket::Frame->new(type=>'close', buffer=>pack("n",4242)."test server shutdown cleanly")->to_bytes;
  waitpid $child, 0;
  ok(!(kill 0 => $child), "child should have shut down cleanly");
};

done_testing();
cleanup();

sub _recv {
  my ($sock, $parser) = @_;

  my $message;
  while (!defined($message = $parser->next_bytes)) {
    my $data;
    die "expected read but socket seems to be disconnected" unless defined sysread($sock, $data, 8192);
    $parser->append($data);
  }
  return $message;
}
