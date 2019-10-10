use 5.006;
use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.058

use Test::More;

plan tests => 18;

my @module_files = (
    'OpenERP/OOM.pm',
    'OpenERP/OOM/Class.pm',
    'OpenERP/OOM/Class/Base.pm',
    'OpenERP/OOM/DynamicUtils.pm',
    'OpenERP/OOM/Link.pm',
    'OpenERP/OOM/Link/DBIC.pm',
    'OpenERP/OOM/Link/Provider.pm',
    'OpenERP/OOM/Meta/Class/Trait/HasLink.pm',
    'OpenERP/OOM/Meta/Class/Trait/HasRelationship.pm',
    'OpenERP/OOM/Object.pm',
    'OpenERP/OOM/Object/Base.pm',
    'OpenERP/OOM/Roles/Attribute.pm',
    'OpenERP/OOM/Roles/Class.pm',
    'OpenERP/OOM/Schema.pm',
    'OpenERP/OOM/Tutorial.pm',
    'OpenERP/OOM/Tutorial/Schema.pm',
    'OpenERP/OOM/Tutorial/Searching.pm'
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


