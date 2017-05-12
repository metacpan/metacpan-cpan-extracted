use Test::More tests => 12;

use_ok('SWISH::3');

ok( my $s3 = SWISH::3->new, "new s3" );
is( $s3->refcount,           1, "refcnt = 1" );
is( $s3->analyzer->refcount, 1, "analyzer refcount == 1" );
ok( my $analyzer = $s3->analyzer, "get analyzer" );
is( $analyzer->refcount, 1, "analyzer refcount == 1" );

#undef $s3;
is( $analyzer->refcount, 1, "analyzer refcount == 1" );
my $a2 = $analyzer;
is( $a2->refcount,       2, "a2 copy == 2" );
is( $analyzer->refcount, 2, "analyzer refcount == 2" );

#$s3->dump($analyzer);
is( $s3->config->refcount, 1, "config refcount == 1" );

is( $s3->refcount, 1, "s3 refcount == 1" );
is( $s3->ref_cnt,  1, "s3 ref_cnt (c_ptr) == 1" );
