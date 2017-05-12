use Test::More tests => 8;
use strict;
use warnings;
use diagnostics;
use File::Spec;
use File::Basename;
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

my $soap;
#2
ok( $soap = SOAP::WSDL->new(
    wsdl => 'file://' . $url . '/../../acceptance/wsdl/05_simpleType-restriction.wsdl'
), 'Instantiated object' );

#3
ok( $soap->wsdlinit(
    servicename => 'testService',
), 'parsed WSDL' );
$soap->no_dispatch(1);
$soap->autotype(0);
# won't work without - would require SOAP::WSDL::Deserializer::SOM,
# which requires SOAP::Lite
$soap->outputxml(1);

#4
ok $xml = $soap->call('test', testAll => [ 1, 2 ] ) , 'Serialize list call';

# print $xml, "\n";

TODO: {
  local $TODO = "implement minLength/maxLength checks";
  eval { $soap->call('test', testAll => [ 1, 2, 3 ] ) };
  ok($@, 'Died on illegal number of elements (too many)');	
	
  eval { $soap->call('test', testAll => [] ) };
  ok($@, 'Died on illegal number of elements (not enough)');
}

TODO: {
    local $TODO = "minValue check not implemented ";
    eval { $xml = $soap->call('test', testAll => 0 ) };
    ok($@, 'Died on illegal value');
}

TODO: {
    local $TODO =  "maxValue check not implemented ";
    eval { $xml = $soap->call('test', testAll => 100 ) };
    ok($@, 'Died on illegal value');
}
