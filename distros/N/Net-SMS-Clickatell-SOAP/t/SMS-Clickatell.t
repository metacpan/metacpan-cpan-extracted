# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl GNM-AlarmPointFuncs.t'

#########################
use Test::More; # tests => 15;

#########################
## Validate the constructor

BEGIN {
	use_ok('Net::SMS::Clickatell::SOAP') ;
};

isa_ok( $obj = Net::SMS::Clickatell::SOAP->new(), 
	'Net::SMS::Clickatell::SOAP', 
	'new() with no parameters' );
isa_ok( $obj = Net::SMS::Clickatell::SOAP->new( 
	proxy=>"http://api.clickatell.com/soap/webservice.php"), 
	'Net::SMS::Clickatell::SOAP',
	'new() with proxy parameter' );
isa_ok( $obj = Net::SMS::Clickatell::SOAP->new( 
	service=>"http://api.clickatell.com/soap/webservice.php?wsdl"), 
	'Net::SMS::Clickatell::SOAP',
	'new() with service parameter' );
isa_ok( $obj = Net::SMS::Clickatell::SOAP->new( 
	proxy=>"http://api.clickatell.com/soap/webservice.php", 
	service=>"http://api.clickatell.com/soap/webservice.php?wsdl"), 
	'Net::SMS::Clickatell::SOAP',
	'new() with proxy and service parameters' );
isa_ok( $obj = Net::SMS::Clickatell::SOAP->new( 
	Service=>"http://api.clickatell.com/soap/webservice.php?wsdl"), 
	'Net::SMS::Clickatell::SOAP',
	'new() with misspelled parameter' );

#########################

like( Net::SMS::Clickatell::SOAP->errorcode( '007'), qr/IP Lockdown violation/, "errorcode() as a function" );
like( $obj->errorcode( '007'), qr/IP Lockdown violation/, "errorcode() as a method" );
like( $obj->auth(), qr/$ERR: \d\d\d.+/, "auth with no credentials" );
ok( !defined( $obj->sessionid() ), "sessionid before authentication" );
like( $obj->ping(), qr/$ERR: \d\d\d.+/, "ping before authentication" );

#########################

done_testing;