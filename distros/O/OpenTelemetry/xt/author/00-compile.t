use 5.006;
use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.058

use Test::More;

plan tests => 36;

my @module_files = (
    'OpenTelemetry.pm',
    'OpenTelemetry/Attributes.pm',
    'OpenTelemetry/Baggage.pm',
    'OpenTelemetry/Common.pm',
    'OpenTelemetry/Constants.pm',
    'OpenTelemetry/Context.pm',
    'OpenTelemetry/Exporter.pm',
    'OpenTelemetry/Integration.pm',
    'OpenTelemetry/Integration/DBI.pm',
    'OpenTelemetry/Integration/HTTP/Tiny.pm',
    'OpenTelemetry/Integration/LWP/UserAgent.pm',
    'OpenTelemetry/Integration/namespace.pm',
    'OpenTelemetry/Propagator.pm',
    'OpenTelemetry/Propagator/Baggage.pm',
    'OpenTelemetry/Propagator/Composite.pm',
    'OpenTelemetry/Propagator/None.pm',
    'OpenTelemetry/Propagator/TextMap.pm',
    'OpenTelemetry/Propagator/TraceContext.pm',
    'OpenTelemetry/Propagator/TraceContext/TraceFlags.pm',
    'OpenTelemetry/Propagator/TraceContext/TraceParent.pm',
    'OpenTelemetry/Propagator/TraceContext/TraceState.pm',
    'OpenTelemetry/Trace.pm',
    'OpenTelemetry/Trace/Event.pm',
    'OpenTelemetry/Trace/Link.pm',
    'OpenTelemetry/Trace/Span.pm',
    'OpenTelemetry/Trace/Span/Processor.pm',
    'OpenTelemetry/Trace/Span/Status.pm',
    'OpenTelemetry/Trace/SpanContext.pm',
    'OpenTelemetry/Trace/Tracer.pm',
    'OpenTelemetry/Trace/TracerProvider.pm',
    'OpenTelemetry/X.pm',
    'OpenTelemetry/X/Invalid.pm',
    'OpenTelemetry/X/Parsing.pm',
    'OpenTelemetry/X/Unsupported.pm',
    'Test2/Tools/OpenTelemetry.pm'
);



# no fake home requested

my @switches = (
    -d 'blib' ? '-Mblib' : '-Ilib',
);

use File::Spec;
use IPC::Open3;
use IO::Handle;

open my $stdin, '<', File::Spec->devnull or die "can't open devnull: $!";

my @warnings;
for my $lib (@module_files)
{
    # see L<perlfaq8/How can I capture STDERR from an external command?>
    my $stderr = IO::Handle->new;

    diag('Running: ', join(', ', map { my $str = $_; $str =~ s/'/\\'/g; q{'} . $str . q{'} }
            $^X, @switches, '-e', "require q[$lib]"))
        if $ENV{PERL_COMPILE_TEST_DEBUG};

    my $pid = open3($stdin, '>&STDERR', $stderr, $^X, @switches, '-e', "require q[$lib]");
    binmode $stderr, ':crlf' if $^O eq 'MSWin32';
    my @_warnings = <$stderr>;
    waitpid($pid, 0);
    is($?, 0, "$lib loaded ok");

    shift @_warnings if @_warnings and $_warnings[0] =~ /^Using .*\bblib/
        and not eval { +require blib; blib->VERSION('1.01') };

    if (@_warnings)
    {
        warn @_warnings;
        push @warnings, @_warnings;
    }
}



is(scalar(@warnings), 0, 'no warnings found')
    or diag 'got warnings: ', ( Test::More->can('explain') ? Test::More::explain(\@warnings) : join("\n", '', @warnings) );


