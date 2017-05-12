use Net::FTP;
use lib '../../lib';
use TestConfig;
use strict;
use Data::Dumper;

my $ftp = Net::FTP->new($TestConfig::common_cfg{Host}, Debug => 1, Passive => 1);
$ftp->login("anonymous",'-anonymous@');
$ftp->cwd("/pub");
my @ls = $ftp->ls;


die Dumper(\@ls);
