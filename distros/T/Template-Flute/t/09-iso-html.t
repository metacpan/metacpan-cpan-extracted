#! perl
#
# Test for HTML files with ISO-8859-1 content

use strict;
use warnings;

use Test::More tests => 3;

use File::Basename;
use Template::Flute;
use Template::Flute::Specification::XML;
use Template::Flute::HTML;

# parse XML specification
my ($spec, $ret);

$spec = new Template::Flute::Specification::XML;

$ret = $spec->parse_file(dirname(__FILE__) . '/files/iso.xml');

isa_ok($ret, 'Template::Flute::Specification');

# check whether encoding was read correctly
ok($ret->encoding() eq 'iso8859-1');

# parse HTML template
my ($html_object);

$html_object = new Template::Flute::HTML;

eval {
	$html_object->parse_file(dirname(__FILE__) . '/files/iso.html', $ret);
};

if ($@) {
	fail("Crashed while parsing HTML: $@");
}
else {
	pass("Parsing HTML was successful.");
}


