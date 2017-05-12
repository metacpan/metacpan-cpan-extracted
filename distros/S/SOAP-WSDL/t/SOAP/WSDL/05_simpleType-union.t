use Test::More skip_all => 'Not supported yet';
use strict;
use warnings;
use File::Spec;
use File::Basename;

use_ok qw/SOAP::WSDL/;

my $xml;
my $soap = undef;
my $path = File::Spec->rel2abs( dirname __FILE__ );

#2
ok $soap = SOAP::WSDL->new(
	wsdl => 'file:///' . $path . '/t/acceptance/wsdl/05_simpleType-union.wsdl'
), 'Instantiated object';

#3
ok $soap->wsdlinit(), 'parsed WSDL';
$soap->no_dispatch(1);
# won't work without - would require SOAP::WSDL::Deserializer::SOM,
# which requires SOAP::Lite
$soap->outputxml(1);

#4
ok $xml = $soap->call('test', testAll => 1 ) , 'Serialized call';

# 6
eval {
		$xml = $soap->serializer->method( 
			$soap->call('test', 
				testAll => [ 1 , 'union']
			) 
		)
};
ok($@, 'Died on illegal number of elements (not enough)');	
	
eval {
		$xml = $soap->serializer->method( 
			$soap->call('test', 
				testAll => undef
			) 
		)
};
ok($@, 'Died on illegal number of elements (not enough)');

#8
ok ( $xml = $soap->serializer->method( $soap->call('test2', 
						testAll => 1 ) 
			),
	'Serialized (simple) call (list)' );

#9
eval {
		$xml = $soap->serializer->method( 
			$soap->call('test', 
				testAll => [ 1 , 'union']
			) 
		)
};
ok($@, 'Died on illegal number of elements (not enough)');	
