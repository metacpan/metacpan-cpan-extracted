use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/OpenGbg.pm',
    'lib/OpenGbg/Elk.pm',
    'lib/OpenGbg/Exceptions.pm',
    'lib/OpenGbg/Service/AirQuality.pm',
    'lib/OpenGbg/Service/AirQuality/GetLatestMeasurement.pm',
    'lib/OpenGbg/Service/AirQuality/GetMeasurements.pm',
    'lib/OpenGbg/Service/AirQuality/Measurement.pm',
    'lib/OpenGbg/Service/AirQuality/Measurements.pm',
    'lib/OpenGbg/Service/Bridge.pm',
    'lib/OpenGbg/Service/Bridge/BridgeOpening.pm',
    'lib/OpenGbg/Service/Bridge/BridgeOpenings.pm',
    'lib/OpenGbg/Service/Bridge/GetIsCurrentlyOpen.pm',
    'lib/OpenGbg/Service/Bridge/GetOpenedStatus.pm',
    'lib/OpenGbg/Service/Getter.pm',
    'lib/OpenGbg/Service/StyrOchStall.pm',
    'lib/OpenGbg/Service/StyrOchStall/GetBikeStation.pm',
    'lib/OpenGbg/Service/StyrOchStall/GetBikeStations.pm',
    'lib/OpenGbg/Service/StyrOchStall/Station.pm',
    'lib/OpenGbg/Service/TrafficCamera.pm',
    'lib/OpenGbg/Service/TrafficCamera/CameraDevice.pm',
    'lib/OpenGbg/Service/TrafficCamera/CameraDevices.pm',
    'lib/OpenGbg/Service/TrafficCamera/GetCameraImage.pm',
    'lib/OpenGbg/Service/TrafficCamera/GetTrafficCameras.pm',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01-styrochstall.t',
    't/02-air-quality.t',
    't/03-bridge.t',
    't/04-traffic-camera.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
