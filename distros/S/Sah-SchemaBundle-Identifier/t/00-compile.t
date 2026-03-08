use 5.006;
use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.058

use Test::More;

plan tests => 41 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

my @module_files = (
    'Sah/Schema/identifier.pm',
    'Sah/Schema/identifier/lc.pm',
    'Sah/Schema/identifier/lc127.pm',
    'Sah/Schema/identifier/lc15.pm',
    'Sah/Schema/identifier/lc255.pm',
    'Sah/Schema/identifier/lc31.pm',
    'Sah/Schema/identifier/lc63.pm',
    'Sah/Schema/identifier/no_u.pm',
    'Sah/Schema/identifier/no_u_delim.pm',
    'Sah/Schema/identifier/uc.pm',
    'Sah/Schema/identifier/uc127.pm',
    'Sah/Schema/identifier/uc15.pm',
    'Sah/Schema/identifier/uc255.pm',
    'Sah/Schema/identifier/uc31.pm',
    'Sah/Schema/identifier/uc63.pm',
    'Sah/Schema/identifier127.pm',
    'Sah/Schema/identifier15.pm',
    'Sah/Schema/identifier255.pm',
    'Sah/Schema/identifier31.pm',
    'Sah/Schema/identifier63.pm',
    'Sah/SchemaBundle/Identifier.pm',
    'Sah/SchemaR/identifier.pm',
    'Sah/SchemaR/identifier/lc.pm',
    'Sah/SchemaR/identifier/lc127.pm',
    'Sah/SchemaR/identifier/lc15.pm',
    'Sah/SchemaR/identifier/lc255.pm',
    'Sah/SchemaR/identifier/lc31.pm',
    'Sah/SchemaR/identifier/lc63.pm',
    'Sah/SchemaR/identifier/no_u.pm',
    'Sah/SchemaR/identifier/no_u_delim.pm',
    'Sah/SchemaR/identifier/uc.pm',
    'Sah/SchemaR/identifier/uc127.pm',
    'Sah/SchemaR/identifier/uc15.pm',
    'Sah/SchemaR/identifier/uc255.pm',
    'Sah/SchemaR/identifier/uc31.pm',
    'Sah/SchemaR/identifier/uc63.pm',
    'Sah/SchemaR/identifier127.pm',
    'Sah/SchemaR/identifier15.pm',
    'Sah/SchemaR/identifier255.pm',
    'Sah/SchemaR/identifier31.pm',
    'Sah/SchemaR/identifier63.pm'
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


