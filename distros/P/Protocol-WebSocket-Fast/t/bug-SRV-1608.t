use 5.012;
use warnings;
use lib 't/lib'; use MyTest;
use Test::More;

plan skip_all => "set TEST_FULL" unless $ENV{TEST_FULL};

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


subtest 'lorem-ipsum' => sub {
    my $sample = '00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000';
    my @payload = ('bla-bladddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd', 
        ( ($sample) x 500000 ),
    );
    my ($c, $s) = $create_pair->();
    my $bin = $s->start_message(deflate => 1)->send(\@payload);
    pass "no crash occur";
};


done_testing;
