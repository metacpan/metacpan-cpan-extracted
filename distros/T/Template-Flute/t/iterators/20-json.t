#! perl
#
# Testing JSON iterator.

use strict;
use warnings;
use Test::More;

eval "use JSON";

if ($@) {
	plan skip_all => "No JSON module.";
}

require Template::Flute::Iterator::JSON;

plan tests => 6;

my ($json, $json_iter);

$json = q{[
{"sku": "orange", "image": "orange.jpg"},
{"sku": "pomelo", "image": "pomelo.jpg"}
]};

# JSON string as is
$json_iter = Template::Flute::Iterator::JSON->new($json);

isa_ok($json_iter, 'Template::Flute::Iterator');

ok($json_iter->count == 2);

isa_ok($json_iter->next, 'HASH');

# JSON string as scalar
$json_iter = Template::Flute::Iterator::JSON->new(\$json);

isa_ok($json_iter, 'Template::Flute::Iterator');

ok($json_iter->count == 2);

isa_ok($json_iter->next, 'HASH');