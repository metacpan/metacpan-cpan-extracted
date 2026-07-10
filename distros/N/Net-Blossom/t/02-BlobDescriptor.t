use strictures 2;

use Test::More;

use Net::Blossom::BlobDescriptor;

sub dies(&) {
    my ($code) = @_;
    my $ok = eval { $code->(); 1 };
    return $ok ? undef : $@;
}

my $HASH = 'b1674191a88ec5cdd733e4240a81803105dc412d6c6708d53ab94fc248f4f553';

sub nip94_tags {
    return [
        ['url', "https://cdn.example.com/$HASH.pdf"],
        ['m', 'application/pdf'],
        ['x', $HASH],
        ['size', '184292'],
    ];
}

subtest 'BUD-02 blob descriptor example parses' => sub {
    my $descriptor = Net::Blossom::BlobDescriptor->from_hash({
        url      => "https://cdn.example.com/$HASH.pdf",
        sha256   => $HASH,
        size     => 184292,
        type     => 'application/pdf',
        uploaded => 1725105921,
    });

    isa_ok($descriptor, 'Net::Blossom::BlobDescriptor');
    is($descriptor->url, "https://cdn.example.com/$HASH.pdf", 'url');
    is($descriptor->sha256, $HASH, 'sha256');
    is($descriptor->size, 184292, 'size');
    is($descriptor->type, 'application/pdf', 'type');
    is($descriptor->uploaded, 1725105921, 'uploaded');
};

subtest 'extra descriptor fields are preserved' => sub {
    my $descriptor = Net::Blossom::BlobDescriptor->from_hash({
        url      => "https://cdn.example.com/$HASH.pdf",
        sha256   => $HASH,
        size     => 184292,
        type     => 'application/pdf',
        uploaded => 1725105921,
        ipfs     => 'bafyexample',
        magnet   => 'magnet:?xt=urn:btih:abc',
    });

    is($descriptor->get('ipfs'), 'bafyexample', 'extra field accessor');
    is($descriptor->get('magnet'), 'magnet:?xt=urn:btih:abc', 'second extra field accessor');

    my $hash = $descriptor->to_hash;
    is($hash->{ipfs}, 'bafyexample', 'to_hash preserves extra field');
    is($hash->{magnet}, 'magnet:?xt=urn:btih:abc', 'to_hash preserves second extra field');
};

subtest 'extra descriptor fields cannot shadow standard fields' => sub {
    like(dies {
        Net::Blossom::BlobDescriptor->new(
            url      => "https://cdn.example.com/$HASH.pdf",
            sha256   => $HASH,
            size     => 184292,
            type     => 'application/pdf',
            uploaded => 1725105921,
            extra    => { url => 'https://bad.example/blob' },
        );
    }, qr/extra must not contain standard descriptor field url/, 'standard extra key rejected');
};

subtest 'nip94 descriptor field is exposed and preserved' => sub {
    my $descriptor = Net::Blossom::BlobDescriptor->from_hash({
        url      => "https://cdn.example.com/$HASH.pdf",
        sha256   => $HASH,
        size     => 184292,
        type     => 'application/pdf',
        uploaded => 1725105921,
        nip94    => nip94_tags(),
    });

    is_deeply($descriptor->nip94, nip94_tags(), 'nip94 accessor');
    is_deeply($descriptor->get('nip94'), nip94_tags(), 'generic accessor');
    is_deeply($descriptor->to_hash->{nip94}, nip94_tags(), 'to_hash preserves nip94');
    ok(!exists $descriptor->extra->{nip94}, 'nip94 is not stored as an extra field');
};

subtest 'required fields are validated' => sub {
    for my $field (qw(url sha256 size type uploaded)) {
        my %data = (
            url      => "https://cdn.example.com/$HASH.pdf",
            sha256   => $HASH,
            size     => 184292,
            type     => 'application/pdf',
            uploaded => 1725105921,
        );
        delete $data{$field};
        like(dies { Net::Blossom::BlobDescriptor->from_hash(\%data) },
            qr/$field is required/, "$field required");
    }
};

subtest 'field formats are validated' => sub {
    like(dies {
        Net::Blossom::BlobDescriptor->from_hash({
            url => "https://cdn.example.com/$HASH.pdf", sha256 => 'A' x 64,
            size => 1, type => 'application/pdf', uploaded => 1,
        });
    }, qr/sha256.*lowercase hex/, 'uppercase sha rejected');

    like(dies {
        Net::Blossom::BlobDescriptor->from_hash({
            url => "https://cdn.example.com/$HASH.pdf", sha256 => $HASH,
            size => -1, type => 'application/pdf', uploaded => 1,
        });
    }, qr/size.*non-negative integer/, 'negative size rejected');

    like(dies {
        Net::Blossom::BlobDescriptor->from_hash({
            url => "https://cdn.example.com/$HASH.pdf", sha256 => $HASH,
            size => 1, type => 'application/pdf', uploaded => 'abc',
        });
    }, qr/uploaded.*non-negative integer/, 'bad uploaded rejected');

    like(dies {
        Net::Blossom::BlobDescriptor->from_hash({
            url => "https://cdn.example.com/$HASH.pdf", sha256 => $HASH,
            size => 1, type => 'application/pdf', uploaded => 1,
            nip94 => {},
        });
    }, qr/nip94 must be an array reference/, 'bad nip94 rejected');

    like(dies {
        Net::Blossom::BlobDescriptor->from_hash({
            url => [], sha256 => $HASH,
            size => 1, type => 'application/pdf', uploaded => 1,
        });
    }, qr/url must be a scalar/, 'url reference rejected');

    like(dies {
        Net::Blossom::BlobDescriptor->from_hash({
            url => "https://cdn.example.com/$HASH.pdf", sha256 => $HASH,
            size => 1, type => {}, uploaded => 1,
        });
    }, qr/type must be a scalar/, 'type reference rejected');
};

done_testing;
