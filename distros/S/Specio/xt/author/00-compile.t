use 5.006;
use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.057

use Test::More;

plan tests => 41;

my @module_files = (
    'Specio.pm',
    'Specio/Coercion.pm',
    'Specio/Constraint/AnyCan.pm',
    'Specio/Constraint/AnyDoes.pm',
    'Specio/Constraint/AnyIsa.pm',
    'Specio/Constraint/Enum.pm',
    'Specio/Constraint/Intersection.pm',
    'Specio/Constraint/ObjectCan.pm',
    'Specio/Constraint/ObjectDoes.pm',
    'Specio/Constraint/ObjectIsa.pm',
    'Specio/Constraint/Parameterizable.pm',
    'Specio/Constraint/Parameterized.pm',
    'Specio/Constraint/Role/CanType.pm',
    'Specio/Constraint/Role/DoesType.pm',
    'Specio/Constraint/Role/Interface.pm',
    'Specio/Constraint/Role/IsaType.pm',
    'Specio/Constraint/Simple.pm',
    'Specio/Constraint/Structurable.pm',
    'Specio/Constraint/Structured.pm',
    'Specio/Constraint/Union.pm',
    'Specio/Declare.pm',
    'Specio/DeclaredAt.pm',
    'Specio/Exception.pm',
    'Specio/Exporter.pm',
    'Specio/Helpers.pm',
    'Specio/Library/Builtins.pm',
    'Specio/Library/Numeric.pm',
    'Specio/Library/Perl.pm',
    'Specio/Library/String.pm',
    'Specio/Library/Structured.pm',
    'Specio/Library/Structured/Dict.pm',
    'Specio/Library/Structured/Map.pm',
    'Specio/Library/Structured/Tuple.pm',
    'Specio/OO.pm',
    'Specio/PartialDump.pm',
    'Specio/Registry.pm',
    'Specio/Role/Inlinable.pm',
    'Specio/Subs.pm',
    'Specio/TypeChecks.pm',
    'Test/Specio.pm'
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


