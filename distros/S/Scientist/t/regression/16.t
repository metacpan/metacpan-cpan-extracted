use Test2::V0 -target => 'Scientist';

ok(
    dies { $CLASS->new(use => sub { die } )->run },
    'die in use() should propagate'
);

ok(
    lives { $CLASS->new( use => sub {}, try => sub { die } )->run },
    'die in try() should be caught'
);

done_testing;
