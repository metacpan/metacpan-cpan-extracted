use strictures 2;

use Test::More;

use Net::Blossom::Server::Storage::Test qw(run_storage_contract_tests);

sub dies(&) {
    my ($code) = @_;
    my $ok = eval { $code->(); 1 };
    return $ok ? undef : $@;
}

{
    package Local::ContractStorage;
    use strictures 2;

    use Net::Blossom::BlobDescriptor;
    use Net::Blossom::Server::BlobResult;

    sub new {
        my ($class) = @_;
        return bless {
            blobs  => {},
            owners => {},
        }, $class;
    }

    sub begin_upload {
        my ($self, %context) = @_;
        return Local::ContractUpload->new($self, \%context);
    }

    sub get_blob {
        my ($self, $sha256) = @_;
        my $entry = $self->{blobs}{$sha256};
        return unless defined $entry;
        return Net::Blossom::Server::BlobResult->new(
            descriptor => $entry->{descriptor},
            body       => $entry->{body},
        );
    }

    sub head_blob {
        my ($self, $sha256) = @_;
        return unless exists $self->{blobs}{$sha256};
        return $self->{blobs}{$sha256}{descriptor};
    }

    sub delete_blob {
        my ($self, $sha256, %opts) = @_;
        return 0 unless exists $self->{blobs}{$sha256};

        if (defined $opts{pubkey}) {
            return 0 unless exists $self->{owners}{$opts{pubkey}}
                && $self->{owners}{$opts{pubkey}}{$sha256};
            delete $self->{owners}{$opts{pubkey}}{$sha256};
        }
        else {
            for my $pubkey (keys %{$self->{owners}}) {
                delete $self->{owners}{$pubkey}{$sha256};
            }
        }

        my $owned = 0;
        for my $pubkey (keys %{$self->{owners}}) {
            $owned ||= exists $self->{owners}{$pubkey}{$sha256};
        }
        delete $self->{blobs}{$sha256} unless $owned;

        return 1;
    }

    sub list_blobs {
        my ($self, $pubkey, %opts) = @_;
        my @sha256 = keys %{$self->{owners}{$pubkey} || {}};
        my @blobs = sort {
            $b->uploaded <=> $a->uploaded || $a->sha256 cmp $b->sha256
        } grep { defined } map { $self->{blobs}{$_}{descriptor} } @sha256;

        if (defined $opts{cursor}) {
            while (@blobs && $blobs[0]->sha256 ne $opts{cursor}) {
                shift @blobs;
            }
            shift @blobs if @blobs;
        }

        splice @blobs, $opts{limit} if defined $opts{limit} && @blobs > $opts{limit};
        return \@blobs;
    }
}

{
    package Local::StreamingContractStorage;
    use strictures 2;

    our @ISA = qw(Local::ContractStorage);

    use Net::Blossom::Server::BlobResult;

    sub get_blob {
        my ($self, $sha256) = @_;
        my $entry = $self->{blobs}{$sha256};
        return unless defined $entry;
        return Net::Blossom::Server::BlobResult->new(
            descriptor => $entry->{descriptor},
            body       => Local::ReadStream->new($entry->{body}),
        );
    }
}

{
    package Local::ReadStream;
    use strictures 2;

    sub new {
        my ($class, $body) = @_;
        return bless { body => $body, offset => 0 }, $class;
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
    package Local::ContractUpload;
    use strictures 2;

    use Net::Blossom::BlobDescriptor;

    sub new {
        my ($class, $storage, $context) = @_;
        return bless {
            storage => $storage,
            context => $context,
            chunks  => [],
            aborted => 0,
        }, $class;
    }

    sub write {
        my ($self, $chunk) = @_;
        push @{$self->{chunks}}, $chunk;
        return length $chunk;
    }

    sub commit {
        my ($self, %metadata) = @_;
        my $body = join '', @{$self->{chunks}};
        my $created = exists $self->{storage}{blobs}{$metadata{sha256}} ? 0 : 1;
        my $descriptor = Net::Blossom::BlobDescriptor->new(
            url      => "https://cdn.example.com/$metadata{sha256}.bin",
            sha256   => $metadata{sha256},
            size     => $metadata{size},
            type     => $metadata{type},
            uploaded => $metadata{uploaded},
        );

        $self->{storage}{blobs}{$metadata{sha256}} = {
            descriptor => $descriptor,
            body       => $body,
        };
        $self->{storage}{owners}{$metadata{pubkey}}{$metadata{sha256}} = 1
            if defined $metadata{pubkey};

        return {
            descriptor => $descriptor,
            created    => $created,
        };
    }

    sub abort {
        my ($self) = @_;
        $self->{aborted}++;
        return 1;
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

run_storage_contract_tests(
    name    => 'in-memory contract storage',
    factory => sub { Local::ContractStorage->new },
);

run_storage_contract_tests(
    name    => 'streaming body contract storage',
    factory => sub { Local::StreamingContractStorage->new },
);

done_testing;
