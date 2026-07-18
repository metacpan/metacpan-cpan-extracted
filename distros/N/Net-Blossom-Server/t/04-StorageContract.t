use strictures 2;

use Digest::SHA qw(sha256_hex);
use Scalar::Util qw(refaddr);
use Test::More;

use Net::Blossom::Server;
use Net::Blossom::Server::BlobStore;
use Net::Blossom::Server::MetadataStore;
use Net::Blossom::Server::Storage::Test qw(run_storage_contract_tests);

my $PUBKEY = '79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798';
my $OTHER_PUBKEY = '266815e0c9210dfa324c6cba3573b14bee49da4209a9456f9484e5106cd408a5';

sub dies(&) {
    my ($code) = @_;
    my $ok = eval { $code->(); 1 };
    return $ok ? undef : $@;
}

{
    package Local::MetadataStore;
    use strictures 2;

    use Carp qw(croak);
    use Class::Tiny qw(blobs owners events in_transaction fail_next_owner), {
        blobs          => sub { {} },
        owners         => sub { {} },
        events         => sub { [] },
        in_transaction => 0,
    };

    sub BUILD {
        my ($self) = @_;
        $self->blobs;
        $self->owners;
        $self->events;
        $self->in_transaction;
        return;
    }

    sub deploy_schema {
        return 1;
    }

    sub with_transaction {
        my ($self, $callback) = @_;
        croak "transaction callback must be a code reference"
            unless ref($callback) eq 'CODE';
        croak "nested transaction is not supported" if $self->{in_transaction};

        my $blobs = _clone_records($self->{blobs});
        my $owners = {
            map {
                my $pubkey = $_;
                $pubkey => _clone_records($self->{owners}{$pubkey});
            } keys %{$self->{owners}}
        };

        $self->_event('metadata.transaction.begin');
        $self->{in_transaction} = 1;
        my $result;
        my $ok = eval {
            $result = $callback->();
            1;
        };
        my $error = $@;
        $self->{in_transaction} = 0;

        if (!$ok) {
            $self->{blobs} = $blobs;
            $self->{owners} = $owners;
            $self->_event('metadata.transaction.rollback');
            die $error;
        }

        $self->_event('metadata.transaction.commit');
        return $result;
    }

    sub lock_blob {
        my ($self, $sha256) = @_;
        $self->_assert_transaction;
        $self->_event('metadata.lock_blob');
        return 1;
    }

    sub find_blob {
        my ($self, $sha256) = @_;
        $self->_event('metadata.find_blob');
        return unless exists $self->{blobs}{$sha256};
        return {%{$self->{blobs}{$sha256}}};
    }

    sub insert_blob {
        my ($self, %record) = @_;
        $self->_assert_transaction;
        $self->_event('metadata.insert_blob');
        return 0 if exists $self->{blobs}{$record{sha256}};
        $self->{blobs}{$record{sha256}} = {
            map { $_ => $record{$_} }
                qw(sha256 storage_key size type uploaded)
        };
        return 1;
    }

    sub upsert_owner {
        my ($self, %owner) = @_;
        $self->_assert_transaction;
        $self->_event('metadata.upsert_owner');
        if (defined $self->{fail_next_owner}) {
            my $error = $self->{fail_next_owner};
            $self->{fail_next_owner} = undef;
            die "$error\n";
        }
        $self->{owners}{$owner{pubkey}}{$owner{sha256}} = {
            type     => $owner{type},
            uploaded => $owner{uploaded},
        };
        return 1;
    }

    sub delete_owner {
        my ($self, $sha256, $pubkey) = @_;
        $self->_assert_transaction;
        $self->_event('metadata.delete_owner');
        return 0 unless exists $self->{owners}{$pubkey}
            && exists $self->{owners}{$pubkey}{$sha256};
        delete $self->{owners}{$pubkey}{$sha256};
        delete $self->{owners}{$pubkey} unless keys %{$self->{owners}{$pubkey}};
        return 1;
    }

    sub delete_owners {
        my ($self, $sha256) = @_;
        $self->_assert_transaction;
        $self->_event('metadata.delete_owners');
        for my $pubkey (keys %{$self->{owners}}) {
            delete $self->{owners}{$pubkey}{$sha256};
            delete $self->{owners}{$pubkey} unless keys %{$self->{owners}{$pubkey}};
        }
        return 1;
    }

    sub owner_count {
        my ($self, $sha256) = @_;
        my $count = 0;
        for my $pubkey (keys %{$self->{owners}}) {
            $count++ if exists $self->{owners}{$pubkey}{$sha256};
        }
        return $count;
    }

    sub delete_blob {
        my ($self, $sha256) = @_;
        $self->_assert_transaction;
        $self->_event('metadata.delete_blob');
        return delete $self->{blobs}{$sha256} ? 1 : 0;
    }

    sub list_blobs {
        my ($self, $pubkey, %opts) = @_;
        my @rows = map {
            my $sha256 = $_;
            +{
                %{$self->{blobs}{$sha256}},
                %{$self->{owners}{$pubkey}{$sha256}},
            };
        } grep {
            exists $self->{blobs}{$_}
        } keys %{$self->{owners}{$pubkey} || {}};

        @rows = sort {
            $b->{uploaded} <=> $a->{uploaded}
                || $a->{sha256} cmp $b->{sha256}
        } @rows;

        if (defined $opts{cursor}) {
            while (@rows && $rows[0]{sha256} ne $opts{cursor}) {
                shift @rows;
            }
            shift @rows if @rows;
        }

        splice @rows, $opts{limit}
            if defined $opts{limit} && @rows > $opts{limit};
        return \@rows;
    }

    sub _assert_transaction {
        my ($self) = @_;
        croak "metadata transaction is required" unless $self->{in_transaction};
        return;
    }

    sub _event {
        my ($self, $event) = @_;
        push @{$self->{events}}, $event;
        return;
    }

    sub _clone_records {
        my ($records) = @_;
        return {map { $_ => {%{$records->{$_}}} } keys %$records};
    }
}

{
    package Local::BlobStore;
    use strictures 2;

    use Carp qw(croak);
    use Class::Tiny qw(blobs events streaming), {
        blobs     => sub { {} },
        events    => sub { [] },
        streaming => 0,
    };

    sub BUILD {
        my ($self) = @_;
        $self->blobs;
        $self->events;
        $self->streaming;
        return;
    }

    sub deploy_schema {
        return 1;
    }

    sub begin_upload {
        my ($self, %context) = @_;
        $self->_event('blob.begin_upload');
        return Local::BlobUpload->new(store => $self);
    }

    sub get_blob {
        my ($self, $storage_key) = @_;
        return unless exists $self->{blobs}{$storage_key};
        return $self->{streaming}
            ? Local::ReadStream->new(body => $self->{blobs}{$storage_key})
            : $self->{blobs}{$storage_key};
    }

    sub get_blob_range {
        my ($self, $storage_key, %opts) = @_;
        return unless exists $self->{blobs}{$storage_key};
        return substr($self->{blobs}{$storage_key}, $opts{offset}, $opts{length});
    }

    sub delete_blob {
        my ($self, $storage_key) = @_;
        $self->_event('blob.delete_blob');
        return 0 unless exists $self->{blobs}{$storage_key};
        delete $self->{blobs}{$storage_key};
        return 1;
    }

    sub _prepare {
        my ($self, $body, %metadata) = @_;
        $self->_event('blob.prepare');
        my $storage_key = $metadata{sha256};
        if (exists $self->{blobs}{$storage_key}) {
            croak "stored bytes do not match upload"
                unless $self->{blobs}{$storage_key} eq $body;
            return ($storage_key, 0);
        }
        $self->{blobs}{$storage_key} = $body;
        return ($storage_key, 1);
    }

    sub _commit {
        my ($self) = @_;
        $self->_event('blob.commit');
        return 1;
    }

    sub _abort {
        my ($self, $storage_key, $body, $created) = @_;
        $self->_event('blob.abort');
        delete $self->{blobs}{$storage_key}
            if $created
            && exists $self->{blobs}{$storage_key}
            && $self->{blobs}{$storage_key} eq $body;
        return 1;
    }

    sub _event {
        my ($self, $event) = @_;
        push @{$self->{events}}, $event;
        return;
    }
}

{
    package Local::BlobUpload;
    use strictures 2;

    use Carp qw(croak);
    use Class::Tiny qw(store prepared_key prepared_body), {
        chunks   => sub { [] },
        created  => 0,
        committed => 0,
        aborted   => 0,
    };

    sub BUILD {
        my ($self) = @_;
        $self->chunks;
        $self->created;
        $self->committed;
        $self->aborted;
        return;
    }

    sub write {
        my ($self, $chunk) = @_;
        croak "blob upload is already prepared" if defined $self->{prepared_key};
        croak "blob upload is already committed" if $self->{committed};
        croak "blob upload is aborted" if $self->{aborted};
        push @{$self->{chunks}}, $chunk;
        return length $chunk;
    }

    sub prepare {
        my ($self, %metadata) = @_;
        croak "blob upload is already prepared" if defined $self->{prepared_key};
        croak "blob upload is already committed" if $self->{committed};
        croak "blob upload is aborted" if $self->{aborted};
        my $body = join '', @{$self->{chunks}};
        my ($storage_key, $created) = $self->{store}->_prepare($body, %metadata);
        $self->{prepared_key} = $storage_key;
        $self->{prepared_body} = $body;
        $self->{created} = $created;
        return $storage_key;
    }

    sub commit {
        my ($self) = @_;
        croak "blob upload must be prepared before commit"
            unless defined $self->{prepared_key};
        croak "blob upload is aborted" if $self->{aborted};
        return 1 if $self->{committed};
        $self->{store}->_commit;
        $self->{committed} = 1;
        return 1;
    }

    sub abort {
        my ($self) = @_;
        return 1 if $self->{aborted} || $self->{committed};
        $self->{store}->_abort(
            $self->{prepared_key},
            $self->{prepared_body},
            $self->{created},
        ) if defined $self->{prepared_key};
        $self->{aborted} = 1;
        return 1;
    }

    sub DEMOLISH {
        my ($self) = @_;
        eval { $self->abort } unless $self->{aborted} || $self->{committed};
        return;
    }
}

{
    package Local::ReadStream;
    use strictures 2;

    use Class::Tiny qw(body), {offset => 0};

    sub BUILD {
        my ($self) = @_;
        $self->offset;
        return;
    }

    sub read {
        my ($self, undef, $length) = @_;
        return 0 if $self->{offset} >= length $self->{body};
        $_[1] = substr($self->{body}, $self->{offset}, $length);
        $self->{offset} += length $_[1];
        return length $_[1];
    }
}

{
    package Local::ContractStorage;
    use strictures 2;

    use Class::Tiny qw(metadata_store blob_store), {
        base_url => 'https://cdn.example.com',
    };
    use Net::Blossom::BlobDescriptor;
    use Net::Blossom::Server::BlobResult;
    use Net::Blossom::Server::BlobStore;
    use Net::Blossom::Server::MetadataStore;

    sub BUILD {
        my ($self) = @_;
        Net::Blossom::Server::MetadataStore->assert_implements($self->metadata_store);
        Net::Blossom::Server::BlobStore->assert_implements($self->blob_store);
        $self->base_url;
        return;
    }

    sub deploy_schema {
        my ($self) = @_;
        $self->blob_store->deploy_schema;
        $self->metadata_store->deploy_schema;
        return 1;
    }

    sub begin_upload {
        my ($self, %context) = @_;
        my $blob_upload = $self->blob_store->begin_upload(%context);
        Net::Blossom::Server::BlobStore->assert_upload($blob_upload);
        return Local::ContractUpload->new(
            storage     => $self,
            blob_upload => $blob_upload,
        );
    }

    sub get_blob {
        my ($self, $sha256) = @_;
        my $record = $self->metadata_store->find_blob($sha256);
        return unless defined $record;
        my $body = $self->blob_store->get_blob($record->{storage_key});
        return unless defined $body;
        return Net::Blossom::Server::BlobResult->new(
            descriptor => $self->_descriptor($record),
            body       => $body,
        );
    }

    sub get_blob_range {
        my ($self, $sha256, %opts) = @_;
        my $record = $self->metadata_store->find_blob($sha256);
        return unless defined $record;
        return $self->blob_store->get_blob_range(
            $record->{storage_key},
            %opts,
            size => $record->{size},
        );
    }

    sub head_blob {
        my ($self, $sha256) = @_;
        my $record = $self->metadata_store->find_blob($sha256);
        return unless defined $record;
        return $self->_descriptor($record);
    }

    sub delete_blob {
        my ($self, $sha256, %opts) = @_;
        my $metadata = $self->metadata_store;
        my $storage_key;
        my $deleted = $metadata->with_transaction(sub {
            $metadata->lock_blob($sha256);

            if (defined $opts{pubkey}) {
                return 0 unless $metadata->delete_owner($sha256, $opts{pubkey});
                if (!$metadata->owner_count($sha256)) {
                    my $record = $metadata->find_blob($sha256);
                    if (defined $record) {
                        $storage_key = $record->{storage_key};
                        $metadata->delete_blob($sha256);
                    }
                }
                return 1;
            }

            my $record = $metadata->find_blob($sha256);
            return 0 unless defined $record;
            $storage_key = $record->{storage_key};
            $metadata->delete_owners($sha256);
            $metadata->delete_blob($sha256);
            return 1;
        });

        $self->blob_store->delete_blob($storage_key) if defined $storage_key;
        return $deleted ? 1 : 0;
    }

    sub list_blobs {
        my ($self, $pubkey, %opts) = @_;
        my $records = $self->metadata_store->list_blobs($pubkey, %opts);
        return [map { $self->_descriptor($_) } @$records];
    }

    sub _commit_upload {
        my ($self, $upload, %metadata) = @_;
        my $store = $self->metadata_store;
        my $created;

        my $ok = eval {
            $store->with_transaction(sub {
                $store->lock_blob($metadata{sha256});
                my $record = $store->find_blob($metadata{sha256});

                if (defined $record) {
                    $created = 0;
                }
                else {
                    my $storage_key = $upload->_prepare(%metadata);
                    $created = $store->insert_blob(
                        %metadata,
                        storage_key => $storage_key,
                    ) ? 1 : 0;
                }

                $store->upsert_owner(%metadata) if defined $metadata{pubkey};
                return 1;
            });
            1;
        };
        my $error = $@;

        if (!$ok) {
            eval { $upload->_cleanup(0) };
            die $error;
        }

        $upload->_cleanup($created);
        return {
            descriptor => $self->_descriptor(\%metadata),
            created    => $created,
        };
    }

    sub _descriptor {
        my ($self, $record) = @_;
        return Net::Blossom::BlobDescriptor->new(
            url      => $self->base_url . '/' . $record->{sha256},
            sha256   => $record->{sha256},
            size     => 0 + $record->{size},
            type     => $record->{type},
            uploaded => 0 + $record->{uploaded},
        );
    }
}

{
    package Local::ContractUpload;
    use strictures 2;

    use Carp qw(croak);
    use Class::Tiny qw(storage blob_upload), {
        committed => 0,
        aborted   => 0,
    };

    sub BUILD {
        my ($self) = @_;
        $self->committed;
        $self->aborted;
        return;
    }

    sub write {
        my ($self, $chunk) = @_;
        croak "upload is already committed" if $self->{committed};
        croak "upload is aborted" if $self->{aborted};
        return $self->{blob_upload}->write($chunk);
    }

    sub commit {
        my ($self, %metadata) = @_;
        croak "upload is already committed" if $self->{committed};
        croak "upload is aborted" if $self->{aborted};
        my $result = $self->{storage}->_commit_upload($self, %metadata);
        $self->{committed} = 1;
        return $result;
    }

    sub abort {
        my ($self) = @_;
        return 1 if $self->{aborted} || $self->{committed};
        $self->{aborted} = 1;
        return $self->{blob_upload}->abort;
    }

    sub _prepare {
        my ($self, %metadata) = @_;
        return $self->{blob_upload}->prepare(%metadata);
    }

    sub _cleanup {
        my ($self, $created) = @_;
        return $created
            ? $self->{blob_upload}->commit
            : $self->{blob_upload}->abort;
    }

    sub DEMOLISH {
        my ($self) = @_;
        eval { $self->abort } unless $self->{committed} || $self->{aborted};
        return;
    }
}

subtest 'run_storage_contract_tests validates arguments' => sub {
    like(dies { run_storage_contract_tests() },
        qr/name is required/, 'name required');
    like(dies { run_storage_contract_tests(name => 'storage') },
        qr/factory must be a code reference/, 'factory required');
    like(dies { run_storage_contract_tests(name => 'storage', factory => sub { Local::ContractStorage->new }, bogus => 1) },
        qr/unknown argument\(s\): bogus/, 'unknown argument rejected');
};

subtest 'in-memory contract storage uses split components' => sub {
    my ($storage, $metadata, $blobs) = _new_split_storage();
    isa_ok($metadata, 'Local::MetadataStore');
    isa_ok($blobs, 'Local::BlobStore');
    isnt(refaddr($metadata), refaddr($blobs), 'metadata and blob stores are distinct objects');
    ok(Net::Blossom::Server::MetadataStore->assert_implements($metadata),
        'metadata component implements its contract');
    ok(Net::Blossom::Server::BlobStore->assert_implements($blobs),
        'blob component implements its contract');
    is($storage->metadata_store, $metadata, 'coordinator exposes metadata component');
    is($storage->blob_store, $blobs, 'coordinator exposes blob component');
};

subtest 'metadata and blob bytes stay separated' => sub {
    my ($storage, $metadata, $blobs) = _new_split_storage();
    my $body = "split storage body\n";
    my $result = Net::Blossom::Server->new(storage => $storage)->receive_blob(
        $body,
        type     => 'text/plain',
        uploaded => 1725105921,
        pubkey   => $PUBKEY,
    );
    my $record = $metadata->find_blob($result->descriptor->sha256);

    is_deeply(
        [sort keys %$record],
        [qw(sha256 size storage_key type uploaded)],
        'metadata record contains identifiers and descriptor fields only',
    );
    is($blobs->get_blob($record->{storage_key}), $body,
        'blob store contains the bytes under the opaque storage key');
};

subtest 'blob component reports deletion of an empty body' => sub {
    my (undef, undef, $blobs) = _new_split_storage();
    my $upload = $blobs->begin_upload;
    is($upload->write(''), 0, 'empty body is accepted');
    my $storage_key = $upload->prepare(
        sha256   => sha256_hex(''),
        size     => 0,
        type     => 'application/octet-stream',
        uploaded => 1725105921,
    );
    $upload->commit;

    is($blobs->get_blob($storage_key), '', 'empty body is stored');
    ok($blobs->delete_blob($storage_key), 'deleting empty bytes reports success');
    is($blobs->get_blob($storage_key), undef, 'empty bytes are removed');
};

subtest 'split upload follows the component lifecycle' => sub {
    my @events;
    my ($storage) = _new_split_storage(events => \@events);
    Net::Blossom::Server->new(storage => $storage)->receive_blob(
        "ordered lifecycle\n",
        uploaded => 1725105921,
        pubkey   => $PUBKEY,
    );

    is_deeply(
        \@events,
        [qw(
            blob.begin_upload
            metadata.transaction.begin
            metadata.lock_blob
            metadata.find_blob
            blob.prepare
            metadata.insert_blob
            metadata.upsert_owner
            metadata.transaction.commit
            blob.commit
        )],
        'bytes are prepared inside the metadata transaction and finalized after commit',
    );
};

subtest 'metadata rollback aborts newly prepared bytes' => sub {
    my ($storage, $metadata, $blobs) = _new_split_storage();
    my $body = "rolled back body\n";
    my $sha256 = sha256_hex($body);
    $metadata->fail_next_owner('owner write failed');

    like(
        dies {
            Net::Blossom::Server->new(storage => $storage)->receive_blob(
                $body,
                uploaded => 1725105921,
                pubkey   => $PUBKEY,
            );
        },
        qr/owner write failed/,
        'metadata failure is reported',
    );
    is($metadata->find_blob($sha256), undef, 'rolled-back metadata is absent');
    is($blobs->get_blob($sha256), undef, 'newly prepared bytes are aborted');
};

subtest 'failed upload over existing bytes preserves them' => sub {
    my ($storage, $metadata, $blobs) = _new_split_storage();
    my $body = "existing body\n";
    my $sha256 = sha256_hex($body);
    my $existing = $blobs->begin_upload;
    $existing->write($body);
    my $storage_key = $existing->prepare(
        sha256   => $sha256,
        size     => length($body),
        type     => 'application/octet-stream',
        uploaded => 1725105921,
    );
    $existing->commit;
    $metadata->fail_next_owner('duplicate owner write failed');

    like(
        dies {
            Net::Blossom::Server->new(storage => $storage)->receive_blob(
                $body,
                uploaded => 1725105922,
                pubkey   => $OTHER_PUBKEY,
            );
        },
        qr/duplicate owner write failed/,
        'duplicate metadata failure is reported',
    );
    is($blobs->get_blob($storage_key), $body, 'aborting a duplicate keeps existing bytes');
    is($metadata->find_blob($sha256), undef, 'failed upload leaves no metadata');
    is($metadata->owner_count($sha256), 0, 'failed upload leaves no owner');
};

subtest 'final owner deletion removes both component records' => sub {
    my ($storage, $metadata, $blobs) = _new_split_storage();
    my $server = Net::Blossom::Server->new(storage => $storage);
    my $body = "shared split body\n";
    my $first = $server->receive_blob(
        $body,
        uploaded => 1725105921,
        pubkey   => $PUBKEY,
    );
    $server->receive_blob(
        $body,
        uploaded => 1725105922,
        pubkey   => $OTHER_PUBKEY,
    );
    my $sha256 = $first->descriptor->sha256;
    my $storage_key = $metadata->find_blob($sha256)->{storage_key};

    ok($storage->delete_blob($sha256, pubkey => $PUBKEY), 'first owner is deleted');
    is($metadata->owner_count($sha256), 1, 'one owner remains');
    ok(defined $metadata->find_blob($sha256), 'shared metadata remains');
    is($blobs->get_blob($storage_key), $body, 'shared bytes remain');

    ok($storage->delete_blob($sha256, pubkey => $OTHER_PUBKEY), 'final owner is deleted');
    is($metadata->find_blob($sha256), undef, 'final metadata record is removed');
    is($blobs->get_blob($storage_key), undef, 'final blob bytes are removed');
};

run_storage_contract_tests(
    name    => 'in-memory contract storage',
    factory => sub {
        my ($storage) = _new_split_storage();
        return $storage;
    },
);

run_storage_contract_tests(
    name    => 'streaming body contract storage',
    factory => sub {
        my ($storage) = _new_split_storage(streaming => 1);
        return $storage;
    },
);

done_testing;

sub _new_split_storage {
    my %args = @_;
    my $events = $args{events} || [];
    my $metadata = Local::MetadataStore->new(events => $events);
    my $blobs = Local::BlobStore->new(
        events    => $events,
        streaming => $args{streaming} || 0,
    );
    my $storage = Local::ContractStorage->new(
        metadata_store => $metadata,
        blob_store     => $blobs,
    );
    return ($storage, $metadata, $blobs);
}
