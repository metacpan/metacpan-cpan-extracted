# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl TAP3-Tap3edit.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 123;
BEGIN { use_ok('TAP3::Tap3edit') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

use TAP3::Tap3edit;
use Data::Dumper;
$Data::Dumper::Indent=1;
$Data::Dumper::Quotekeys=1;
$Data::Dumper::Useqq=1;

$filename="CDOPER1OPER200001";

$notific_struct = {
    "notification" => {
      "releaseVersionNumber" => 11,
      "transferCutOffTimeStamp" => {
        "localTimeStamp" => "20040101000000",
        "utcTimeOffset" => "+0000"
      },
      "recipient" => "OPER2",
      "specificationVersionNumber" => 3,
      "fileCreationTimeStamp" => {
        "localTimeStamp" => "20040101000000",
        "utcTimeOffset" => "+0000"
      },
      "sender" => "OPER1",
      "fileSequenceNumber" => "00001",
      "fileAvailableTimeStamp" => {
        "localTimeStamp" => "20040101000000",
        "utcTimeOffset" => "+0000"
      }
    },
};

$acknowledge_struct = {
    "acknowledgement" => {
        "rapFileSequenceNumber" => "00001",
        "ackFileCreationTimeStamp" => {
            "localTimeStamp" => "20120101000000",
            "utcTimeOffset" => "+0100"
        },
        "recipient" => "OPER2",
        "ackFileAvailableTimeStamp" => {
            "localTimeStamp" => "20120101000000",
            "utcTimeOffset" => "+0100"
        },
        "sender" => "OPER1"
    }
};

$nrtrde_struct = {
    "releaseVersionNumber" => 1,
    "sequenceNumber" => "00001",
    "recipient" => "OPER1",
    "specificationVersionNumber" => 2,
    "utcTimeOffset" => "+0100",
    "callEvents" => [
        {
            "moc" => {
                "imei" => "991111111111",
                "causeForTermination" => 1,
                "dialledDigits" => "005411111111",
                "utcTimeOffset" => "+0100",
                "imsi" => "208011111111111",
                "cellId" => 12345,
                "connectedNumber" => "005411111111",
                "callEventStartTimeStamp" => "20110607050505",
                "locationArea" => 12346,
                "chargeAmount" => 123,
                "msisdn" => "992222222222",
                "callEventDuration" => 111,
                "recEntityId" => "SWITCH 1",
                "callReference" => 996010870,
                "serviceCode" => {
                    "teleServiceCode" => 11
                }
            }
        }
    ],
    "sender" => "OPER1",
    "fileAvailableTimeStamp" => "20120205001847",
    "callEventsCount" => 1
};


# TAP3.1
ok($tap3=TAP3::Tap3edit->new());

ok($tap3->file_type("TAP"));
ok($tap3->version(3));
ok($tap3->release(1));

ok($tap3->structure($notific_struct));
ok($tap3->encode($filename) || die $tap3->error());
ok($tap3->get_info($filename) || die $tap3->error());
ok($tap3->decode($filename) || die $tap3->error());

# TAP3.2
ok($tap3=TAP3::Tap3edit->new());

ok($tap3->file_type("TAP"));
ok($tap3->version(3));
ok($tap3->release(2));

ok($tap3->structure($notific_struct));
ok($tap3->encode($filename) || die $tap3->error());
ok($tap3->get_info($filename) || die $tap3->error());
ok($tap3->decode($filename) || die $tap3->error());

# TAP3.3
ok($tap3=TAP3::Tap3edit->new());

ok($tap3->file_type("TAP"));
ok($tap3->version(3));
ok($tap3->release(3));

ok($tap3->structure($notific_struct));
ok($tap3->encode($filename) || die $tap3->error());
ok($tap3->get_info($filename) || die $tap3->error());
ok($tap3->decode($filename) || die $tap3->error());

# TAP3.4
ok($tap3=TAP3::Tap3edit->new());

ok($tap3->file_type("TAP"));
ok($tap3->version(3));
ok($tap3->release(4));

ok($tap3->structure($notific_struct));
ok($tap3->encode($filename) || die $tap3->error());
ok($tap3->get_info($filename) || die $tap3->error());
ok($tap3->decode($filename) || die $tap3->error());

# TAP3.9
ok($tap3=TAP3::Tap3edit->new());

ok($tap3->file_type("TAP"));
ok($tap3->version(3));
ok($tap3->release(9));

ok($tap3->structure($notific_struct));
ok($tap3->encode($filename) || die $tap3->error());
ok($tap3->get_info($filename) || die $tap3->error());
ok($tap3->decode($filename) || die $tap3->error());

# TAP3.10
ok($tap3=TAP3::Tap3edit->new());

ok($tap3->file_type("TAP"));
ok($tap3->version(3));
ok($tap3->release(10));

ok($tap3->structure($notific_struct));
ok($tap3->encode($filename) || die $tap3->error());
ok($tap3->get_info($filename) || die $tap3->error());
ok($tap3->decode($filename) || die $tap3->error());

# TAP3.11
ok($tap3=TAP3::Tap3edit->new());

ok($tap3->file_type("TAP"));
ok($tap3->version(3));
ok($tap3->release(11));

ok($tap3->structure($notific_struct));
ok($tap3->encode($filename) || die $tap3->error());
ok($tap3->get_info($filename) || die $tap3->error());
ok($tap3->decode($filename) || die $tap3->error());

# TAP3.12
ok($tap3=TAP3::Tap3edit->new());

ok($tap3->file_type("TAP"));
ok($tap3->version(3));
ok($tap3->release(12));

ok($tap3->structure($notific_struct));
ok($tap3->encode($filename) || die $tap3->error());
ok($tap3->get_info($filename) || die $tap3->error());
ok($tap3->decode($filename) || die $tap3->error());

# RAP1.1
ok($tap3=TAP3::Tap3edit->new());

ok($tap3->file_type("RAP"));
ok($tap3->version(1));
ok($tap3->release(1));
ok($tap3->supl_version(3));
ok($tap3->supl_release(10));

ok($tap3->structure($acknowledge_struct));
ok($tap3->encode($filename) || die $tap3->error());
ok($tap3->get_info($filename) || die $tap3->error());
ok($tap3->decode($filename) || die $tap3->error());

# RAP1.2
ok($tap3=TAP3::Tap3edit->new());

ok($tap3->file_type("RAP"));
ok($tap3->version(1));
ok($tap3->release(2));
ok($tap3->supl_version(3));
ok($tap3->supl_release(10));

ok($tap3->structure($acknowledge_struct));
ok($tap3->encode($filename) || die $tap3->error());
ok($tap3->get_info($filename) || die $tap3->error());
ok($tap3->decode($filename) || die $tap3->error());

# RAP1.3
ok($tap3=TAP3::Tap3edit->new());

ok($tap3->file_type("RAP"));
ok($tap3->version(1));
ok($tap3->release(3));
ok($tap3->supl_version(3));
ok($tap3->supl_release(10));

ok($tap3->structure($acknowledge_struct));
ok($tap3->encode($filename) || die $tap3->error());
ok($tap3->get_info($filename) || die $tap3->error());
ok($tap3->decode($filename) || die $tap3->error());

# RAP1.4
ok($tap3=TAP3::Tap3edit->new());

ok($tap3->file_type("RAP"));
ok($tap3->version(1));
ok($tap3->release(4));
ok($tap3->supl_version(3));
ok($tap3->supl_release(10));

ok($tap3->structure($acknowledge_struct));
ok($tap3->encode($filename) || die $tap3->error());
ok($tap3->get_info($filename) || die $tap3->error());
ok($tap3->decode($filename) || die $tap3->error());

# RAP1.5
ok($tap3=TAP3::Tap3edit->new());

ok($tap3->file_type("RAP"));
ok($tap3->version(1));
ok($tap3->release(5));
ok($tap3->supl_version(3));
ok($tap3->supl_release(10));

ok($tap3->structure($acknowledge_struct));
ok($tap3->encode($filename) || die $tap3->error());
ok($tap3->get_info($filename) || die $tap3->error());
ok($tap3->decode($filename) || die $tap3->error());

# NRT2.1
ok($tap3=TAP3::Tap3edit->new());

ok($tap3->file_type("NRT"));
ok($tap3->version(2));
ok($tap3->release(1));

ok($tap3->structure($nrtrde_struct));
ok($tap3->encode($filename) || die $tap3->error());
ok($tap3->get_info($filename) || die $tap3->error());
ok($tap3->decode($filename) || die $tap3->error());


if ( -f $filename ) { unlink $filename };
