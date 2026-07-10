use strictures 2;

use Test::More;

use Net::Blossom::_ConstructorArgs ();
use Net::Blossom::BlobDescriptor;
use Net::Blossom::Client;

sub dies(&) {
    my ($code) = @_;
    my $ok = eval { $code->(); 1 };
    return $ok ? undef : $@;
}

subtest 'normalizer accepts flat hashes and hash references' => sub {
    is_deeply({ Net::Blossom::_ConstructorArgs::normalize(foo => 1) }, { foo => 1 }, 'flat hash');
    is_deeply({ Net::Blossom::_ConstructorArgs::normalize({ foo => 1 }) }, { foo => 1 }, 'hash reference');
    is_deeply({ Net::Blossom::_ConstructorArgs::normalize() }, {}, 'empty argument list');
    like(dies { Net::Blossom::_ConstructorArgs::normalize('foo') },
        qr/hash or hash reference/, 'odd flat list rejected');
};

subtest 'representative constructors accept hash references' => sub {
    my $descriptor = Net::Blossom::BlobDescriptor->new({
        url      => 'https://cdn.example.com/' . ('a' x 64) . '.txt',
        sha256   => 'a' x 64,
        size     => 5,
        type     => 'text/plain',
        uploaded => 1725105921,
    });
    isa_ok($descriptor, 'Net::Blossom::BlobDescriptor');

    my $client = Net::Blossom::Client->new({ server => 'https://cdn.example.com' });
    isa_ok($client, 'Net::Blossom::Client');
};

subtest 'constructors reject unknown arguments' => sub {
    like(dies { Net::Blossom::Client->new(server => 'https://cdn.example.com', bogus => 1) },
        qr/unknown argument.+bogus/, 'client rejects unknown argument');
};

done_testing;
