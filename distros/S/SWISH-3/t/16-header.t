use Test::More tests => 5;
use strict;

use SWISH::3 qw(:constants);

my $header = SWISH_HEADER_FILE();
unlink("t/$header");

ok( my $s3    = SWISH::3->new,          "new s3" );
ok( my $index = $s3->config->get_index, "get_index" );
ok( $index->set( 'Format', 'Test' ), "set Format" );
ok( $s3->config->write("t/$header"), 'write header' );
cmp_ok( -s "t/$header", '>', 792, "size of header file" );
