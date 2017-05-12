#! perl -T

use strict;
use warnings;

use Test::More tests => 2;

use Cwd;
use File::Basename;

use Template::Flute;
use Template::Flute::Specification::XML;
use Template::Flute::HTML;
use Template::Flute::Style::CSS;

my $xml = <<EOF;
<specification name="csstest">
</specification>
EOF

my $dir = dirname(__FILE__);

my $html = qq{<link rel="stylesheet" type="text/css" href="/files/simple.css">
<div class="example">
Example
</div>
};

# parse XML specification
my ($spec, $ret);

$spec = new Template::Flute::Specification::XML;

$ret = $spec->parse($xml);

# parse HTML template
my ($html_object);

$html_object = new Template::Flute::HTML;

$html_object->parse($html, $ret);

# CSS object
my ($css, $props);

$css = Template::Flute::Style::CSS->new(template => $html_object,
										prepend_directory => dirname(__FILE__));

isa_ok($css, 'Template::Flute::Style::CSS');

$props = $css->properties(class => 'example');

ok($props->{float} eq 'left');
