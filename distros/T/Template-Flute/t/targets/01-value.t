#! perl
#

use strict;
use warnings;

use Test::More tests => 6;

use Template::Flute;

my ($spec_xml, $template, $flute, $output, $link_value, @link_descriptions);

$link_value = 'goto_url';
@link_descriptions = ('Here we go', 'and there as well');

# testing simple replacement
$spec_xml = <<'EOF';
<specification name="link">
<value name="link" target="href"/>
</specification>
EOF

$template = qq{<a href="#" class="link description">$link_descriptions[0]</a>};

$flute = Template::Flute->new(specification => $spec_xml,
							  template => $template,
							  values => {link => $link_value});

$output = $flute->process();

ok($output =~ m%href="$link_value"%, $output);
ok($output =~ m%>$link_descriptions[0]<%, $output);

# testing replacement of target and text inside the HTML tag

$spec_xml = <<'EOF';
<specification name="link">
<value name="link" target="href"/>
<value name="description"/>
</specification>
EOF

$flute = Template::Flute->new(specification => $spec_xml,
							  template => $template,
							  values => {link => $link_value,
										 description => $link_descriptions[1]});

$output = $flute->process();

ok($output =~ m%href="$link_value"%, $output);
ok($output =~ m%>$link_descriptions[1]<%, $output);

# now using the same class name
$spec_xml = <<'EOF';
<specification name="link">
<value name="link" target="href"/>
<value name="description" class="link"/>
</specification>
EOF

$template = qq{<a href="#" class="link">$link_descriptions[0]</a>};

$flute = Template::Flute->new(specification => $spec_xml,
							  template => $template,
							  values => {link => $link_value,
										 description => $link_descriptions[1]});

$output = $flute->process();

ok($output =~ m%href="$link_value"%, $output);
ok($output =~ m%>$link_descriptions[1]<%, $output);

