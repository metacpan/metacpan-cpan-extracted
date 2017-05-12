# vim: filetype=perl :
use strict;
use warnings;

#use Test::More tests => 1; # last test to print
use Test::More 'no_plan';  # substitute with previous line when done

use lib 't';
use NAS3Test;
my $xml = NAS3Test::get_sample_acl();

my $module = 'Net::Amazon::S3::ACL::XMLHelper';
require_ok $module;
can_ok($module, 'xpc');

{
   my $xpc = $module->can('xpc')->($xml);
   isa_ok($xpc, 'XML::LibXML::XPathContext');
}

# pre-check and import
ok(! __PACKAGE__->can('xpc'), "current package initially can't xpc");
$module->import('xpc');
can_ok(__PACKAGE__, 'xpc');
{
   my $xpc = xpc($xml);
   isa_ok($xpc, 'XML::LibXML::XPathContext');
}
