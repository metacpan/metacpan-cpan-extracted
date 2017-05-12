use Test::More tests => 8;
use strict;
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

my ($soap, $xml, $xml2);

#2
ok( $soap = SOAP::WSDL->new(
    wsdl => 'file://' . $url . '/../../acceptance/wsdl/05_simpleType-list.wsdl'
), 'Instantiated object' );

# won't work without - would require SOAP::WSDL::Deserializer::SOM,
# which requires SOAP::Lite
$soap->outputxml(1);

#3
ok( $soap->wsdlinit(
    servicename => 'testService',
), 'parsed WSDL' );
$soap->no_dispatch(1);

#4
ok $xml = $soap->call('test', testAll => [ 1, 2 ] ), 'Serialize list call';

#5
ok ( $xml2 = $soap->call('test', testAll => "1 2" ) , 'Serialized scalar call' );
#6
ok( $xml eq $xml2, 'Got expected result');

#7	
TODO: {
    local $TODO = "implement minLength check";
    eval { $xml = $soap->call('test', testAll => undef ) };
    ok($@, 'Died on illegal number of elements (not enough)');
}

#8
TODO: {
    local $TODO = "maxLength test not implemented";
    eval { $xml = $soap->call('test', testAll => [ 1, 2, 3, 4, 5, 6, 7, 8, 9, 0 ] ) };
	ok($@, 'Died on illegal number of elements (more than maxLength)');	
}
