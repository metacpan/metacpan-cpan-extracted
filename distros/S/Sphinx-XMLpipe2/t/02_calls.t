use strict;
use Test::More tests => 10;

my $m;

BEGIN {
    use_ok( $m = 'Sphinx::XMLpipe2' );
}

ok(!$m->new(), 'reject empty args for new() is ok');

my $sxml;
eval {
    $sxml = $m->new(
        fields => [qw(author title content)],
        attrs  => {published => 'timestamp',}
    );
};

ok($sxml, 'new object is ok');

my $add;
eval {
    $add = {
        id         => 314159265,
        author     => 'Oscar Wilde',
        title      => 'Illusion is the first of all pleasures',
        content    => 'Man is least himself when he talks in his own person. Give him a mask, and he will tell you the truth.',
        published  => 1234567890,
    };
};

ok(!$sxml->add_data(), 'reject add_data method with bad args is ok');
ok($sxml->add_data($add), 'add_data method is ok');
ok(!$sxml->remove_data(), 'reject remove_data method with bad args is ok');
ok($sxml->remove_data({id => 27182818}), 'remove_data method is ok');
ok($sxml->fetch(), 'fetch method is ok');

eval {
    $sxml = $m->new(
        fields => [qw(author title content)],
        attrs  => [
            {
                name => 'published',
                type => 'timestamp',
            },
            {
                name    => 'section',
                type    => 'int',
                bits    => 8,
                default => 1,
            },
        ]
    );
};

ok($sxml, 'new object with attrs_array is ok');

eval {
    $sxml = $m->new(
        fields => [qw(author title content)],
    );
};

ok($sxml, 'new object with fields_only is ok');

done_testing();
