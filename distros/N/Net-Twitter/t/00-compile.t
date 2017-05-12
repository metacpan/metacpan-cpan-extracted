use 5.006;
use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.054

use Test::More;

plan tests => 27 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

my @module_files = (
    'Net/Identica.pm',
    'Net/Twitter.pm',
    'Net/Twitter/API.pm',
    'Net/Twitter/Core.pm',
    'Net/Twitter/Error.pm',
    'Net/Twitter/OAuth.pm',
    'Net/Twitter/Role/API/Lists.pm',
    'Net/Twitter/Role/API/REST.pm',
    'Net/Twitter/Role/API/RESTv1_1.pm',
    'Net/Twitter/Role/API/Search.pm',
    'Net/Twitter/Role/API/Search/Trends.pm',
    'Net/Twitter/Role/API/TwitterVision.pm',
    'Net/Twitter/Role/API/Upload.pm',
    'Net/Twitter/Role/API/UploadMedia.pm',
    'Net/Twitter/Role/AppAuth.pm',
    'Net/Twitter/Role/AutoCursor.pm',
    'Net/Twitter/Role/InflateObjects.pm',
    'Net/Twitter/Role/Legacy.pm',
    'Net/Twitter/Role/OAuth.pm',
    'Net/Twitter/Role/RateLimit.pm',
    'Net/Twitter/Role/RetryOnError.pm',
    'Net/Twitter/Role/SimulateCursors.pm',
    'Net/Twitter/Role/WrapError.pm',
    'Net/Twitter/Role/WrapResult.pm',
    'Net/Twitter/Search.pm',
    'Net/Twitter/Types.pm',
    'Net/Twitter/WrappedResult.pm'
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

    shift @_warnings if @_warnings and $_warnings[0] =~ /^Using .*\bblib/
        and not eval { require blib; blib->VERSION('1.01') };

    if (@_warnings)
    {
        warn @_warnings;
        push @warnings, @_warnings;
    }
}



is(scalar(@warnings), 0, 'no warnings found')
    or diag 'got warnings: ', ( Test::More->can('explain') ? Test::More::explain(\@warnings) : join("\n", '', @warnings) ) if $ENV{AUTHOR_TESTING};


