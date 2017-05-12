use strict;
use warnings;
use utf8;
use Test::More;
use Encode qw/encode_utf8/;

use Sub::Data::Recursive;

{
    my $hash = +{
        bar => +{
            baz => '焼肉'
        },
        qux => '寿司',
    };

    Sub::Data::Recursive->invoke(
        sub { $_[0] = encode_utf8($_[0]) },
        $hash,
    );

    my $expect = +{
        bar => +{
            baz => encode_utf8('焼肉'),
        },
        qux => encode_utf8('寿司'),
    };

    is_deeply $hash, $expect;
}

done_testing;
