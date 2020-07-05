use Test::Most tests => 1;
use Test::OpenTracing::Integration;
use OpenTracing::Implementation qw/Test/;


sub pre {  }

use OpenTracing::WrapScope qw[ pre post ];

sub post {  }

pre();
post();

global_tracer_cmp_easy(
    [ { operation_name => 'main::pre' }, { operation_name => 'main::post' } ],
    'subs defined before and after "use OpenTracing::WrapScope"'
);
