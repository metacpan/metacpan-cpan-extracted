use Test::Most tests => 1;
use Test::OpenTracing::Integration;
use OpenTracing::Implementation qw/Test/;
use FindBin;

use OpenTracing::WrapScope qw[ Samples::run Sample1::foo Sample2::foo ];

use lib "$FindBin::Bin/samples/lib";

require Samples;
Samples::run();    # has calls to Sample1::foo and Sample2::foo

TODO: {
    local $TODO = 'not implemented yet';

    global_tracer_cmp_easy([
        { operation_name => 'Samples::run' },
        { operation_name => 'Sample1::foo' },
        { operation_name => 'Sample2::foo' },
    ], 'subs from a runtime-loaded module are wrapped');
}
