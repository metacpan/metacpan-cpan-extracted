use strict;
use warnings;

use Test::More;
use RDF::Flow qw(:all rdflow_uri);
use Scalar::Util qw(blessed);

# utility methods
#my $time = qr/^\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d(Z|[+-]\d\d:\d\d)$/;
my $time = qr/\d{4}/;
my $env = { HTTP_HOST => "example.com", SCRIPT_NAME => '/y', };

my $uri = rdflow_uri( $env );
is( $uri, 'http://example.com/y', 'rdflow_uri' );
ok(! blessed $uri, 'plain string' );

my $src1 = sub { };
my $src2 = rdflow $src1;
my $src3 = rdflow $src2;
# is( $src2, $src3, 'rdflow does not copy source objects' );

like( $src2->timestamp, $time, 'timestamp' );
$env = { };
$src2->timestamp($env);
like( $env->{'rdflow.timestamp'}, $time, 'timestamp' );

done_testing;
