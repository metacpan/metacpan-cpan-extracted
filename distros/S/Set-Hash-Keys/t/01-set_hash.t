use Test::Most;

use Set::Hash::Keys;

subtest 'Set Hash' => sub {
    plan tests => 2;
    
    my $set_h;
    lives_ok {
        $set_h = set_hash(
            bar => 1,
            buz => 2,
        );
    }
    "Can create an object in the short version of set_hash";
    cmp_deeply(
        { %$set_h } => {
            bar => 1,
            buz => 2,
        },
        "... and contains the correct data"
    );
    
};

done_testing();
