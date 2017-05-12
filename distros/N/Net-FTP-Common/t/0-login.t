use strict;
use Test;

use Net::FTP::Common;
use Data::Dumper;

BEGIN { plan tests => 1 }

use TestConfig;

# fodder to eliminiate 
# Name "TestConfig::netftp_cfg" used only once: possible typo 
# red herring errors
keys %TestConfig::common_cfg;
keys %TestConfig::netftp_cfg;

#warn Data::Dumper->Dump([\%TestConfig::common_cfg, \%TestConfig::netftp_cfg], [qw(common netftp)]);

my $ez = Net::FTP::Common->new
  (\%TestConfig::common_cfg, %TestConfig::netftp_cfg);

#
# Test 1
#

#my $retval = $ez->login('call with one arg to see it fail')
#also, alter TestConfig.pm so that it attempts to connect to a host
#which does not exist

warn "Using version $Net::FTP::Common::VERSION";

my $retval = $ez->login;
ok("$retval", qr/Net::FTP=GLOB/);
