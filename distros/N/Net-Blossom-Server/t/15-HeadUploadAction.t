use strictures 2;

use Test::More;

use Net::Blossom::Server;
use Net::Blossom::Server::Request;

my $SHA256 = '0f343b0931126a20f133d67c2b018a3b5ceca63dd3585a76cb1f3289a274707f';

sub dies(&) {
    my ($code) = @_;
    my $ok = eval { $code->(); 1 };
    return $ok ? undef : $@;
}

{
    package Local::Storage;
    use strictures 2;

    sub new {
        my ($class) = @_;
        return bless {}, $class;
    }

    sub begin_upload {
        die "preflight must not start uploads";
    }

    sub get_blob {
        return;
    }

    sub delete_blob {
        return 0;
    }

    sub list_blobs {
        return [];
    }
}

sub request {
    my (%headers) = @_;
    return Net::Blossom::Server::Request->new(
        method  => 'HEAD',
        path    => '/upload',
        headers => \%headers,
    );
}

subtest 'handle_head_upload accepts complete BUD-06 preflight metadata' => sub {
    my $server = Net::Blossom::Server->new(storage => Local::Storage->new);

    my $response = $server->handle_head_upload(request(
        'X-SHA-256'        => $SHA256,
        'X-Content-Type'   => 'application/pdf',
        'X-Content-Length' => 184292,
    ));

    isa_ok($response, 'Net::Blossom::Server::Response');
    is($response->status, 200, 'preflight accepted');
    is($response->body, '', 'head response has empty body');
    is($response->header('content-length'), 0, 'empty content length');
};

subtest 'handle_head_upload returns BUD-06 request errors' => sub {
    my $server = Net::Blossom::Server->new(storage => Local::Storage->new);

    is($server->handle_head_upload(request(
        'X-Content-Type'   => 'application/pdf',
        'X-Content-Length' => 184292,
    ))->status, 400, 'missing X-SHA-256 is malformed');

    is($server->handle_head_upload(request(
        'X-SHA-256'        => 'A' x 64,
        'X-Content-Type'   => 'application/pdf',
        'X-Content-Length' => 184292,
    ))->status, 400, 'uppercase X-SHA-256 is malformed');

    is($server->handle_head_upload(request(
        'X-SHA-256'        => $SHA256,
        'X-Content-Length' => 184292,
    ))->status, 400, 'missing X-Content-Type is malformed');

    is($server->handle_head_upload(request(
        'X-SHA-256'      => $SHA256,
        'X-Content-Type' => 'application/pdf',
    ))->status, 411, 'missing X-Content-Length is length required');

    is($server->handle_head_upload(request(
        'X-SHA-256'        => $SHA256,
        'X-Content-Type'   => 'application/pdf',
        'X-Content-Length' => -1,
    ))->status, 400, 'bad X-Content-Length is malformed');
};

subtest 'handle_head_upload validates programmer inputs' => sub {
    my $server = Net::Blossom::Server->new(storage => Local::Storage->new);

    like(dies { $server->handle_head_upload('not a request') },
        qr/request must be a Net::Blossom::Server::Request/, 'request object required');
    like(dies {
        $server->handle_head_upload(Net::Blossom::Server::Request->new(method => 'PUT', path => '/upload'));
    }, qr/upload preflight method must be HEAD/, 'HEAD required');
    like(dies {
        $server->handle_head_upload(Net::Blossom::Server::Request->new(method => 'HEAD', path => '/media'));
    }, qr/upload preflight path must be \/upload/, 'upload path required');
    like(dies { $server->handle_head_upload(request(), bogus => 1) },
        qr/unknown option\(s\): bogus/, 'unknown option rejected');
};

done_testing;
