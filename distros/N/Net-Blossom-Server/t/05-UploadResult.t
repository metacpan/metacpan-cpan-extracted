use strictures 2;

use Test::More;

use Net::Blossom::BlobDescriptor;
use Net::Blossom::Server::UploadResult;

sub dies(&) {
    my ($code) = @_;
    my $ok = eval { $code->(); 1 };
    return $ok ? undef : $@;
}

my $HASH = 'b1674191a88ec5cdd733e4240a81803105dc412d6c6708d53ab94fc248f4f553';

sub descriptor {
    return Net::Blossom::BlobDescriptor->new(
        url      => "https://cdn.example.com/$HASH.bin",
        sha256   => $HASH,
        size     => 12,
        type     => 'application/octet-stream',
        uploaded => 1725105921,
    );
}

subtest 'constructs upload results' => sub {
    my $descriptor = descriptor();
    my $result = Net::Blossom::Server::UploadResult->new(
        descriptor => $descriptor,
        created    => 1,
    );

    isa_ok($result, 'Net::Blossom::Server::UploadResult');
    is($result->descriptor, $descriptor, 'descriptor');
    is($result->created, 1, 'created flag');

    my $existing = Net::Blossom::Server::UploadResult->new(
        descriptor => $descriptor,
        created    => 0,
    );
    is($existing->created, 0, 'existing flag');
};

subtest 'validates upload result inputs' => sub {
    like(dies { Net::Blossom::Server::UploadResult->new(created => 1) },
        qr/descriptor is required/, 'descriptor required');
    like(dies { Net::Blossom::Server::UploadResult->new(descriptor => {}, created => 1) },
        qr/descriptor must be a Net::Blossom::BlobDescriptor/, 'descriptor class required');
    like(dies { Net::Blossom::Server::UploadResult->new(descriptor => descriptor()) },
        qr/created is required/, 'created required');
    like(dies { Net::Blossom::Server::UploadResult->new(descriptor => descriptor(), created => []) },
        qr/created must be a scalar/, 'created scalar required');
    like(dies { Net::Blossom::Server::UploadResult->new(descriptor => descriptor(), created => 2) },
        qr/created must be 0 or 1/, 'created boolean required');
    like(dies { Net::Blossom::Server::UploadResult->new(descriptor => descriptor(), created => 1, bogus => 1) },
        qr/unknown argument\(s\): bogus/, 'unknown argument rejected');
};

done_testing;
