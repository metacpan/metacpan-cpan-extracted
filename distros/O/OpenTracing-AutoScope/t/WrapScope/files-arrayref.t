use Test::Most tests => 1;
use Test::OpenTracing::Integration;
use OpenTracing::Implementation qw/Test/;
use FindBin;

use OpenTracing::WrapScope -file => [
    "$FindBin::Bin/samples/wrapscope1.txt",
    "$FindBin::Bin/samples/sample3.txt",
];

use lib "$FindBin::Bin/samples/lib";
use Samples;

Samples::run();

global_tracer_cmp_deeply([
    map { superhashof($_) }
    { operation_name => 'Sample1::foo' },
    { operation_name => 'Sample1::bar' },
    { operation_name => 'Sample3::foo' },
    { operation_name => 'Sample3::bar' },
], 'multiple files specified');
