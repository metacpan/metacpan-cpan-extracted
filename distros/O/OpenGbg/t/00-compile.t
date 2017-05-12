use 5.006;
use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.054

use Test::More;

plan tests => 24 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

my @module_files = (
    'OpenGbg.pm',
    'OpenGbg/DateTimeType.pm',
    'OpenGbg/Elk.pm',
    'OpenGbg/Exceptions.pm',
    'OpenGbg/Service/AirQuality.pm',
    'OpenGbg/Service/AirQuality/GetLatestMeasurement.pm',
    'OpenGbg/Service/AirQuality/GetMeasurements.pm',
    'OpenGbg/Service/AirQuality/Measurement.pm',
    'OpenGbg/Service/AirQuality/Measurements.pm',
    'OpenGbg/Service/Bridge.pm',
    'OpenGbg/Service/Bridge/BridgeOpening.pm',
    'OpenGbg/Service/Bridge/BridgeOpenings.pm',
    'OpenGbg/Service/Bridge/GetIsCurrentlyOpen.pm',
    'OpenGbg/Service/Bridge/GetOpenedStatus.pm',
    'OpenGbg/Service/Getter.pm',
    'OpenGbg/Service/StyrOchStall.pm',
    'OpenGbg/Service/StyrOchStall/GetBikeStation.pm',
    'OpenGbg/Service/StyrOchStall/GetBikeStations.pm',
    'OpenGbg/Service/StyrOchStall/Station.pm',
    'OpenGbg/Service/TrafficCamera.pm',
    'OpenGbg/Service/TrafficCamera/CameraDevice.pm',
    'OpenGbg/Service/TrafficCamera/CameraDevices.pm',
    'OpenGbg/Service/TrafficCamera/GetCameraImage.pm',
    'OpenGbg/Service/TrafficCamera/GetTrafficCameras.pm'
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


