use Test::More tests => 10;
use strict;
use warnings;
use diagnostics;
use Cwd;
use lib '../lib';

use File::Basename;
use File::Spec;

my $path = File::Spec->rel2abs( dirname __FILE__ );
my ($volume, $dir) = File::Spec->splitpath($path, 1);
my @dir_from = File::Spec->splitdir($dir);
unshift @dir_from, $volume if $volume;
my $url = join '/', @dir_from;

use_ok(qw/SOAP::WSDL/);

my $soap;
#2
ok( $soap = SOAP::WSDL->new(
	wsdl => 'file://' . $url . '/../../acceptance/wsdl/02_port.wsdl'
), 'Instantiated object' );

ok( ($soap->servicename('testService')  ), 'set service' );
ok( ($soap->portname('testPort2')  ) ,'set portname');
ok( $soap->wsdlinit(), 'parsed WSDL' );

ok( $soap->wsdlinit( servicename => 'testService', portname => 'testPort'), 'parsed WSDL' );

ok( ($soap->portname() eq 'testPort' ), 'found port passed to wsdlinit');

ok( $soap = SOAP::WSDL->new(
    wsdl => 'file://' . $url . '/../../acceptance/wsdl/02_port.wsdl'
), 'Instantiated object' );

ok( $soap->wsdlinit() );
$soap->outputxml(1);
eval { $soap->call('test') };
like $@, qr{type \s tns:testSimpleType1 \s , \s urn:simpleType \s not \s found}xms;