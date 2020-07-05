use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/OpenTracing.pm',
    'lib/OpenTracing/Any.pm',
    'lib/OpenTracing/Batch.pm',
    'lib/OpenTracing/Batch.pod',
    'lib/OpenTracing/Common.pm',
    'lib/OpenTracing/DSL.pm',
    'lib/OpenTracing/Integration.pm',
    'lib/OpenTracing/Integration/HTTP/Tiny.pm',
    'lib/OpenTracing/Log.pm',
    'lib/OpenTracing/Log.pod',
    'lib/OpenTracing/Process.pm',
    'lib/OpenTracing/Process.pod',
    'lib/OpenTracing/Protocol.pm',
    'lib/OpenTracing/Protocol/Jaeger.pm',
    'lib/OpenTracing/Protocol/Zipkin.pm',
    'lib/OpenTracing/Span.pm',
    'lib/OpenTracing/SpanContext.pm',
    'lib/OpenTracing/SpanContext.pod',
    'lib/OpenTracing/SpanProxy.pm',
    'lib/OpenTracing/SpanProxy.pod',
    'lib/OpenTracing/Tag.pm',
    'lib/OpenTracing/Tag.pod',
    'lib/OpenTracing/Tracer.pm',
    't/00-check-deps.t',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/any.t',
    't/dsl.t',
    't/span.t',
    't/tracer.t',
    'xt/author/eol.t',
    'xt/author/minimum-version.t',
    'xt/author/mojibake.t',
    'xt/author/no-tabs.t',
    'xt/author/pod-syntax.t',
    'xt/author/portability.t',
    'xt/author/test-version.t',
    'xt/release/common_spelling.t',
    'xt/release/cpan-changes.t',
    'xt/release/distmeta.t'
);

notabs_ok($_) foreach @files;
done_testing;
