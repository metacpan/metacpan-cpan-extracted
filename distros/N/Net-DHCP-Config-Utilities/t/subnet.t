#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

BEGIN {
    use_ok( 'Net::DHCP::Config::Utilities::Subnet' ) || print "Bail out!\n";
}

my $options={
			 base=>'10.0.0.0',
			 mask=>'255.255.255.0',
			 dns=>'10.0.0.1 , 10.0.10.1',
			 desc=>'a example subnet',
			 range=>[
					 '10.0.0.100 10.0.0.200'
					 ],
			 };

my $worked=0;
my $subnet;
eval{
	$subnet=Net::DHCP::Config::Utilities::Subnet->new($options);
	$worked=1;
};
ok( $worked eq '1', 'init') or diag('new failed with... '.$@);

if( $ENV{'perl_dev_test'} ){
	use Data::Dumper;
	diag( "object dump...\n".Dumper( $subnet ) );
}

$worked=0;
eval{
	my $base=$subnet->base_get;
	if ( $base ne $options->{base} ){
		die( '"'.$base.'" was returned for the base, but "'.$options->{base}.'" was expcted');
	}
	$worked=1;
};
ok( $worked eq '1', 'base_get') or diag('base_get failed with... '.$@);

$worked=0;
eval{
	my $desc=$subnet->desc_get;
	if ( $desc ne $options->{desc} ){
		die( '"'.$desc.'" was returned for the base, but "'.$options->{desc}.'" was expcted');
	}
	$worked=1;
};
ok( $worked eq '1', 'desc_get') or diag('desc_get failed with... '.$@);

$worked=0;
eval{
	my $mask=$subnet->mask_get;
	if ( $mask ne $options->{mask} ){
		die( '"'.$mask.'" was returned for the mask, but "'.$options->{mask}.'" was expcted');
	}
	$worked=1;
};
ok( $worked eq '1', 'mask_get') or diag('mask_get failed with... '.$@);

$worked=0;
eval{
	my $option=$subnet->option_get('dns');
	if ( $option ne $options->{dns} ){
		die( '"'.$option.'" was returned for the option dns, but "'.$options->{dns}.'" was expcted');
	}
	$worked=1;
};
ok( $worked eq '1', 'option_get') or diag('option_get failed with... '.$@);

$worked=0;
eval{
	$subnet->option_set('ntp', '10.0.0.1');
	$worked=1;
};
ok( $worked eq '1', 'option_set, set') or diag('option_set failed with... '.$@);

$worked=0;
eval{
	my $option=$subnet->option_get('ntp');
	if ( $option ne '10.0.0.1' ){
		die( '"'.$option.'" was returned for the option ntp, but "10.0.0.1" was expcted... the previous set failed');
	}
	$worked=1;
};
ok( $worked eq '1', 'option_set, check') or diag($@);

$worked=0;
eval{
	$subnet->option_set('ntp');
	$worked=1;
};
ok( $worked eq '1', 'option_set, delete') or diag('option_set failed with... '.$@);

$worked=0;
eval{
	my $option=$subnet->option_get('ntp');
	if ( defined( $option ) ){
		die( 'Previous check was suppose to remove option ntp, but option_get("ntp") returned "'.$option.'"');
	}
	$worked=1;
};
ok( $worked eq '1', 'option_set, delete check') or diag($@);

$worked=0;
eval{
	$subnet->option_set('mask', '255.255.255.0');
	$worked=1;
};
ok( $worked eq '0', 'option_set, mask') or diag('option_set should not work for mask');


$worked=0;
$options={
		  base=>'10.0.0.0',
		  mask=>'255.255.255.0',
		  dns=>'10.0.0.1 , 10.0.10.1',
		  desc=>'a example subnet',
		  ranges=>[
				   '10.0.0.100 10.0.1.200'
				   ],
		  };
eval{
	$subnet=Net::DHCP::Config::Utilities::Subnet->new($options);
	$worked=1;
};
ok( $worked ne '1', 'init, bad subnet') or diag('new failed to check if range was outside of the subnet');

if( $ENV{'perl_dev_test'} ){
	use Data::Dumper;
	diag( "object dump...\n".Dumper( $subnet ) );
}

done_testing(12);
