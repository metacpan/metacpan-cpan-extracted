use Test::More tests => 6; 
use strict;
use warnings;
use lib '../lib';
use lib 't/lib';

use File::Basename;
use File::Spec;

my $path = File::Spec->rel2abs( dirname __FILE__ );
my ($volume, $dir) = File::Spec->splitpath($path, 1);
my @dir_from = File::Spec->splitdir($dir);
unshift @dir_from, $volume if $volume;
my $url = join '/', @dir_from;

use_ok(qw/SOAP::WSDL/);

my $xml;

my $soap = undef;

ok( $soap = SOAP::WSDL->new(
	wsdl => 'file://' . $url . '/../../acceptance/wsdl/04_element-simpleType.wsdl'
), 'Instantiated object' );

# won't work without - would require SOAP::WSDL::Deserializer::SOM,
# which requires SOAP::Lite
$soap->outputxml(1);

ok( $soap->wsdlinit(
    servicename => 'testService',
), 'parsed WSDL' );
$soap->no_dispatch(1);

ok ( $xml = $soap->call('test', testElement1 => 1 ) ,
	'Serialized (simpler) element' );

	
TODO: {
    local $TODO="implement min/maxOccurs checks";
    
    eval { $soap->call('test', testAll => [ 2, 3 ] ); };
	
    like $@, qr{illegal\snumber\sof\selements}, "Died on illegal number of elements (too many)";
    
    eval { $soap->call('test', testAll => undef ) };
    ok $@, 'Died on illegal number of elements (not enough)';
}

