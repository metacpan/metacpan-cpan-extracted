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

subtest 'parse minimal blossom URI' => sub {
    my $uri = Net::Blossom::URI->parse("blossom:$HASH.pdf");

    isa_ok($uri, 'Net::Blossom::URI');
    is($uri->sha256, $HASH, 'sha256');
    is($uri->extension, 'pdf', 'extension');
    is_deeply($uri->xs, [], 'no server hints');
    is_deeply($uri->as, [], 'no author hints');
    is($uri->sz, undef, 'no size');
    is($uri->to_string, "blossom:$HASH.pdf", 'round trip minimal URI');
};

subtest 'parse repeated discovery hints' => sub {
    my $uri = Net::Blossom::URI->parse(
        "blossom:$HASH.pdf?xs=cdn.satellite.earth&as=$PUBKEY1&xs=https://blossom.primal.net&as=$PUBKEY2&sz=184292"
    );

    is_deeply($uri->xs, ['cdn.satellite.earth', 'https://blossom.primal.net'], 'server hints preserve order');
    is_deeply($uri->as, [$PUBKEY1, $PUBKEY2], 'author hints preserve order');
    is($uri->sz, 184292, 'size');
};

subtest 'build canonical blossom URI' => sub {
    my $uri = Net::Blossom::URI->new(
        sha256    => $HASH,
        extension => '.png',
        xs        => ['cdn.satellite.earth', 'https://blossom.primal.net'],
        as        => [$PUBKEY1],
        sz        => 184292,
    );

    is(
        $uri->to_string,
        "blossom:$HASH.png?xs=cdn.satellite.earth&xs=https://blossom.primal.net&as=$PUBKEY1&sz=184292",
        'canonical query ordering',
    );
};

subtest 'build defaults unknown extension to bin' => sub {
    my $uri = Net::Blossom::URI->new(sha256 => $HASH);
    is($uri->extension, 'bin', 'default extension');
    is($uri->to_string, "blossom:$HASH.bin", 'default extension in URI');
};

subtest 'validates constructor inputs' => sub {
    like(dies { Net::Blossom::URI->new(extension => 'pdf') },
        qr/sha256 is required/, 'sha required');
    like(dies { Net::Blossom::URI->new(sha256 => 'A' x 64, extension => 'pdf') },
        qr/sha256.*lowercase hex/, 'uppercase sha rejected');
    like(dies { Net::Blossom::URI->new(sha256 => $HASH, extension => 'tar.gz') },
        qr/extension/, 'multi-dot extension rejected');
    like(dies { Net::Blossom::URI->new(sha256 => $HASH, xs => 'cdn.example.com') },
        qr/xs must be an array reference/, 'xs must be arrayref');
    like(dies { Net::Blossom::URI->new(sha256 => $HASH, xs => ['https://cdn.example.com/path']) },
        qr/server hint/, 'server path rejected');
    like(dies { Net::Blossom::URI->new(sha256 => $HASH, as => ['A' x 64]) },
        qr/author.*lowercase hex/, 'uppercase author rejected');
    like(dies { Net::Blossom::URI->new(sha256 => $HASH, sz => 0) },
        qr/size.*positive integer/, 'zero size rejected');
};

subtest 'validates parser inputs' => sub {
    like(dies { Net::Blossom::URI->parse("https://cdn.example.com/$HASH.pdf") },
        qr/blossom scheme/, 'wrong scheme rejected');
    like(dies { Net::Blossom::URI->parse("blossom:$HASH") },
        qr/extension is required/, 'missing extension rejected');
    like(dies { Net::Blossom::URI->parse('blossom:' . ('a' x 63) . '.pdf') },
        qr/sha256.*64-char/, 'short sha rejected');
    like(dies { Net::Blossom::URI->parse("blossom:$HASH.pdf?bad=value") },
        qr/unknown query parameter/, 'unknown query rejected');
    like(dies { Net::Blossom::URI->parse("blossom:$HASH.pdf?sz=1&sz=2") },
        qr/duplicate size/, 'duplicate size rejected');
    like(dies { Net::Blossom::URI->parse("blossom:$HASH.pdf?xs=%") },
        qr/invalid percent encoding/, 'bad percent encoding rejected');
};

done_testing;
