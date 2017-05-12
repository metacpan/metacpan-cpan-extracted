#!perl
use warnings;
use strict;
use Data::Dumper;
use Test::More tests => 4;
use FindBin qw($Bin);
use Test::XML;

use Template::TAL;

ok( my $tt = Template::TAL->new( include_path => $Bin ), "got TT object");
ok( $tt->add_language("Template::TAL::Language::PerlValue"), "loaded PerlValue language");

ok( my $output = $tt->process(\(<<'END_OF_TEMPLATE'), { text => 5 }), "processed");
<html xmlns:tal="http://xml.zope.org/namespaces/tal">
<p tal:content="perl: 'one plus two is ' . (1+2) ">Test of HTML output</p>
</html>
END_OF_TEMPLATE

is_xml($output, <<'END_OF_EXPECTED');
<html>
<p>one plus two is 3</p>
</html>
END_OF_EXPECTED
