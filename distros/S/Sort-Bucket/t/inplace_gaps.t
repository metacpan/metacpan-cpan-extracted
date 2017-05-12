# Check that inplace_bucket_sort handles arrays with gaps and undef elts

use strict;
use warnings;
no warnings qw(uninitialized);

use Test::More;
use Sort::Bucket qw(inplace_bucket_sort);

{
    my @a = (undef, '', undef, '');
    my @b = sort @a;
    inplace_bucket_sort(@a);
    is_deeply \@a, \@b, "undef,'' same as sort()";
}

{
    my @a = (undef, '', "\0", undef, '', "\0");
    my @b = sort @a;
    inplace_bucket_sort(@a);
    is_deeply \@a, \@b, "undef,'',null same as sort()";
}

{
    my @a = qw(a b);
    delete $a[0];
    inplace_bucket_sort(@a);
    is_deeply \@a, [undef, 'b'], "1st elt missing";
}

{
    my @a = qw(a b c);
    delete $a[1];
    inplace_bucket_sort(@a);
    is_deeply \@a, [undef, 'a', 'c'], "middle elt missing";
}

{
    my @a;
    $a[100] = "foo";
    inplace_bucket_sort(@a);
    is_deeply \@a, [(undef)x100, 'foo'], "100 missing";
}

done_testing;

