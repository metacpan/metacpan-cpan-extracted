use 5.006;
use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.048

use Test::More;

plan tests => 12 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

my @module_files = (
    'MooseX/TrackDirty/Attributes.pm',
    'MooseX/TrackDirty/Attributes/Trait/Attribute.pm',
    'MooseX/TrackDirty/Attributes/Trait/Attribute/Native/Trait.pm',
    'MooseX/TrackDirty/Attributes/Trait/Class.pm',
    'MooseX/TrackDirty/Attributes/Trait/Method/Accessor.pm',
    'MooseX/TrackDirty/Attributes/Trait/Method/Accessor/Native.pm',
    'MooseX/TrackDirty/Attributes/Trait/Role.pm',
    'MooseX/TrackDirty/Attributes/Trait/Role/Application/ToClass.pm',
    'MooseX/TrackDirty/Attributes/Trait/Role/Application/ToInstance.pm',
    'MooseX/TrackDirty/Attributes/Trait/Role/Application/ToRole.pm',
    'MooseX/TrackDirty/Attributes/Trait/Role/Composite.pm',
    'MooseX/TrackDirty/Attributes/Util.pm'
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


