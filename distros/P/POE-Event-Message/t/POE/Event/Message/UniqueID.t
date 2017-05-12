# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl POE-Event-Message.t'

#########################

use Test::More tests => 2;

## BEGIN {  # use/test Time::HiRes  }
## skip tests if not available

BEGIN { use_ok('POE::Event::Message') };             # 01

my $genId = "POE::Event::Message::UniqueID";
$genId->verifyGenerateUniqueID();
my $errCount = $genId->dupErrCount();
is ( $errCount, 0, "Duplicate IDs generated?" );     # 02

#########################
