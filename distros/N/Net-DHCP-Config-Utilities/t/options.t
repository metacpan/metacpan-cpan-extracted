#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

BEGIN {
    use_ok( 'Net::DHCP::Config::Utilities::Options' ) || print "Bail out!\n";
}

my $worked=0;
my $dhcp_options;
eval{
	$dhcp_options=Net::DHCP::Config::Utilities::Options->new;
	$worked=1;
};
ok( $worked eq '1', 'init') or diag('new failed with... '.$@);

if( $ENV{'perl_dev_test'} ){
	use Data::Dumper;
	diag( "object dump...\n".Dumper( $dhcp_options ) );
}

$worked=0;
my $options;
eval{
	$options=$dhcp_options->get_options;
	if ( !defined( $options->{routers} ) ){
		die( 'The key "routers" was not found' );
	}
	$worked=1;
};
ok( $worked eq '1', 'get_options') or diag('get_options failed with... '.$@);

if( $ENV{'perl_dev_test'} ){
	diag( "options dump...\n".Dumper( $options ) );
}

$worked=0;
eval{
	my $long=$dhcp_options->get_long('root');
	if ( !defined( $long ) ){
		die( 'Undefined value returned' );
	}elsif( $long ne 'root-path' ){
		die( '"'.$long.'" was returned for "root" instead of "root-path"' );
	}
	$worked=1;
};
ok( $worked eq '1', 'get_long') or diag('get_long failed with... '.$@);

$worked=0;
eval{
	my $code=$dhcp_options->get_code('mask');
	if ( !defined( $code ) ){
		die( 'Undefined value returned' );
	}elsif( $code ne '0' ){
		die( '"'.$code.'" was returned for "mask" instead of "0"' );
	}
	$worked=1;
};
ok( $worked eq '1', 'get_code') or diag('get_code failed with... '.$@);

$worked=0;
eval{
	my $multiple=$dhcp_options->get_multiple('mask');
	if ( !defined( $multiple ) ){
		die( 'Undefined value returned' );
	}elsif( $multiple ne '0' ){
		die( '"'.$multiple.'" was returned for "mask" instead of "0"' );
	}
	$worked=1;
};
ok( $worked eq '1', 'get_multiple') or diag('get_multiple failed with... '.$@);

$worked=0;
eval{
	my $type=$dhcp_options->get_type('mask');
	if ( !defined( $type ) ){
		die( 'Undefined value returned' );
	}elsif( $type ne 'ip' ){
		die( '"'.$type.'" was returned for "mask" instead of "ip"' );
	}
	$worked=1;
};
ok( $worked eq '1', 'get_type') or diag('get_type failed with... '.$@);

$worked=0;
eval{
	if (! $dhcp_options->valid_option_name('mask') ){
		die( 'valid_option_name considered "mask" invalid' );
	}
	$worked=1;
};
ok( $worked eq '1', 'valid_option_name, valid') or diag('failed with... '.$@);

$worked=0;
eval{
	if ($dhcp_options->valid_option_name('foo foo') ){
		die( 'valid_option_name considered "foo foo" valid' );
	}
	$worked=1;
};
ok( $worked eq '1', 'valid_option_name, invalid') or diag('failed with... '.$@);

$worked=0;
eval{
	my $error=$dhcp_options->validate_option('mask', '255.255.255.0');
	if ( defined( $error ) ){
		die( '"mask" with "255.255.255.0" was considered invalid... '.$error );
	}
	$worked=1;
};
ok( $worked eq '1', 'validate_option, valid 1') or diag('failed with... '.$@);

$worked=0;
eval{
	my $error=$dhcp_options->validate_option('root', '192.168.0.52:/foo/bar');
	if ( defined( $error ) ){
		die( '"root" with "192.168.0.52:/foo/bar" was considered invalid... '.$error );
	}
	$worked=1;
};
ok( $worked eq '1', 'validate_option, valid 1') or diag('failed with... '.$@);

$worked=0;
eval{
	my $error=$dhcp_options->validate_option('mtu', '1600');
	if ( defined( $error ) ){
		die( '"mtu" with "1600" was considered invalid... '.$error );
	}
	$worked=1;
};
ok( $worked eq '1', 'validate_option, valid 1') or diag('failed with... '.$@);

$worked=0;
eval{
	my $error=$dhcp_options->validate_option('mask', 'foo');
	if ( ! defined( $error ) ){
		die( '"mask" with "foo" was considered valid' );
	}
	$worked=1;
};
ok( $worked eq '1', 'validate_option, invalid 1') or diag('failed with... '.$@);

$worked=0;
eval{
	my $error=$dhcp_options->validate_option('root', undef);
	if ( ! defined( $error ) ){
		die( '"root" with undef was consideredvalid' );
	}
	$worked=1;
};
ok( $worked eq '1', 'validate_option, invalid 2') or diag('failed with... '.$@);

$worked=0;
eval{
	my $error=$dhcp_options->validate_option('mtu', '1600a');
	if ( ! defined( $error ) ){
		die( '"mtu" with "1600a" was considered valid' );
	}
	$worked=1;
};
ok( $worked eq '1', 'validate_option, invalid 3') or diag('failed with... '.$@);

$worked=0;
eval{
	my $error=$dhcp_options->validate_option('dns', '192.168.0.1, 10.10.10.10 , 1.1.1.1   ,    1.2.3.4,5.6.7.8');
	if ( defined( $error ) ){
		die( '"dns" with "192.168.0.1, 10.10.10.10 , 1.1.1.1   ,    1.2.3.4,5.6.7.8" was considered invalid... '.$error );
	}
	$worked=1;
};
ok( $worked eq '1', 'validate_option, multiple valid') or diag('failed with... '.$@);

$worked=0;
eval{
	my $error=$dhcp_options->validate_option('dns', '192.168.0.1, foo');
	if ( ! defined( $error ) ){
		die( '"dns" with "192.168.0.1, foo" was considered valid' );
	}
	$worked=1;
};
ok( $worked eq '1', 'validate_option, multiple semivalid') or diag('failed with... '.$@);

done_testing(17);
