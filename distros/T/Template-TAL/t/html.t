#!perl
use warnings;
use strict;
use Data::Dumper;
use Test::More tests => 4;
use FindBin qw($Bin);
use Test::XML;

use Template::TAL;

ok( my $tt = Template::TAL->new( include_path => $Bin, output => "Template::TAL::Output::HTML" ), "got TT object");

isa_ok( $tt->provider, "Template::TAL::Provider::Disk", "TT provider" );

ok( my $output = $tt->process(\(<<'END_OF_TEMPLATE')), "processed");
<html>
<p>Test of HTML output</p>
<br />
<img src="foo"/>
</html>
END_OF_TEMPLATE

is($output, <<'END_OF_EXPECTED');
<html>
<p>Test of HTML output</p>
<br>
<img src="foo">
</html>
END_OF_EXPECTED
