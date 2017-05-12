use strict;
use warnings;
use lib '../../../lib';
use Test::More tests => 4;
use SOAP::WSDL;
use File::Basename;
use File::Spec;

my $path = File::Spec->rel2abs( dirname __FILE__ );
my ($volume, $dir) = File::Spec->splitpath($path, 1);
my @dir_from = File::Spec->splitdir($dir);
unshift @dir_from, $volume if $volume;
my $url = join '/', @dir_from;

print "# Using SOAP::WSDL Version $SOAP::WSDL::VERSION\n";

# chdir to my location
my $soap = undef;

my $proxy = 'http://127.0.0.1/testPort';

ok( $soap = SOAP::WSDL->new(
	wsdl => 'file://' . $url . '/../../acceptance/wsdl/02_port.wsdl'
) );
ok $soap->servicename('testService');
ok $soap->portname('testPort');

ok $soap->wsdlinit( url => $proxy );
