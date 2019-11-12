#!perl
use 5.006;
use strict;
use warnings;
use Test::More;
use Net::DHCP::Config::Utilities;
use Net::DHCP::Config::Utilities::INI_loader;

BEGIN {
    use_ok( 'Net::DHCP::Config::Utilities::Generator::ISC_DHCPD' ) || print "Bail out!\n";
}


# figure out if DHCPD is installed for later usage
my $dhcpd_bin=`/bin/sh -c 'which dhcpd 2> /dev/null'`;
my $dhcpd_avail=0;
if ( $? == 0 ){
	$dhcpd_avail=1;
}else{
	diag('ISC DHCPD is not installed. Output linting will be skipped.');
}

my $dhcp_util=Net::DHCP::Config::Utilities->new;
my $ini_loader=Net::DHCP::Config::Utilities::INI_loader->new($dhcp_util);
$ini_loader->load_dir( 't/ini/' );

my $worked=0;
my $generator;
eval{
	$generator=Net::DHCP::Config::Utilities::Generator::ISC_DHCPD->new({
																		'footer'=>'t/iscdhcpd/footer',
																		'header'=>'t/iscdhcpd/header',
																		'vars'=>{a=>1},
																		'output'=>'t/iscdhcpd/output',
																		});
	$worked=1;
};
ok( $worked eq '1', 'init') or diag('new failed with... '.$@);

if ( -f 't/iscdhcpd/output' ){
	unlink( 't/iscdhcpd/output' );
}

$worked=0;
eval{
	$generator->generate( $dhcp_util );
	if ( ! -f 't/iscdhcpd/output' ){
		die( 'Failed to write out "t/iscdhcpd/output"' );
	}
	if ( $dhcpd_avail ){
		my $check=`/bin/sh -c 'dhcpd -t -cf t/iscdhcpd/output 2> /dev/null'`;
		if ( $? != 0 ){
			die('"dhcpd -t -cf t/iscdhcpd/output" exited with a non-zero value');
		}
	}
	$worked=1;
};
ok( $worked eq '1', 'generate') or diag('generator failed with... '.$@);

diag( 'Check t/iscdhcpd/output and make sure it looks sane' );

done_testing(3);
