use Test2::V0;

use Nanoid;

subtest 'generates custom settings' => sub {
    is length +Nanoid::generate( size => 5 ), 5, 'size';
    like +Nanoid::generate( size => 5, alphabet => 'abcdefg' ),
        qr/[abcdefg]+/,
        'size and alphabet';
};

subtest 'generates URL friendly ID' => sub {
    my $id = Nanoid::generate();

    is length $id, 21;
    like $id, qr/[a-zA-Z0-9\-\_]+/;
};

subtest 'no collisions' => sub {
    my %generated = ();
    my $count     = 100_000;

    for ( 0 .. $count ) {
        my $id = Nanoid::generate();

        if ( defined $generated{$id} ) {
            fail('has collisions');
        }

        $generated{$id} = 1;
    }
    pass('has no collisions for million entries as 21 characters length');
};

subtest 'invalid alphabets' => sub {
    like dies {
        Nanoid::generate( size => 10, alphabet => 'a' x 256 );
    }, qr/alphabet must not empty and contain no more than 255 chars/;
};

subtest 'invalid size parameter' => sub {
    like dies {
        Nanoid::generate( size => 0, alphabet => 'a' x 256 );
    }, qr/size must be greater than zero/;
};

done_testing;
