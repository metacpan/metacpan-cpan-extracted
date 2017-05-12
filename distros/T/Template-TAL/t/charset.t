#!perl
use warnings;
use strict;
use Data::Dumper;
use Test::More tests => 11;
use FindBin qw($Bin);
use Test::XML;
use Encode;

use Template::TAL;

my $data = {
  e1 => "\x{e9}",
  e2 => "<p>\x{e9}</p>",
};

my $template = Encode::encode_utf8(<<"END_TEMPLATE");
<?xml version="1" encoding="utf-8"?>
<div xmlns:tal="http://xml.zope.org/namespaces/tal">
  <p>\x{e9}</p>
  <p tal:content="e1"/>
  <p tal:replace="structure e2"/>
</div>
END_TEMPLATE

my $expected = <<"END_EXPECTED";
<div>
  <p>&#233;</p>
  <p>&#233;</p>
  <p>&#233;</p>
</div>
END_EXPECTED

for my $charset (qw( utf-8 iso-8859-1 iso-8859-2)) {

  ok( my $tt = Template::TAL->new(
    output => "Template::TAL::Output::XML",
    charset => $charset,
  ), "got TT object for $charset");

  my $output = $tt->process(\$template, $data);
  ok( $output =~ /$charset/, "output contains charset" );
  is_xml($output, $expected, "xml for $charset") or warn $output,$expected;
}

ok( my $tt = Template::TAL->new(
  output => "Template::TAL::Output::XML",
  charset => "ASCII",
), "got TT object for XML / ASCII output");

my $output = $tt->process(\$template, $data);

like( $output, qr/&#233;/, "ascii encoded");

