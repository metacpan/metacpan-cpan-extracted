#!perl -T

use warnings;
use strict;

use File::Spec::Functions;
use Test::More tests => 47;
use Test::Differences;
use lib qw( lib );

my $datadir      = q{data};  # test files
my %file2content = ();

BEGIN { use_ok('Parse::Flash::Cookie') }
use Parse::Flash::Cookie;
ok(1);

# create separate block to disable warning since we use commas within qw()
{
  no warnings q{qw};
  %file2content = (
    'A_Browser.sol'               => [qw(A_Browser lastViewedFeatureIndex;number;1)],
    'Synergy_Area.sol'            => [qw(Synergy_Area lastViewedFeatureIndex;number;1)],
    'TestMovie_Config_Info.sol'   => [qw(TestMovie_Config_Info config;object-customclass;class_name=NetDebugConfig;,m_debug;1,client;class_name=NetDebugConfig;,m_debug;1,trace;1,recordset;1,http;1,rtmp;1,realtime_server;class_name=NetDebugConfig;,m_debug;1,trace;1,app_server;class_name=NetDebugConfig;,m_debug;1,trace;1,error;1,recordset;1,httpheaders;0,amf;0,amfheaders;0,coldfusion;1)],
    'clearspring.sol'             => [qw(clearspring userId;string;470f65bcd2e75653 sessions;object;470f65ea2bea2428;ver=0%2E7%2E8 events;object;470f65ea2bea2428;0;array;0;number;34,1;number;1192191468014,2;undefined; lastHeartbeat;object;470f65ea2bea2428;1192191476467 loadTime;object;470f65ea2bea2428;1192191466276 servers;object;470f65ea2bea2428;cs40.clearspring.com:80 newPlacements;object;470f65ea2bea2428;0 clicks;object;470f65ea2bea2428;0 clickmap;object;470f65ea2bea2428; interactionTimes;object;470f65ea2bea2428;0 versions;object; )],
    'lastPart.sol'                => [qw(lastPart lastPart_nr;number;1)],
    'mediaPlayerUserSettings.sol' => [qw (mediaPlayerUserSettings volume;number;1 smoothing;boolean;0 sizeMode;string;fit )],
    'revverplayer.sol'            => [qw(revverplayer cookie;string;5d72699b80429b5b32e64cbb42ddc73f)],
    'settings.sol'                => [qw(settings website.com;object;video.google.com;1,nokia.com;1,www.youtube.com;1,youtube.com;1,pandora.com;1,disney.com;1,flash.revver.com;1,slashdot.org;1,perlmonks.org;1 gain;number;50 echosuppression;boolean;0 defaultmicrophone;string; defaultcamera;string; defaultklimit;number;100 defaultalways;boolean;0 crossdomainAllow;boolean;0 crossdomainAlways;boolean;0 )],
    'soundData.sol'               => [qw(soundData volume;number;100 mute;boolean;0)],
    'v3_Machine.sol'              => [qw (v3_Machine volume;number;100 persistenceTestValue;number;1 anonymousAuthToken;null; stationSortOrder;boolean;1 station;string;159774106279022222 playTime;number;1251997 hasLoggedIn;boolean;1) ],
    'v3_PerfComp.sol'             => [qw(v3_PerfComp counts;object;st159758330864144014;6,st159773247285563022;4,st159774106279022222;5 timestamps;object;st159758330864144014;1161599020564,st159773247285563022;1161599713693,st159774106279022222;1161600321118 totalListeningTimes;object;st159758330864144014;7801549,st159773247285563022;595251,st159774106279022222;1711777 lastListeningTimestamps;object;st159758330864144014;1161599715935,st159773247285563022;1161600323067,st159774106279022222;1161602049881 routeid;number;1161588196700 routeExpiration;number;1161616450212)],
    'v4_UserCredentials.sol'      => [qw (v4_UserCredentials username;string;foo@bar.com password;string;qwerty )],
    'video.sol'                   => [qw(video soundmuted;boolean;0)],
		'wrong_size.sol' => ['test',qq{+Infinity;number;inf},qq{-Infinity;number;-inf},'tBoolean;boolean;1','fBoolean;boolean;0','eBoolean;boolean;1','Date;date;date;1212359634000;-9'],
    'base_test.sol' => ['test',qq{+Infinity;number;inf},qq{-Infinity;number;-inf},'tBoolean;boolean;1','fBoolean;boolean;0','eBoolean;boolean;1','Date;date;date;1212359634000;-9'
],
  );
}


# Use sort to create test in a predictable sequence
foreach my $file (sort keys %file2content) {

  # untaint using expression from File::Find
  $file =~ qr|^([-+@\w./]+)$|;
  $file = $1;

  # locate test file
  my $file_with_path = catfile(q{data}, $file);
  ok(-f $file_with_path, qq{Expect '$file' to be a file on local filesystem});

 SKIP: {
    skip q{Cannot test missing file}, 2 unless -f $file_with_path;

    # check content of test file
    my @content      = ();
    eval {
      @content = Parse::Flash::Cookie::to_text($file_with_path);
    };
    ok($@ eq q{}, qq{to_text died when parsing '$file_with_path'}) or
      diag(q{Error message: } . $@);

    eq_or_diff \@content, $file2content{$file}, "testing $file_with_path content ";
  }
}

__END__
