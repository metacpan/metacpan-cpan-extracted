#!perl
use 5.006;
use strict;
use warnings;
use Test::More;
use Net::DHCP::Config::Utilities;

BEGIN {
    use_ok( 'Net::DHCP::Config::Utilities::INI_loader' ) || print "Bail out!\n";
}

my $dhcp_util=Net::DHCP::Config::Utilities->new;

my $worked=0;
my $ini_loader;
eval{
	$ini_loader=Net::DHCP::Config::Utilities::INI_loader->new($dhcp_util);
	$worked=1;
};
ok( $worked eq '1', 'init') or diag('new failed with... '.$@);

$worked=0;
eval{
	$ini_loader->load_file( 't/ini/10.0.0.0.dhcp.ini' );
	$worked=1;
};
ok( $worked eq '1', 'load_file 1') or diag('load_file failed with... '.$@);

$worked=0;
eval{
	$ini_loader->load_file( 't/ini/10.0.0.0.dhcp.ini' );
	$worked=1;
};
ok( $worked eq '1', 'load_file reload') or diag('load_file failed with... '.$@);

$worked=0;
eval{
	$ini_loader->load_file( 't/ini-bad/10.0.10.0.dhcp.ini' );
	$worked=1;
};
ok( $worked eq '0', 'load_file overlap') or diag('load_file loaded a subnet that overlaps a previous subnet '.$@);

$worked=0;
eval{
	$ini_loader->load_file( 't/ini/192.168.0.0.dhcp.ini' );
	$worked=1;
};
ok( $worked eq '1', 'load_file 2') or diag('load_file failed with... '.$@);

$dhcp_util=Net::DHCP::Config::Utilities->new;
eval{
	$ini_loader=Net::DHCP::Config::Utilities::INI_loader->new($dhcp_util);
};
$worked=0;
eval{
	$ini_loader->load_dir( 't/ini/' );
	$worked=1;
};
ok( $worked eq '1', 'load_dir') or diag('load_dir failed with... '.$@);

done_testing(7);
