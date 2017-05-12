#! perl
#
# Test for passing specification and/or template from string

use strict;
use warnings;

use Test::More tests => 3;

use File::Basename;
use Template::Flute;

my ($xml, $html, $flute, $spec, $template, $output);

$flute = Template::Flute->new(specification_file => dirname(__FILE__) . '/files/test.xml', 
							  template_file => dirname(__FILE__) . '/files/test.html',
							  values => {email => 'racke@linuxia.de'});
$flute->process();

$spec = $flute->specification();

isa_ok($spec, 'Template::Flute::Specification');

$template = $flute->template();

isa_ok($template, 'Template::Flute::HTML');

$output = $flute->process({email => 'racke@linuxia.de'});

ok($output =~ m%>racke\@linuxia.de<%, $output);
