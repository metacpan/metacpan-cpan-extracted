use strict;
use warnings;
use Test::More;
use Set::Product::XS qw(product);

ok defined &product, 'product() is exported';

{
    my @set = ();
    my @out; product { push @out, "@_" } @set;
    is_deeply \@out, [], 'empty list'
}

{
    my @set = ([1..3]);
    my @out; product { push @out, "@_" } @set;
    is_deeply \@out, [1..3], 'single list'
}

{
    my @set = map { [$_] } 1..5;
    my @out; product { push @out, "@_" } @set;
    is_deeply \@out, ['1 2 3 4 5'], 'all lists with single element';
}

{
    my @set = ([1,2], [3,4,5], []);
    my @out; product { push @out, "@_" } @set;
    is_deeply \@out, [], 'non-empty lists and an empty list'
}

{
    my @set = ([1,2], [3,4,5]);
    my @out; product { push @out, "@_" } @set;
    is_deeply \@out, ['1 3', '1 4', '1 5', '2 3', '2 4', '2 5'],
        'non-empty lists';
}

{
    my @set = (1, 2, 3);
    my @out; eval { product { push @out, "@_" } @set };
    like $@, qr/^Not an array reference/, 'bad list';
}

{
    my @set = ([1,2], [3,4,5]);
    my @out; eval { product { push @out, "@_"; $#_ = 0; } @set };
    is_deeply \@out, ['1 3', '1 4', '1 5', '2 3', '2 4', '2 5'],
        'decreased size of @_ inside block';
}

{
    my @set = ([1,2], [3,4,5]);
    my @out; eval { product { push @out, "@_"; push @_, ''; } @set };
    is_deeply \@out, ['1 3', '1 4', '1 5', '2 3', '2 4', '2 5'],
        'increased size of @_ inside block';
}

{
    my @set = ([1,2], [3,4,5]);
    my @out; eval { product { push @out, "@_"; @_ = (1..3); } @set };
    is_deeply \@out, ['1 3', '1 4', '1 5', '2 3', '2 4', '2 5'],
        'recreated @_ inside block';
}

{
    @_ = (1..3);
    product { } [4];
    is_deeply \@_, [1..3], 'restored @_'
}

done_testing;
