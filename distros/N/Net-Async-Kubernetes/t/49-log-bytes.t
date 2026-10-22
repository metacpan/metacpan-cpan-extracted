use strict;
use warnings;
use Test::More;

use IO::Async::Loop;
use IO::Async::Listener;
use Future;

use Net::Async::Kubernetes;

# Pod log output is bytes, one-shot and streaming alike (Kubernetes::REST's
# encoding contract): the real transport against a plain HTTP server on the
# loopback interface answering a UTF-8 log as text/plain - no cluster.
# HTTP::Response->decoded_content would turn that into characters.

my $loop = IO::Async::Loop->new;

my $log = "h\xc3\xa4llo \xe2\x82\xac\n";

my $listener = IO::Async::Listener->new(
    on_stream => sub {
        my (undef, $stream) = @_;
        $stream->configure(
            on_read => sub {
                my ($s, $buffref) = @_;
                return 0 unless $$buffref =~ s/\A(.*?)\r\n\r\n//s;
                $s->write(join "\r\n",
                    'HTTP/1.1 200 OK',
                    'Content-Type: text/plain; charset=utf-8',
                    'Content-Length: ' . length($log),
                    'Connection: close',
                    '',
                    $log,
                );
                $s->close_when_empty;
                return 0;
            },
        );
        $loop->add($stream);
    },
);
$loop->add($listener);
$listener->listen(
    addr => { family => 'inet', socktype => 'stream', ip => '127.0.0.1', port => 0 },
)->get;
my $port = $listener->read_handle->sockport;

my $kube = Net::Async::Kubernetes->new(
    server      => { endpoint => "http://127.0.0.1:$port" },
    credentials => { token => 'test-token' },
    resource_map_from_cluster => 0,
);
$loop->add($kube);

sub await_f {
    my ($f) = @_;
    my $timeout = $loop->watch_time(after => 5, code => sub {
        $f->fail('test timed out') unless $f->is_ready;
    });
    $loop->await($f);
    $loop->unwatch_time($timeout);
    return $f;
}

my $f = await_f($kube->log('Pod', 'nginx', namespace => 'default'));
ok($f->is_done, 'one-shot log resolved') or diag($f->failure);
my $text = $f->is_done ? $f->get : '';

my @lines;
my $s = await_f($kube->log('Pod', 'nginx',
    namespace => 'default',
    follow    => 1,
    on_line   => sub { push @lines, $_[0]->line },
));
ok($s->is_done, 'streaming log resolved') or diag($s->failure);

ok(!utf8::is_utf8($text), 'one-shot log is not a character string');
is(length($text), length($log), 'one-shot length is in bytes');
is($text, $log, 'one-shot log is the raw bytes');

is(scalar(@lines), 1, 'streaming log: one line');
ok(!utf8::is_utf8($lines[0]), 'streamed line is not a character string');
is($lines[0] . "\n", $text, 'one-shot and streaming deliver the same bytes');

done_testing;
