use strictures 2;

use Test::More;

use Net::Blossom::Server;
use Net::Blossom::Server::Request;

my $SHA256 = '0f343b0931126a20f133d67c2b018a3b5ceca63dd3585a76cb1f3289a274707f';
my $PUBKEY = '79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798';

sub dies(&) {
    my ($code) = @_;
    my $ok = eval { $code->(); 1 };
    return $ok ? undef : $@;
}

{
    package Local::Storage;
    use strictures 2;

    sub new {
        my ($class, %args) = @_;
        return bless { deleted => $args{deleted} }, $class;
    }

    sub begin_upload {
        return Local::Upload->new;
    }

    sub get_blob {
        return;
    }

    sub delete_blob {
        my ($self, $sha256, %opts) = @_;
        $self->{last_delete_blob} = [$sha256, \%opts];
        return $self->{deleted};
    }

    sub list_blobs {
        return [];
    }

    sub last_delete_blob {
        my ($self) = @_;
        return $self->{last_delete_blob};
    }
}

{
    package Local::Upload;
    use strictures 2;

    sub new {
        my ($class) = @_;
        return bless {}, $class;
    }

    sub write {
        return length $_[1];
    }

    sub commit {
        return;
    }

    sub abort {
        return 1;
    }
}

sub request {
    my (%args) = @_;
    return Net::Blossom::Server::Request->new(
        method => $args{method},
        path   => $args{path},
    );
}

subtest 'handle_delete_blob returns 204 when storage deletes an owner' => sub {
    my $storage = Local::Storage->new(deleted => 1);
    my $server = Net::Blossom::Server->new(storage => $storage);

    my $response = $server->handle_delete_blob(
        request(method => 'DELETE', path => "/$SHA256"),
        pubkey => $PUBKEY,
    );

    isa_ok($response, 'Net::Blossom::Server::Response');
    is($response->status, 204, 'deleted status');
    is($response->body, '', 'deleted body');
    is($response->header('content-length'), 0, 'deleted content length');
    is_deeply($storage->last_delete_blob, [$SHA256, { pubkey => $PUBKEY }], 'delete passed to storage');
};

subtest 'handle_delete_blob returns 404 when storage does not delete' => sub {
    my $storage = Local::Storage->new(deleted => 0);
    my $server = Net::Blossom::Server->new(storage => $storage);

    my $response = $server->handle_delete_blob(
        request(method => 'DELETE', path => "/$SHA256"),
        pubkey => $PUBKEY,
    );

    isa_ok($response, 'Net::Blossom::Server::Response');
    is($response->status, 404, 'missing delete status');
    is($response->body, '', 'missing delete body');
    is($response->header('content-length'), 0, 'missing delete content length');
    is_deeply($storage->last_delete_blob, [$SHA256, { pubkey => $PUBKEY }], 'missing delete passed to storage');
};

subtest 'handle_delete_blob validates request inputs' => sub {
    my $storage = Local::Storage->new(deleted => 1);
    my $server = Net::Blossom::Server->new(storage => $storage);

    like(dies { $server->handle_delete_blob('not a request', pubkey => $PUBKEY) },
        qr/request must be a Net::Blossom::Server::Request/, 'request object required');
    like(dies { $server->handle_delete_blob(request(method => 'GET', path => "/$SHA256"), pubkey => $PUBKEY) },
        qr/delete request method must be DELETE/, 'method rejected');
    like(dies { $server->handle_delete_blob(request(method => 'DELETE', path => '/missing'), pubkey => $PUBKEY) },
        qr/blob request path must be \/<sha256>/, 'path shape rejected');
    like(dies { $server->handle_delete_blob(request(method => 'DELETE', path => '/' . uc($SHA256)), pubkey => $PUBKEY) },
        qr/sha256 must be 64-char lowercase hex/, 'uppercase hash rejected');
    like(dies { $server->handle_delete_blob(request(method => 'DELETE', path => "/$SHA256")) },
        qr/pubkey is required/, 'pubkey required');
    like(dies { $server->handle_delete_blob(request(method => 'DELETE', path => "/$SHA256"), pubkey => []) },
        qr/pubkey must be a scalar/, 'pubkey scalar required');
    like(dies { $server->handle_delete_blob(request(method => 'DELETE', path => "/$SHA256"), pubkey => 'A' x 64) },
        qr/pubkey must be 64-char lowercase hex/, 'uppercase pubkey rejected');
    like(dies { $server->handle_delete_blob(request(method => 'DELETE', path => "/$SHA256"), pubkey => $PUBKEY, bogus => 1) },
        qr/unknown option\(s\): bogus/, 'unknown option rejected');
    is($storage->last_delete_blob, undef, 'invalid requests do not reach storage');
};

done_testing;
