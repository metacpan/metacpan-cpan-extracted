#!/usr/bin/perl -w
#######################################################################################
#
# 2_helloworld.t
#
# Acceptance test for message encoding, based on .NET wsdl and example code.
# SOAP::WSDL's encoding doesn't I<exactly> match the .NET example, because 
# .NET doesn't always specify types (SOAP::WSDL does), and the namespace 
# prefixes chosen are different (maybe the encoding style, too ? this would be a bug !)
#
########################################################################################

use strict;
use Test::More tests => 4;
use lib '../../../lib/';
use File::Basename;
use File::Spec;

my $path = File::Spec->rel2abs( dirname __FILE__ );
my ($volume, $dir) = File::Spec->splitpath($path, 1);
my @dir_from = File::Spec->splitdir($dir);
unshift @dir_from, $volume if $volume;
my $url = join '/', @dir_from;

use_ok q/SOAP::WSDL/;

### test vars END
print "# Testing SOAP::WSDL ". $SOAP::WSDL::VERSION."\n";
print "# Acceptance test against sample output with simple WSDL\n";

my $data = {
    name => 'test',
    givenName => 'test',
};

my $soap = undef;

ok $soap = SOAP::WSDL->new(
    wsdl => 'file://'.$url.'/../../acceptance/wsdl/11_helloworld.wsdl',
    no_dispatch => 1
), 'Create SOAP::WSDL object'; 

# won't work without - would require SOAP::WSDL::Deserializer::SOM,
# which requires SOAP::Lite
$soap->outputxml(1);

$soap->proxy('http://helloworld/helloworld.asmx');

ok $soap->wsdlinit(
    servicename => 'Service1',
), 'wsdlinit';


ok $soap->call('sayHello', 'sayHello' => $data), 'soap call';
	
