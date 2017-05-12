use Test::More tests => 6;

use_ok('SWISH::3');

ok( my $s3 = SWISH::3->new(), "new object" );

ok( my $buf = $s3->slurp("t/test.html"), "slurp file" );

ok( my $gzbuf = $s3->slurp("t/test-zipped.html.gz"), "slurp gz file");

is( $buf, $gzbuf, "gzipped buf eq buf");

eval {
    $buf = $s3->slurp('no/such/file');
};
ok($@, "croak on no stat");

#diag( $s3->dump );
#diag( $s3->refcount );

#diag($buf);

