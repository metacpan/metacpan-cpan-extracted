use strict;
use warnings;
use Test::Tester tests => 5;
use Test::More;
use Test::Deep;
use Test::Deep::JWT;

subtest 'compare claims only' => sub {
    cmp_deeply 'eyJhbGciOiJub25lIn0.eyJzdWIiOiIxMDAiLCJhdWQiOiIxMjMifQ.', jwt(+{
        sub => '100',
        aud => '123',
    });
};

subtest 'compare claims with Test::Deep function' => sub {
    cmp_deeply 'eyJhbGciOiJub25lIn0.eyJzdWIiOiIxMDAiLCJhdWQiOiIxMjMifQ.', jwt(+{
        sub => '100',
        aud => ignore,
    });

    cmp_deeply 'eyJhbGciOiJub25lIn0.eyJzdWIiOiIxMDAiLCJhdWQiOiIxMjMifQ.', jwt(
        superhashof(+{
            sub => '100',
        })
    );
};

subtest 'compare claims and header' => sub {
    cmp_deeply 'eyJhbGciOiJub25lIn0.eyJzdWIiOiIxMDAiLCJhdWQiOiIxMjMifQ.', jwt(+{
        sub => '100',
        aud => '123',
    }, +{
        alg => 'none',
    });
};

subtest 'missing aud' => sub {
    check_test sub {
        cmp_deeply 'eyJhbGciOiJub25lIn0.eyJzdWIiOiIxMDAiLCJhdWQiOiIxMjMifQ.', jwt(+{
            sub => '100',
        });
    }, +{
        ok => 0,
    };
};

subtest 'invalid jwt' => sub {
    check_test sub {
        cmp_deeply 'eyJzdWIiOiIxMDAiLCJhdWQiOiIxMjMifQ.', jwt(+{
            sub => '100',
            aud => '123',
        });
    }, +{
        ok => 0,
    };
};
