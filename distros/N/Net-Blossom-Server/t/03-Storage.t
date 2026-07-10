use strictures 2;

use Test::More;
use Digest::SHA qw(sha256_hex);

use Net::Blossom::BlobDescriptor;
use Net::Blossom::Server;
use Net::Blossom::Server::Storage;
use Net::Blossom::Server::UploadResult;

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
        return bless { uploads => [], %args }, $class;
    }

    sub begin_upload {
        my ($self, %args) = @_;
        my $upload = Local::Upload->new($self, \%args);
        push @{$self->{uploads}}, $upload;
        return $upload;
    }

    sub get_blob {
        return;
    }

    sub delete_blob {
        return 1;
    }

    sub list_blobs {
        return [];
    }

    sub uploads {
        my ($self) = @_;
        return @{$self->{uploads}};
    }
}

{
    package Local::Upload;
    use strictures 2;

    sub new {
        my ($class, $storage, $args) = @_;
        return bless {
            storage    => $storage,
            args       => $args,
            chunks     => [],
            commit     => undef,
            aborted    => 0,
            fail_write => $storage->{fail_write},
            bad_commit => $storage->{bad_commit},
            existing   => $storage->{existing},
            result_obj => $storage->{result_obj},
            bad_created => $storage->{bad_created},
        }, $class;
    }

    sub write {
        my ($self, $chunk) = @_;
        die "write failed" if $self->{fail_write};
        push @{$self->{chunks}}, $chunk;
        return length $chunk;
    }

    sub commit {
        my ($self, %args) = @_;
        $self->{commit} = \%args;
        $args{sha256} = 'f' x 64 if $self->{bad_commit};
        my $descriptor = {
            url      => "https://cdn.example.com/$args{sha256}",
            sha256   => $args{sha256},
            size     => $args{size},
            type     => $args{type},
            uploaded => $args{uploaded},
        };
        my $created = $self->{existing} ? 0 : 1;
        $created = 2 if $self->{bad_created};

        return Net::Blossom::Server::UploadResult->new(
            descriptor => Net::Blossom::BlobDescriptor->from_hash($descriptor),
            created    => $created,
        ) if $self->{result_obj};

        return { descriptor => $descriptor, created => $created }
            if $self->{existing} || $self->{bad_created};

        return $descriptor;
    }

    sub abort {
        my ($self) = @_;
        $self->{aborted}++;
        return 1;
    }
}

{
    package Local::MissingList;
    use strictures 2;

    sub new {
        my ($class) = @_;
        return bless {}, $class;
    }

    sub begin_upload {
        return;
    }

    sub get_blob {
        return;
    }

    sub delete_blob {
        return;
    }
}

{
    package Local::ReadStream;
    use strictures 2;

    sub new {
        my ($class, $data) = @_;
        return bless { data => $data, offset => 0 }, $class;
    }

    sub read {
        my ($self, undef, $length) = @_;
        return 0 if $self->{offset} >= length $self->{data};
        $_[1] = substr($self->{data}, $self->{offset}, $length);
        $self->{offset} += length $_[1];
        return length $_[1];
    }
}

subtest 'documents required storage methods' => sub {
    is_deeply(
        [Net::Blossom::Server::Storage->required_methods],
        [qw(begin_upload get_blob delete_blob list_blobs)],
        'required methods',
    );

    my $storage = Local::Storage->new;
    ok(Net::Blossom::Server::Storage->assert_implements($storage), 'complete storage accepted');
    like(dies { Net::Blossom::Server::Storage->assert_implements(Local::MissingList->new) },
        qr/storage must provide list_blobs/, 'missing method rejected');
};

subtest 'server requires storage contract' => sub {
    like(dies { Net::Blossom::Server->new },
        qr/storage is required/, 'storage required');
    like(dies { Net::Blossom::Server->new(storage => Local::MissingList->new) },
        qr/storage must provide list_blobs/, 'incomplete storage rejected');
    like(dies { Net::Blossom::Server->new(storage => Local::Storage->new, chunk_size => 0) },
        qr/chunk_size must be a positive integer/, 'bad chunk size rejected');
};

subtest 'receive_blob hashes scalar bodies and commits storage writes' => sub {
    my $storage = Local::Storage->new;
    my $server = Net::Blossom::Server->new(
        storage => $storage,
        clock   => sub { 1725105921 },
    );
    my $body = "hello blossom\n";

    my $result = $server->receive_blob(
        $body,
        type           => 'text/plain',
        expected_sha256 => sha256_hex($body),
        content_length => length($body),
        pubkey         => $PUBKEY,
    );

    isa_ok($result, 'Net::Blossom::Server::UploadResult');
    is($result->created, 1, 'raw descriptor commit defaults to created');
    my $blob = $result->descriptor;
    isa_ok($blob, 'Net::Blossom::BlobDescriptor');
    is($blob->sha256, sha256_hex($body), 'computed sha256');
    is($blob->size, length($body), 'computed size');
    is($blob->type, 'text/plain', 'content type');
    is($blob->uploaded, 1725105921, 'uploaded timestamp from clock');

    my ($upload) = $storage->uploads;
    is_deeply($upload->{chunks}, [$body], 'scalar body written to storage');
    is($upload->{args}{expected_sha256}, sha256_hex($body), 'expected hash passed to storage');
    is($upload->{args}{content_length}, length($body), 'content length passed to storage');
    is($upload->{args}{pubkey}, $PUBKEY, 'pubkey passed to storage');
    is($upload->{commit}{sha256}, sha256_hex($body), 'commit receives sha256');
    is($upload->{commit}{size}, length($body), 'commit receives size');
    is($upload->{commit}{pubkey}, $PUBKEY, 'commit receives pubkey');
    is($upload->{aborted}, 0, 'upload not aborted');
};

subtest 'receive_blob streams chunks while hashing' => sub {
    my $storage = Local::Storage->new;
    my $server = Net::Blossom::Server->new(
        storage    => $storage,
        chunk_size => 4,
        clock      => sub { 1725105922 },
    );
    my $body = 'abcdefghijkl';

    my $result = $server->receive_blob(Local::ReadStream->new($body), type => 'application/octet-stream');
    is($result->created, 1, 'stream upload created');
    my $blob = $result->descriptor;

    is($blob->sha256, sha256_hex($body), 'stream sha256');
    is($blob->size, length($body), 'stream size');

    my ($upload) = $storage->uploads;
    is_deeply($upload->{chunks}, [qw(abcd efgh ijkl)], 'stream written in chunks');
};

subtest 'receive_blob returns existing upload results from storage' => sub {
    my $storage = Local::Storage->new(existing => 1);
    my $server = Net::Blossom::Server->new(storage => $storage);
    my $result = $server->receive_blob('body');

    isa_ok($result, 'Net::Blossom::Server::UploadResult');
    is($result->created, 0, 'existing upload result');
    isa_ok($result->descriptor, 'Net::Blossom::BlobDescriptor');
};

subtest 'receive_blob accepts upload result objects from storage' => sub {
    my $storage = Local::Storage->new(result_obj => 1);
    my $server = Net::Blossom::Server->new(storage => $storage);
    my $result = $server->receive_blob('body');

    isa_ok($result, 'Net::Blossom::Server::UploadResult');
    is($result->created, 1, 'object upload result');
};

subtest 'receive_blob omits absent optional upload context' => sub {
    my $storage = Local::Storage->new;
    my $server = Net::Blossom::Server->new(storage => $storage);

    $server->receive_blob('body');

    my ($upload) = $storage->uploads;
    is_deeply($upload->{args}, { type => 'application/octet-stream' }, 'only defined upload context passed');
};

subtest 'receive_blob aborts failed uploads' => sub {
    my $storage = Local::Storage->new;
    my $server = Net::Blossom::Server->new(storage => $storage);
    my $body = 'not the expected blob';

    like(dies {
        $server->receive_blob($body, expected_sha256 => '0' x 64);
    }, qr/sha256 mismatch/, 'hash mismatch rejected');

    my ($upload) = $storage->uploads;
    is($upload->{commit}, undef, 'mismatch does not commit');
    is($upload->{aborted}, 1, 'mismatch aborts upload');
};

subtest 'receive_blob aborts authorized hash mismatches before commit' => sub {
    my $storage = Local::Storage->new;
    my $server = Net::Blossom::Server->new(storage => $storage);

    my $error = dies {
        $server->receive_blob(
            'body',
            allowed_sha256         => ['0' x 64],
            sha256_mismatch_status => 409,
            sha256_mismatch_reason => 'mirrored blob hash is not authorized',
        );
    };

    isa_ok($error, 'Net::Blossom::Server::Error');
    is($error->status, 409, 'typed mismatch status');
    is($error->reason, 'mirrored blob hash is not authorized', 'typed mismatch reason');

    my ($upload) = $storage->uploads;
    is($upload->{commit}, undef, 'authorized hash mismatch does not commit');
    is($upload->{aborted}, 1, 'authorized hash mismatch aborts upload');
};

subtest 'receive_blob aborts content length mismatches' => sub {
    my $storage = Local::Storage->new;
    my $server = Net::Blossom::Server->new(storage => $storage);
    my $body = 'short';

    like(dies {
        $server->receive_blob($body, content_length => length($body) + 1);
    }, qr/content_length mismatch/, 'content length mismatch rejected');

    my ($upload) = $storage->uploads;
    is($upload->{commit}, undef, 'length mismatch does not commit');
    is($upload->{aborted}, 1, 'length mismatch aborts upload');
};

subtest 'receive_blob can report content length mismatches as typed errors' => sub {
    my $storage = Local::Storage->new;
    my $server = Net::Blossom::Server->new(storage => $storage);
    my $body = 'short';

    my $error = dies {
        $server->receive_blob(
            $body,
            content_length                 => length($body) + 1,
            content_length_mismatch_status => 400,
            content_length_mismatch_reason => 'content_length mismatch',
        );
    };

    isa_ok($error, 'Net::Blossom::Server::Error');
    is($error->status, 400, 'typed content length mismatch status');
    is($error->reason, 'content_length mismatch', 'typed content length mismatch reason');

    my ($upload) = $storage->uploads;
    is($upload->{commit}, undef, 'length mismatch does not commit');
    is($upload->{aborted}, 1, 'length mismatch aborts upload');
};

subtest 'receive_blob aborts storage write failures' => sub {
    my $storage = Local::Storage->new(fail_write => 1);
    my $server = Net::Blossom::Server->new(storage => $storage);

    like(dies {
        $server->receive_blob('body');
    }, qr/write failed/, 'storage write failure propagated');

    my ($upload) = $storage->uploads;
    is($upload->{commit}, undef, 'write failure does not commit');
    is($upload->{aborted}, 1, 'write failure aborts upload');
};

subtest 'receive_blob rejects inconsistent storage descriptors' => sub {
    my $storage = Local::Storage->new(bad_commit => 1);
    my $server = Net::Blossom::Server->new(storage => $storage);

    like(dies {
        $server->receive_blob('body');
    }, qr/storage returned descriptor sha256 mismatch/, 'bad storage descriptor rejected');

    my ($upload) = $storage->uploads;
    ok($upload->{commit}, 'storage was asked to commit');
    is($upload->{aborted}, 1, 'bad descriptor aborts upload');
};

subtest 'receive_blob rejects inconsistent upload results' => sub {
    my $storage = Local::Storage->new(bad_created => 1);
    my $server = Net::Blossom::Server->new(storage => $storage);

    like(dies {
        $server->receive_blob('body');
    }, qr/created must be 0 or 1/, 'bad created flag rejected');

    my ($upload) = $storage->uploads;
    ok($upload->{commit}, 'storage was asked to commit');
    is($upload->{aborted}, 1, 'bad result aborts upload');
};

subtest 'receive_blob validates arguments' => sub {
    my $server = Net::Blossom::Server->new(storage => Local::Storage->new);

    like(dies { $server->receive_blob(undef) },
        qr/body is required/, 'body required');
    like(dies { $server->receive_blob({}) },
        qr/body must be a scalar or stream object/, 'bad body rejected');
    like(dies { $server->receive_blob('body', type => []) },
        qr/type must be a scalar/, 'type scalar required');
    like(dies { $server->receive_blob('body', expected_sha256 => 'A' x 64) },
        qr/expected_sha256 must be 64-char lowercase hex/, 'uppercase expected sha rejected');
    like(dies { $server->receive_blob('body', allowed_sha256 => '0' x 64) },
        qr/allowed_sha256 must be an array reference/, 'allowed hashes arrayref required');
    like(dies { $server->receive_blob('body', allowed_sha256 => ['A' x 64]) },
        qr/allowed_sha256 must contain 64-char lowercase hex values/, 'allowed hashes validated');
    like(dies { $server->receive_blob('body', sha256_mismatch_status => 'bad') },
        qr/sha256_mismatch_status must be an HTTP status code/, 'mismatch status validated');
    like(dies { $server->receive_blob('body', sha256_mismatch_reason => []) },
        qr/sha256_mismatch_reason must be a scalar/, 'mismatch reason scalar required');
    like(dies { $server->receive_blob('body', pubkey => []) },
        qr/pubkey must be a scalar/, 'pubkey scalar required');
    like(dies { $server->receive_blob('body', pubkey => 'A' x 64) },
        qr/pubkey must be 64-char lowercase hex/, 'uppercase pubkey rejected');
    like(dies { $server->receive_blob('body', content_length => -1) },
        qr/content_length must be a non-negative integer/, 'bad content length rejected');
    like(dies { $server->receive_blob('body', content_length_mismatch_status => 'bad') },
        qr/content_length_mismatch_status must be an HTTP status code/, 'content length mismatch status validated');
    like(dies { $server->receive_blob('body', content_length_mismatch_reason => []) },
        qr/content_length_mismatch_reason must be a scalar/, 'content length mismatch reason scalar required');
};

done_testing;
