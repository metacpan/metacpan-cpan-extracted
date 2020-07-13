use Test::Most tests => 2;
use Test::OpenTracing::Integration;
use OpenTracing::Implementation qw/Test/;
use FindBin;

BEGIN {
    $ENV{OPENTRACING_WRAPSCOPE_FILE} = join ':',
      "$FindBin::Bin/samples/wrapscope1.txt",
      "$FindBin::Bin/samples/sample3.txt";
}
use OpenTracing::WrapScope -env, 'Sample1::baz';

use lib "$FindBin::Bin/samples/lib";
use Samples;

Samples::run();

global_tracer_cmp_deeply([
    map { superhashof($_) }
    { operation_name => 'Sample1::foo' },
    { operation_name => 'Sample1::bar' },
    { operation_name => 'Sample1::baz' },
    { operation_name => 'Sample3::foo' },
    { operation_name => 'Sample3::bar' },
], 'files from env var and a separate sub');


$ENV{OPENTRACING_WRAPSCOPE_FILE} = "$FindBin::Bin/samples/wrapscope2.txt";
eval 'use OpenTracing::WrapScope -env; 1' or die $@;
Sample2::foo();
Sample2::bar();
global_tracer_cmp_easy([
    { operation_name => 'Sample2::foo' },
    { operation_name => 'Sample2::bar' },
], 'env var as the sole input');
