use strict;
use warnings;
use Test::More;
use IO::Socket::INET;
use Time::HiRes qw(time sleep);
use POSIX qw(_exit);
use Net::UPnP::HTTP;
use Net::UPnP::Device;

sub server {
    my ($handler) = @_;
    my $listener = IO::Socket::INET->new(LocalAddr => '127.0.0.1',
        LocalPort => 0, Listen => 1, ReuseAddr => 1) or die "listen: $!";
    my $port = $listener->sockport;
    my $pid = fork();
    die "fork: $!" unless defined $pid;
    if (!$pid) {
        local $SIG{PIPE} = 'IGNORE';
        alarm 4;
        my $client = $listener->accept() or _exit(1);
        $client->autoflush(1);
        while (my $line = <$client>) { last if $line eq "\r\n"; }
        eval { $handler->($client); };
        close $client;
        _exit(0);
    }
    close $listener;
    return ($port, $pid);
}

sub request {
    my ($handler, %options) = @_;
    my ($port, $pid) = server($handler);
    my $http = Net::UPnP::HTTP->new(timeout => 0.3, %options);
    my $start = time();
    my ($response, $error);
    eval {
        local $SIG{ALRM} = sub { die "test watchdog\n" };
        alarm 3;
        $response = $http->post('127.0.0.1', $port, 'GET', '/', '', '');
        alarm 0;
    };
    $error = $@;
    alarm 0;
    my $elapsed = time() - $start;
    kill 'KILL', $pid;
    waitpid($pid, 0);
    die $error if $error;
    return ($response, $http->geterror(), $elapsed);
}

for my $case (
    ["HTTP/1.1 200 OK\r\nX-Test: yes\r\nContent-Length: 5\r\n\r\nhello", 'hello', 'nonfirst Content-Length'],
    ["HTTP/1.0 200 OK\r\n\r\nhello", 'hello', 'EOF body'],
    ["HTTP/1.1 200 OK\r\nTransfer-Encoding: chunked\r\n\r\n2;x=y\r\nhe\r\n3\r\nllo\r\n0\r\nX-Trailer: yes\r\n\r\n", 'hello', 'chunked with extension/trailer'],
) {
    my ($wire, $body, $name) = @$case;
    my ($res, $error) = request(sub { print {$_[0]} $wire; });
    ok($res, "$name succeeds") or diag $error;
    is($res ? $res->getcontent() : undef, $body, "$name retains body");
}

for my $wire (
    "HTTP/1.1 200 OK\r\nContent-Length: 0\r\n\r\n",
    "HTTP/1.1 200 OK\r\nTransfer-Encoding: chunked\r\n\r\n0\r\n\r\n",
    "HTTP/1.1 204 No Content\r\n\r\n",
) {
    my ($res, $error, $elapsed) = request(sub { print {$_[0]} $wire; sleep 1; });
    ok($res, 'framed empty body finishes without waiting for EOF') or diag $error;
    is($res ? $res->getcontent() : undef, '', 'empty body preserved');
    cmp_ok($elapsed, '<', 0.25, 'completion does not wait for socket closure');
}

for my $case (
    [sub { sleep 1; }, 'silent peer'],
    [sub { print {$_[0]} "HTTP/1.1 200 OK\r\nX:"; sleep 1; }, 'unterminated header'],
    [sub { print {$_[0]} "HTTP/1.1 200 OK\r\nContent-Length: 5\r\n\r\na"; sleep 1; }, 'stalled body'],
    [sub { print {$_[0]} "HTTP/1.1 200 OK\r\nTransfer-Encoding: chunked\r\n\r\n3\r\na"; sleep 1; }, 'stalled chunk'],
    [sub { for (1 .. 100) { print {$_[0]} 'a'; sleep 0.03; } }, 'slow trickle'],
) {
    my ($res, $error, $elapsed) = request($case->[0], timeout => 0.12);
    ok(!$res, "$case->[1] fails");
    like($error, qr/deadline/, "$case->[1] reports deadline");
    cmp_ok($elapsed, '<', 0.7, "$case->[1] has total deadline");
}

for my $case (
    ["HTTP/1.1 200 OK\r\nContent-Length: 99999999999999999999\r\n\r\n", {}, 'declared length'],
    ["HTTP/1.1 200 OK\r\n\r\n" . ('a' x 65), {}, 'EOF body'],
    ["HTTP/1.1 200 OK\r\nTransfer-Encoding: chunked\r\n\r\nffffffffffffffff\r\n", {}, 'huge chunk'],
    ["HTTP/1.1 200 OK\r\nTransfer-Encoding: chunked\r\n\r\n" . ("10\r\n" . ('a' x 16) . "\r\n") x 5, {}, 'cumulative chunks'],
    ['a' x 65, {max_line_bytes => 64}, 'unterminated status line'],
    ["HTTP/1.1 200 OK\r\n" . ('X' x 65), {max_line_bytes => 64}, 'unterminated header line'],
    ["HTTP/1.1 200 OK\r\n" . ("X: y\r\n" x 20) . "\r\n", {max_header_bytes => 64}, 'aggregate headers'],
    ["HTTP/1.1 200 OK\r\nTransfer-Encoding: chunked\r\n\r\n" . ('f' x 65), {max_line_bytes => 64}, 'chunk size line'],
    ["HTTP/1.1 200 OK\r\nTransfer-Encoding: chunked\r\n\r\n0\r\n" . ("X: y\r\n" x 20) . "\r\n", {max_header_bytes => 100}, 'trailers'],
) {
    my ($wire, $options, $name) = @$case;
    my ($res, $error) = request(sub { print {$_[0]} $wire; }, max_body_bytes => 64, %$options);
    ok(!$res, "$name over budget fails");
    like($error, qr/limit/, "$name reports resource limit");
}

for my $wire (
    "HTTP/1.1 200 OK\r\nContent-Length: 5\r\n\r\nhi",
    "HTTP/1.1 200 OK\r\nContent-Length: -1\r\n\r\n",
    "HTTP/1.1 200 OK\r\nContent-Length: 1\r\nContent-Length: 2\r\n\r\naa",
    "HTTP/1.1 200 OK\r\nTransfer-Encoding: chunked\r\nContent-Length: 0\r\n\r\n",
    "HTTP/1.1 200 OK\r\nTransfer-Encoding: chunked\r\n\r\n1\r\naXX0\r\n\r\n",
) {
    my ($res, $error) = request(sub { print {$_[0]} $wire; });
    ok(!$res, 'incomplete or malformed framing fails explicitly');
    ok(length($error), 'framing failure has diagnostic');
}

{
    my ($port, $pid) = server(sub { print {$_[0]} "HTTP/1.1 200 OK\r\nContent-Length: 2\r\n\r\nok"; });
    my $http = Net::UPnP::HTTP->new();
    local $SIG{ALRM} = sub { die "caller alarm fired\n" };
    alarm 3;
    my $res = $http->post('localhost', $port, 'GET', '/', '', '');
    my $remaining = alarm 0;
    ok($res && $res->getcontent() eq 'ok', 'hostname resolution retains legitimate response');
    cmp_ok($remaining, '>', 0, 'caller alarm remains active');
    waitpid($pid, 0);
}

{
    no warnings 'redefine';
    local *Net::UPnP::HTTP::inet_aton = sub { sleep 2; return pack('C4', 127, 0, 0, 1); };
    my $http = Net::UPnP::HTTP->new(timeout => 0.1);
    my $start = time();
    ok(!$http->post('slow.invalid', 80, 'GET', '/', '', ''), 'stalled resolver fails');
    like($http->geterror(), qr/deadline/, 'DNS uses transaction deadline');
    cmp_ok(time() - $start, '<', 0.7, 'resolver cannot extend deadline');
}

{
    no warnings 'redefine';
    local *Net::UPnP::HTTP::postsoap = sub { return ''; };
    my $device = Net::UPnP::Device->new();
    $device->setssdp("LOCATION: http://127.0.0.1/desc\r\n");
    $device->setdescription('<serviceList><service><serviceType>test</serviceType><controlURL>/control</controlURL></service></serviceList>');
    my ($service) = $device->getservicelist();
    is($service->postaction('Test', {})->getstatuscode(), 0, 'action failure has safe status 0');
    is($service->postcontrol('Test', {})->getstatuscode(), 0, 'deprecated action alias has safe status 0');
    is($service->postquery('Test')->getstatuscode(), 0, 'query failure has safe status 0');
}

{
    pipe(my $reader, my $writer) or die $!;
    my $pid = fork(); die $! unless defined $pid;
    if (!$pid) {
        close $reader;
        sleep 0.1;
        syswrite($writer, 'x');
        _exit(0);
    }
    close $writer;
    my $signals = 0;
    local $SIG{ALRM} = sub { ++$signals; };
    Time::HiRes::alarm(0.02);
    my $ok = eval { Net::UPnP::HTTP::_wait($reader, 0, Net::UPnP::HTTP::_now() + 1); 1; };
    Time::HiRes::alarm(0);
    ok($ok, 'harmless signal does not terminate HTTP wait') or diag $@;
    is($signals, 1, 'caller signal handler still runs');
    close $reader;
    waitpid($pid, 0);
}

for my $options (
    {timeout => '9' x 400}, {max_body_bytes => '9' x 400},
    {deadline => '9' x 400}, {max_line_bytes => 0.5},
) {
    my $ok = eval { Net::UPnP::HTTP->new(%$options); 1; };
    ok(!$ok, 'nonfinite or fractional byte limit rejected');
}

done_testing;
