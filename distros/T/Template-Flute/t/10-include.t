#! perl
#
# Test for include feature

use strict;
use warnings;

use Test::More tests => 3;

use Template::Flute;

my ($xml, $html, $flute, $spec, $template, $output);

$xml = <<'EOF';
<specification name="test" description="test">
<value name="component" include="t/files/component.html"/>
</specification>
EOF

$html = <<'EOF';
<div class="component"></div>
EOF

$flute = Template::Flute->new(specification => $xml, template => $html);
$spec = $flute->specification();

isa_ok($spec, 'Template::Flute::Specification');

$template = $flute->template();

isa_ok($template, 'Template::Flute::HTML');

$flute->set_values({title => 'Include'});

$output = $flute->process();

ok($output =~ m%>Include<%, $output);
