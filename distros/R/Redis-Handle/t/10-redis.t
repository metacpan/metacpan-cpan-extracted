#!/usr/bin/env perl

use Test::More tests => 11;

BEGIN { use_ok 'Redis::Handle' }

SKIP: {
    my $redis;
    eval { require Redis; $redis = Redis->new };
    skip "Redis not installed locally.", 10 if $@ || not defined $redis;

    my $tied = tie *CLIENT, 'Redis::Handle', randWord(16);
    isa_ok($tied,'Redis::Handle',"Create the handle.");

    my @words = map {randWord(8)} (0..8);

    ok((print {*CLIENT} join " ", @words), "Write one line.");

    is(<CLIENT>,(join " ", @words),"Read one line.");

    ok((print {*CLIENT} @words),"Write multiple lines.");

    is_deeply([<CLIENT>],\@words,"Read multiple lines.");

    my $tied2 = tie *CLIENT2, 'Redis::Handle', randWord(16), $redis;

    isa_ok($tied2,'Redis::Handle',"Use existing handle.");

    ok((print {*CLIENT2} join " ", @words), "Write one line.");

    is(<CLIENT2>,(join " ", @words),"Read one line.");

    ok((print {*CLIENT2} @words),"Write multiple lines.");

    is_deeply([<CLIENT2>],\@words,"Read multiple lines.");
}

sub randWord {
    my @alpha = ('a'..'z','A'..'Z','0'..'9');
    join "", map {$alpha[rand(@alpha)]} (0..$_[0]);
}
