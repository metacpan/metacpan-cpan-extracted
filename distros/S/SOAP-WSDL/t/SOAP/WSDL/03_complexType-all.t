use Test::More tests => 7;
use strict;
use warnings;
use lib '../lib';
use lib 't/lib';
use lib 'lib';
use File::Basename;
use File::Spec;
our $SKIP;
eval "use Test::SOAPMessage";
if ($@)
{
    $SKIP = "Test::Differences required for testing. ";
}

my $path = File::Spec->rel2abs( dirname __FILE__ );
my ($volume, $dir) = File::Spec->splitpath($path, 1);
my @dir_from = File::Spec->splitdir($dir);
unshift @dir_from, $volume if $volume;
my $url = join '/', @dir_from;

# print $url;

use_ok(qw/SOAP::WSDL/);

print "# SOAP::WSDL Version: $SOAP::WSDL::VERSION\n";

my $xml;
my $soap;

#2
ok( $soap = SOAP::WSDL->new(
	wsdl => 'file://' . $url . '/../../acceptance/wsdl/03_complexType-all.wsdl',
), 'Instantiated object' );

#3
ok $soap->wsdlinit( 
    checkoccurs => 1,
    servicename => 'testService', 
), 'parse WSDL';
ok $soap->no_dispatch(1), 'set no dispatch';

# won't work without - would require SOAP::WSDL::Deserializer::SOM,
# which requires SOAP::Lite
$soap->outputxml(1);

ok ($xml = $soap->call('test',  
			testAll => {
				Test1 => 'Test 1',
				Test2 => [ 'Test 2', 'Test 3' ]
			}
), 'Serialized complexType' );


# print $xml;

# $soap->wsdl_checkoccurs(1);

TODO: {
  local $TODO = "not implemented yet";

eval 
{ 
	$xml = $soap->call('test', 
			testAll => {
				Test1 => 'Test 1',
				Test2 => [ 'Test 2', 'Test 3' ]
			}
		);
};

ok( ($@ =~m/illegal\snumber\sof\selements/),
	"Died on illegal number of elements (too many)"
);

eval {
	$xml = $soap->call('test', 
			testAll => {
				Test1 => 'Test 1',
			}
		);
};
ok($@, 'Died on illegal number of elements (not enough)');

}