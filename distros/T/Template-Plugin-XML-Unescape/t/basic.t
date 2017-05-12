use Template;
use Test::More tests => 1;

use warnings;
use strict;

my $template = <<TEMPLATE;
[% USE XML::Unescape; "&apos;" | xml_unescape %]
[% USE XML::Unescape 'bargle'; '&amp;' | bargle %]
TEMPLATE
my $toolkit = Template->new;
$toolkit->process(\$template, {}, \my $out)
    or die $toolkit->error;

is $out, "'\n&\n", 'unescaped an apostrophe and ampersand';
