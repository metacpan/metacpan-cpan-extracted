use Test::Most tests => 1;
use Test::OpenTracing::Integration;
use OpenTracing::Implementation qw/Test/;
use OpenTracing::WrapScope;

sub foo { }

'x' =~ /(.)/;
OpenTracing::WrapScope::install_wrapped('foo');
foo();

global_tracer_cmp_easy([{ operation_name => 'main::foo' }]);
