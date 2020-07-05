use Test::Most;
use Test::Deep qw/true false/;
use Test::OpenTracing::Integration;
use OpenTracing::Implementation qw/Test/;

use OpenTracing::WrapScope qw/root child/;


sub root {
    global_tracer_cmp_easy(
        [{ operation_name => 'main::root', has_finished => false }],
        'root span started');

    child();

    global_tracer_cmp_easy(
        [
            { operation_name => 'main::root',  has_finished => false },
            { operation_name => 'main::child', has_finished => true },
        ],
        'child span finished, root span still running'
    );
}

sub child {
    global_tracer_cmp_easy(
        [
            { operation_name => 'main::root',  has_finished => false },
            { operation_name => 'main::child', has_finished => false },
        ],
        'child span started, root span still running'
    );
}

root();

global_tracer_cmp_easy(
    [
        { operation_name => 'main::root',  has_finished => true },
        { operation_name => 'main::child', has_finished => true },
    ],
    'all spans finished'
);

done_testing();
