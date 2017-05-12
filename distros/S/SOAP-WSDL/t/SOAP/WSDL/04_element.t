use Test::More tests => 9;
use strict;
use warnings;
use lib '../lib';
use lib 't/lib';
use File::Spec;
use File::Basename;

our $SKIP;
eval "use Test::SOAPMessage";
if ($@) {
    $SKIP = "Test::Differences required for testing.";
}

use_ok(qw/SOAP::WSDL/);

my $soap;
my $xml;
my $path = File::Spec->rel2abs( dirname __FILE__ );
my ($volume, $dir) = File::Spec->splitpath($path, 1);
my @dir_from = File::Spec->splitdir($dir);
unshift @dir_from, $volume if $volume;
my $url = join '/', @dir_from;

#2
ok( $soap = SOAP::WSDL->new(
	wsdl => 'file://' . $url . '/../../acceptance/wsdl/04_element.wsdl'
), 'Instantiated object' );

#3
SKIP: {
    skip 'Cannot test warning without Test::Warn', 1 if not (eval "require Test::Warn");
    Test::Warn::warning_like( sub { $soap->readable(1) },
        qr{\A 'readable' \s has \s no \s effect \s any \s more}xms);
}
$soap->outputxml(1);

ok( $soap->wsdlinit(
    servicename => 'testService',
), 'parsed WSDL' );
$soap->no_dispatch(1);

ok ($xml = $soap->call('test',
	testElement1 => 'Test'
), 'Serialized (simple) element' );

ok ($xml = $soap->call('testRef',
	testElementRef => 'Test'
), 'Serialized (simple) element' );

like $xml
    , qr{<testElementRef\s\sxmlns="urn:Test">Test</testElementRef></SOAP-ENV:Body></SOAP-ENV:Envelope>}
    , 'element ref serialization result'
;

TODO: {
    local $TODO="implement min/maxOccurs checks";

    eval {
	$xml = 	$soap->call('test',
			testAll => [ 'Test 2', 'Test 3' ]
		);
    };

    ok( ($@ =~m/illegal\snumber\sof\selements/),
	"Died on illegal number of elements (too many)"
    );

    eval {
	$xml = $soap->call('test', testAll => undef );
    };
    ok($@, 'Died on illegal number of elements (not enough)');
}

