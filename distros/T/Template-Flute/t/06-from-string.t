#! perl
#
# Test for passing specification and/or template from string

use strict;
use warnings;

use Test::More tests => 3;

use Template::Flute;

my ($xml, $html, $flute, $spec, $template, $output);

$xml = <<'EOF';
<specification name="test" description="test">
<value name="email"/>
</specification>
EOF

$html = <<'EOF';
<span class="email"></span>
EOF

$flute = Template::Flute->new(specification => $xml, template => $html);
$spec = $flute->specification();

isa_ok($spec, 'Template::Flute::Specification');

$template = $flute->template();

isa_ok($template, 'Template::Flute::HTML');

$flute->set_values({email => 'racke@linuxia.de'});

$output = $flute->process();

ok($output =~ m%>racke\@linuxia.de<%, $output);
