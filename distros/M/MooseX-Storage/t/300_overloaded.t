use strict;
use warnings;
use Test::More 0.88;
use Test::Fatal;

use Test::Requires 'JSON::MaybeXS';
diag 'using JSON backend: ', JSON;

{
    package Thing;
    use Moose;
    use MooseX::Storage;

    use overload
        q{""}    => 'as_string',
        fallback => 1;

    with Storage('format' => 'JSON');

    has foo => ( is => 'ro' );

    sub as_string { shift->freeze }

    no Moose;
}

my $i = Thing->new(foo => "bar");

is( exception {
    $i . "";
}, undef, 'Can stringify without deep recursion');

done_testing;
