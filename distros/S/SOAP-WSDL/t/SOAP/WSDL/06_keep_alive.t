use Test::More tests => 6;
use strict;
use warnings;
use diagnostics;
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
    wsdl => 'file://' . $url . '/../../acceptance/wsdl/02_port.wsdl',
    keep_alive => 1,
), 'Instantiated object' );

ok( ($soap->servicename('testService')  ), 'set service' );
ok( ($soap->portname('testPort2')  ) ,'set portname');
ok( $soap->wsdlinit(), 'parsed WSDL' );

eval {
    $soap = SOAP::WSDL->new(
    	wsdl => 'file:///' . $path . '/../../acceptance/wsdl/FOOBAR',
    	keep_alive => 1,
    );
};
like $@, qr{ does \s not \s exist }x, 'error on non-existant WSDL';