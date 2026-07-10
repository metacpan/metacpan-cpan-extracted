use strictures 2;

use Test::More;

use Net::Blossom::URI;

sub dies(&) {
    my ($code) = @_;
    my $ok = eval { $code->(); 1 };
    return $ok ? undef : $@;
}

my $HASH = 'b1674191a88ec5cdd733e4240a81803105dc412d6c6708d53ab94fc248f4f553';
my $PUBKEY1 = 'ec4425ff5e9446080d2f70440188e3ca5d6da8713db7bdeef73d0ed54d9093f0';
my $PUBKEY2 = '781208004e09102d7da3b7345e64fd193cd1bc3fce8fdae6008d77f9cabcd036';

subtest 'BUD-10 minimal URI parses hash and extension' => sub {
    my $uri = Net::Blossom::URI->parse("blossom:$HASH.pdf");
    is($uri->sha256, $HASH, 'sha256');
    is($uri->extension, 'pdf', 'extension');
};

subtest 'BUD-10 unknown file type uses bin extension when creating URIs' => sub {
    my $uri = Net::Blossom::URI->new(sha256 => $HASH);
    is($uri->to_string, "blossom:$HASH.bin", 'default bin extension');
};

subtest 'BUD-10 parses server, author, and size hints' => sub {
    my $uri = Net::Blossom::URI->parse(
        "blossom:$HASH.pdf?xs=cdn.satellite.earth&xs=blossom.primal.net&as=$PUBKEY1&as=$PUBKEY2&sz=184292"
    );

    is_deeply($uri->xs, ['cdn.satellite.earth', 'blossom.primal.net'], 'xs repeats');
    is_deeply($uri->as, [$PUBKEY1, $PUBKEY2], 'as repeats');
    is($uri->sz, 184292, 'size');
};

subtest 'BUD-10 rejects malformed required components' => sub {
    like(dies { Net::Blossom::URI->parse("blossom:$HASH") },
        qr/extension is required/, 'extension required');
    like(dies { Net::Blossom::URI->parse('blossom:' . ('A' x 64) . '.pdf') },
        qr/lowercase hex/, 'lowercase sha required');
    like(dies { Net::Blossom::URI->parse("blossom:$HASH.pdf?as=" . ('A' x 64)) },
        qr/author.*lowercase hex/, 'lowercase author required');
    like(dies { Net::Blossom::URI->parse("blossom:$HASH.pdf?sz=0") },
        qr/size.*positive integer/, 'positive size required');
};

done_testing;
