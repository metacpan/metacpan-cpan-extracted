#

use strict;
use warnings;

use Test::More tests => 8;

use Template::Flute;

my ($spec_xml, $template, $flute, $output, $link_value, @link_descriptions);

$link_value = 'goto_url';
@link_descriptions = ('Here we go', 'and there as well');

# testing simple replacement
$spec_xml = <<'EOF';
<specification name="link">
<list name="links" class="linklist" iterator="links">
<param name="link" target="href"/>
</list>
</specification>
EOF

$template = qq{<html><div class="linklist"><a href="#" class="link description">$link_descriptions[0]</a></div></html>};

$flute = Template::Flute->new(specification => $spec_xml,
							  template => $template,
							  values => {links => [{link => $link_value}]});

$output = $flute->process();

ok($output =~ m%href="$link_value"%, $output);
ok($output =~ m%>$link_descriptions[0]<%, $output);

# testing replacement of target and text inside the HTML tag

$spec_xml = <<'EOF';
<specification name="link">
<list name="links" class="linklist" iterator="links">
<param name="link" target="href"/>
<param name="description"/>
</list>
</specification>
EOF

$flute = Template::Flute->new(specification => $spec_xml,
							  template => $template,
							  values => {links => [{link => $link_value,
													   description => $link_descriptions[1]}]});

$output = $flute->process();

ok($output =~ m%href="$link_value"%, $output);
ok($output =~ m%>$link_descriptions[1]<%, $output);

# now using the same class name
$spec_xml = <<'EOF';
<specification name="link">
<list name="links" class="linklist" iterator="links">
<param name="link" target="href"/>
<param name="description" class="link"/>
</list>
</specification>
EOF

$template = qq{<html><div class="linklist"><a href="#" class="link">$link_descriptions[0]</a></div></html>};


$flute = Template::Flute->new(specification => $spec_xml,
							  template => $template,
							  values => {links => [{link => $link_value,
													   description => $link_descriptions[1]}]});

$output = $flute->process();

ok($output =~ m%href="$link_value"%, $output);
ok($output =~ m%>$link_descriptions[1]<%, $output);

# op=append
$spec_xml = <<'EOF';
<specification name="link">
<list name="links" class="linklist" iterator="links">
<param name="link" target="href" op="append"/>
<param name="description" class="link"/>
</list>
</specification>
EOF

$template = qq{<html><div class="linklist"><a href="/" class="link">$link_descriptions[0]</a></div></html>};


$flute = Template::Flute->new(specification => $spec_xml,
							  template => $template,
							  values => {links => [{link => $link_value,
													   description => $link_descriptions[1]}]});

$output = $flute->process();

ok($output =~ m%href="/$link_value"%, $output);
ok($output =~ m%>$link_descriptions[1]<%, $output);
