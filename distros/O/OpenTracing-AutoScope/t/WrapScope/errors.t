use List::Util qw/first/;
use Test::Most tests => 3;
use Test::OpenTracing::Integration;
use OpenTracing::GlobalTracer;
use OpenTracing::Implementation qw/Test/;

use OpenTracing::WrapScope qw/success error/;

my $error = 'not good';
my $re_error = qr/$error/;

sub success { }

sub error { die $error }

success();
throws_ok { error() } $re_error, 'error reported outside';

global_tracer_cmp_easy(
    [
        { operation_name => 'main::success' },
        { operation_name => 'main::error', tags => superhashof({ error => re($re_error) }) },
    ],
    'error saved into a tag'
);

my $success_span =
  first { $_->{operation_name} eq 'success' } $TRACER->get_spans_as_struct();
ok !exists $success_span->{tags}{error}, 'no error tag if no error';
