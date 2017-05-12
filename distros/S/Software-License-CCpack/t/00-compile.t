use 5.006;
use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.051

use Test::More;

plan tests => 26 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

my @module_files = (
    'Software/License/CC_BY_1_0.pm',
    'Software/License/CC_BY_2_0.pm',
    'Software/License/CC_BY_3_0.pm',
    'Software/License/CC_BY_4_0.pm',
    'Software/License/CC_BY_NC_1_0.pm',
    'Software/License/CC_BY_NC_2_0.pm',
    'Software/License/CC_BY_NC_3_0.pm',
    'Software/License/CC_BY_NC_4_0.pm',
    'Software/License/CC_BY_NC_ND_2_0.pm',
    'Software/License/CC_BY_NC_ND_3_0.pm',
    'Software/License/CC_BY_NC_ND_4_0.pm',
    'Software/License/CC_BY_NC_SA_1_0.pm',
    'Software/License/CC_BY_NC_SA_2_0.pm',
    'Software/License/CC_BY_NC_SA_3_0.pm',
    'Software/License/CC_BY_NC_SA_4_0.pm',
    'Software/License/CC_BY_ND_1_0.pm',
    'Software/License/CC_BY_ND_2_0.pm',
    'Software/License/CC_BY_ND_3_0.pm',
    'Software/License/CC_BY_ND_4_0.pm',
    'Software/License/CC_BY_ND_NC_1_0.pm',
    'Software/License/CC_BY_SA_1_0.pm',
    'Software/License/CC_BY_SA_2_0.pm',
    'Software/License/CC_BY_SA_3_0.pm',
    'Software/License/CC_BY_SA_4_0.pm',
    'Software/License/CC_PDM_1_0.pm',
    'Software/License/CCpack.pm'
);



# no fake home requested

my $inc_switch = -d 'blib' ? '-Mblib' : '-Ilib';

use File::Spec;
use IPC::Open3;
use IO::Handle;

open my $stdin, '<', File::Spec->devnull or die "can't open devnull: $!";

my @warnings;
for my $lib (@module_files)
{
    # see L<perlfaq8/How can I capture STDERR from an external command?>
    my $stderr = IO::Handle->new;

    my $pid = open3($stdin, '>&STDERR', $stderr, $^X, $inc_switch, '-e', "require q[$lib]");
    binmode $stderr, ':crlf' if $^O eq 'MSWin32';
    my @_warnings = <$stderr>;
    waitpid($pid, 0);
    is($?, 0, "$lib loaded ok");

    if (@_warnings)
    {
        warn @_warnings;
        push @warnings, @_warnings;
    }
}



is(scalar(@warnings), 0, 'no warnings found')
    or diag 'got warnings: ', ( Test::More->can('explain') ? Test::More::explain(\@warnings) : join("\n", '', @warnings) ) if $ENV{AUTHOR_TESTING};


