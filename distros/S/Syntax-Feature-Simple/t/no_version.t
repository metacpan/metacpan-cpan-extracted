use strictures 1;
use Test::More 0.98;
use Test::Fatal 0.003;

do {
    package MyTest::NoVersion;
    use syntax ();
    ::like(
        ::exception { syntax->import(qw( simple )) },
        qr/need\s+to\s+select\s+a\s+specific\s+version/i,
        'missing version throws error',
    );
};

done_testing;

