use strict;
use Test;

use Net::FTP::Common;
use Data::Dumper;

BEGIN { plan tests => 3 }

use TestConfig;

# fodder to eliminiate 
# Name "TestConfig::netftp_cfg" used only once: possible typo 
# red herring errors
keys %TestConfig::common_cfg;
keys %TestConfig::netftp_cfg;

warn Data::Dumper->Dump([\%TestConfig::common_cfg, \%TestConfig::netftp_cfg], [qw(common netftp)]);

my $ez = Net::FTP::Common->new
  (\%TestConfig::common_cfg, %TestConfig::netftp_cfg);

$ez->Common
  (
   Host => 'ftp.ddj.com',
   RemoteDir  => '/',
   RemoteFile =>  'README'
  );


#
# Test 1
#
my $retval = $ez->get(LocalFile => 'localname.test');
ok($retval);

#
# Test 2
#
$retval = $ez->get(LocalDir => 't/dldir');
ok($retval);

#
# Test 3
#
$ez->Common(LocalFile => '');
$retval = $ez->get(LocalDir => 't/dldir');
ok($retval);

