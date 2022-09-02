use 5.006;
use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.058

use Test::More;

plan tests => 47 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

my @module_files = (
    'TableData/Business/ID/DGIP/Class.pm',
    'TableData/Business/ID/DGIP/Class/1.pm',
    'TableData/Business/ID/DGIP/Class/10.pm',
    'TableData/Business/ID/DGIP/Class/11.pm',
    'TableData/Business/ID/DGIP/Class/12.pm',
    'TableData/Business/ID/DGIP/Class/13.pm',
    'TableData/Business/ID/DGIP/Class/14.pm',
    'TableData/Business/ID/DGIP/Class/15.pm',
    'TableData/Business/ID/DGIP/Class/16.pm',
    'TableData/Business/ID/DGIP/Class/17.pm',
    'TableData/Business/ID/DGIP/Class/18.pm',
    'TableData/Business/ID/DGIP/Class/19.pm',
    'TableData/Business/ID/DGIP/Class/2.pm',
    'TableData/Business/ID/DGIP/Class/20.pm',
    'TableData/Business/ID/DGIP/Class/21.pm',
    'TableData/Business/ID/DGIP/Class/22.pm',
    'TableData/Business/ID/DGIP/Class/23.pm',
    'TableData/Business/ID/DGIP/Class/24.pm',
    'TableData/Business/ID/DGIP/Class/25.pm',
    'TableData/Business/ID/DGIP/Class/26.pm',
    'TableData/Business/ID/DGIP/Class/27.pm',
    'TableData/Business/ID/DGIP/Class/28.pm',
    'TableData/Business/ID/DGIP/Class/29.pm',
    'TableData/Business/ID/DGIP/Class/3.pm',
    'TableData/Business/ID/DGIP/Class/30.pm',
    'TableData/Business/ID/DGIP/Class/31.pm',
    'TableData/Business/ID/DGIP/Class/32.pm',
    'TableData/Business/ID/DGIP/Class/33.pm',
    'TableData/Business/ID/DGIP/Class/34.pm',
    'TableData/Business/ID/DGIP/Class/35.pm',
    'TableData/Business/ID/DGIP/Class/36.pm',
    'TableData/Business/ID/DGIP/Class/37.pm',
    'TableData/Business/ID/DGIP/Class/38.pm',
    'TableData/Business/ID/DGIP/Class/39.pm',
    'TableData/Business/ID/DGIP/Class/4.pm',
    'TableData/Business/ID/DGIP/Class/40.pm',
    'TableData/Business/ID/DGIP/Class/41.pm',
    'TableData/Business/ID/DGIP/Class/42.pm',
    'TableData/Business/ID/DGIP/Class/43.pm',
    'TableData/Business/ID/DGIP/Class/44.pm',
    'TableData/Business/ID/DGIP/Class/45.pm',
    'TableData/Business/ID/DGIP/Class/5.pm',
    'TableData/Business/ID/DGIP/Class/6.pm',
    'TableData/Business/ID/DGIP/Class/7.pm',
    'TableData/Business/ID/DGIP/Class/8.pm',
    'TableData/Business/ID/DGIP/Class/9.pm',
    'TableDataBundle/Business/ID/DGIP.pm'
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


