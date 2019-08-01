use 5.006;
use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.058

use Test::More;

plan tests => 23 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

my @module_files = (
    'Sah/Schema/dns/record.pm',
    'Sah/Schema/dns/record/a.pm',
    'Sah/Schema/dns/record/cname.pm',
    'Sah/Schema/dns/record/mx.pm',
    'Sah/Schema/dns/record/ns.pm',
    'Sah/Schema/dns/record/soa.pm',
    'Sah/Schema/dns/record/txt.pm',
    'Sah/Schema/dns/record_of_known_types.pm',
    'Sah/Schema/dns/records.pm',
    'Sah/Schema/dns/records_of_known_types.pm',
    'Sah/Schema/dns/zone.pm',
    'Sah/SchemaR/dns/record.pm',
    'Sah/SchemaR/dns/record/a.pm',
    'Sah/SchemaR/dns/record/cname.pm',
    'Sah/SchemaR/dns/record/mx.pm',
    'Sah/SchemaR/dns/record/ns.pm',
    'Sah/SchemaR/dns/record/soa.pm',
    'Sah/SchemaR/dns/record/txt.pm',
    'Sah/SchemaR/dns/record_of_known_types.pm',
    'Sah/SchemaR/dns/records.pm',
    'Sah/SchemaR/dns/records_of_known_types.pm',
    'Sah/SchemaR/dns/zone.pm',
    'Sah/Schemas/DNS.pm'
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


