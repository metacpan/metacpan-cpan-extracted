use Test::Most tests => 1;
use Test::OpenTracing::Integration;
use OpenTracing::Implementation qw/Test/;
use OpenTracing::WrapScope qw/Sample1::foo/;
use FindBin;
use lib "$FindBin::Bin/samples/lib";
use Samples;

Sample1::foo();

global_tracer_cmp_easy(
    [{ operation_name => 'Sample1::foo' }],
    'sub from a module wrapped correctly'
);
