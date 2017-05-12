#
# Test for the code added to the POD introduction

use strict;
use warnings;
use Test::More tests => 2;

use Template::Flute;

my ($html, $xml, $html_object, $spec_object, $spec, $flute);
	
$html = <<'EOF';
<html>
    <div class="customer_name">Mr A Test</div>
    <div class="customer_email">someone@example.com</div>
</html>
EOF

$xml = <<'EOF';
   <specification name="example" description="Example">
        <value name="customer_name" />
        <value name="customer_email" field="email" />
    </specification>
EOF

$spec_object = new Template::Flute::Specification::XML;

$spec = $spec_object->parse($xml);

$html_object = new Template::Flute::HTML;

$html_object->parse($html, $spec);

$flute = Template::Flute->new(template => $html_object,
							  specification => $spec,
							 );

$flute->set_values({ customer_name => 'Bob McTest',
					 email => 'bob@example.com',
				   });;

my $ret = $flute->process;

ok($ret =~ m%<div class="customer_name">Bob McTest</div>%, $ret);
ok($ret =~ m%<div class="customer_email">bob\@example.com</div>%, $ret);
