use 5.006;
use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.058

use Test::More;

plan tests => 45 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

my @module_files = (
    'Sah/Schema/byte.pm',
    'Sah/Schema/even.pm',
    'Sah/Schema/int128.pm',
    'Sah/Schema/int16.pm',
    'Sah/Schema/int32.pm',
    'Sah/Schema/int64.pm',
    'Sah/Schema/int8.pm',
    'Sah/Schema/natnum.pm',
    'Sah/Schema/negeven.pm',
    'Sah/Schema/negint.pm',
    'Sah/Schema/negodd.pm',
    'Sah/Schema/nonnegint.pm',
    'Sah/Schema/odd.pm',
    'Sah/Schema/poseven.pm',
    'Sah/Schema/posint.pm',
    'Sah/Schema/posodd.pm',
    'Sah/Schema/uint.pm',
    'Sah/Schema/uint128.pm',
    'Sah/Schema/uint16.pm',
    'Sah/Schema/uint32.pm',
    'Sah/Schema/uint64.pm',
    'Sah/Schema/uint8.pm',
    'Sah/SchemaR/byte.pm',
    'Sah/SchemaR/even.pm',
    'Sah/SchemaR/int128.pm',
    'Sah/SchemaR/int16.pm',
    'Sah/SchemaR/int32.pm',
    'Sah/SchemaR/int64.pm',
    'Sah/SchemaR/int8.pm',
    'Sah/SchemaR/natnum.pm',
    'Sah/SchemaR/negeven.pm',
    'Sah/SchemaR/negint.pm',
    'Sah/SchemaR/negodd.pm',
    'Sah/SchemaR/nonnegint.pm',
    'Sah/SchemaR/odd.pm',
    'Sah/SchemaR/poseven.pm',
    'Sah/SchemaR/posint.pm',
    'Sah/SchemaR/posodd.pm',
    'Sah/SchemaR/uint.pm',
    'Sah/SchemaR/uint128.pm',
    'Sah/SchemaR/uint16.pm',
    'Sah/SchemaR/uint32.pm',
    'Sah/SchemaR/uint64.pm',
    'Sah/SchemaR/uint8.pm',
    'Sah/Schemas/Int.pm'
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
    or diag 'got warnings: ', ( Test::More->can('explain') ? Test::More::explain(\@warnings) : join("\n", '', @warnings) ) if $ENV{AUTHOR_TESTING};


