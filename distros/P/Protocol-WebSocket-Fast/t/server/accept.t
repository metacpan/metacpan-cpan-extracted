use 5.012;
use warnings;
use lib 't/lib';
use MyTest qw/accept_packet accept_parsed/;
use Test::More;
use Test::Deep;

my $p = new Protocol::WebSocket::Fast::ServerParser;

subtest 'parser create' => sub {
    ok($p, "parser created");
    ok(!$p->accept_parsed, "not parsed accept");
    ok(!$p->accepted, "not accepted");
    ok(!$p->established, "not established");
};

subtest 'case sensetive values' => sub {
    my $data = accept_packet();
    $data =~ s/Upgrade: websocket\r\n/upgrade: websocket\r\n/;
    $data =~ s/Connection: Upgrade\r\n/connection: upgrade\r\n/;
    my $creq = $p->accept($data);
    ok($creq, "accept done");
    ok($p->accepted, "now accepted");
};
$p->reset();

subtest 'accept chunks' => sub {
    my @data = accept_packet();
    my $last = pop @data;
    foreach my $line (@data) {
        is($p->accept($line), undef, "no full data");
    }
    my $creq = $p->accept($last);
    ok($creq, "accept done");
    cmp_deeply($creq, accept_parsed(), "request correct");
    ok($p->accepted, "now accepted");
    ok(!$p->established, "still not established");
};

$p->reset();
ok(!$p->accept_parsed, "not parsed accept after reset");
ok(!$p->accepted, "not accepted after reset");

subtest 'accept all' => sub {
    my $data = accept_packet();
    cmp_deeply($p->accept($data), accept_parsed(), "request correct");
    ok($p->accepted, "now accepted");
};

$p->reset();

subtest 'accept with body' => sub {
    my @data = accept_packet();
    splice(@data, 1, 0, "Content-Length: 1\r\n");
    push @data, '1';
    my $creq;
    for my $chunk (@data) {
        $creq = $p->accept($chunk);
        last if ($creq && $creq->error);
    }
    ok($creq && $creq->error, "body disallowed");
    ok(!$p->accepted, "not accepted");
};

$p->reset();

subtest 'max_handshake_size' => sub {
    my @data = accept_packet();
    my $last = pop @data;
    my $big  = ("header: value\r\n" x 100);
    $p->accept($_) for @data;
    $p->accept($big);
    my $creq = $p->accept($last);
    ok($creq, "default unlimited buffer");
    ok(!$creq->error, "default unlimited buffer");
    is($creq->header('header'), "value", "default unlimited buffer");
    
    $p->reset();
    
    $p->configure({max_handshake_size => 1000});
    $p->accept($_) for @data;
    $creq = $p->accept($big);
    ok($creq, "buffer limit exceeded");
    is($creq->error, Protocol::HTTP::Error::headers_too_large(), "buffer limit exceeded");
};

$p->reset();

done_testing();
