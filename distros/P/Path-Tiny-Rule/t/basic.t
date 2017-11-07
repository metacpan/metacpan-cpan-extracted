use strict;
use warnings;

use Test::More;

use Path::Tiny::Rule;

subtest(
    'iter',
    sub { _test_iter( Path::Tiny::Rule->new->name(qr/\.t$/)->iter('t') ) }
);
subtest(
    'iter_fast',
    sub {
        _test_iter( Path::Tiny::Rule->new->name(qr/\.t$/)->iter_fast('t') );
    }
);
subtest(
    'all',
    sub { _test_all( Path::Tiny::Rule->new->name(qr/\.t$/)->all('t') ) }
);
subtest(
    'all_fast',
    sub { _test_all( Path::Tiny::Rule->new->name(qr/\.t$/)->all_fast('t') ) }
);

done_testing();

sub _test_iter {
    my $iter = shift;

    my @found;
    while ( my $item = $iter->() ) {
        push @found, $item;
    }

    _test_all(@found);
}

sub _test_all {
    my @found = @_;

    cmp_ok( scalar @found, '>=', 1, 'found some test files' );
    is(
        scalar( grep { $_->isa('Path::Tiny') } @found ),
        scalar @found,
        'all items are returned as Path::Tiny object'
    );
}
