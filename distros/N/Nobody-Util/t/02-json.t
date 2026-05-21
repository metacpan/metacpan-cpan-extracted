use strict;
use warnings;
use Test::More;
use lib 't/lib', 'lib';

use_ok('Nobody::JSON');
eval "use Nobody::JSON qw(encode_json decode_json)";
can_ok('Nobody::JSON', qw(encode_json decode_json));

my $data = { key => "value", list => [1, 2, 3] };
my $json = encode_json($data);

# JSON::XS pretty-prints with spaces around colon: "key" : "value"
like($json, qr/"key"\s*:\s*"value"/, 'encode_json: key/value present');
like($json, qr/"list"\s*:\s*\[/,     'encode_json: list key present');
like($json, qr/\n/,                  'encode_json: output is multi-line (pretty)');

my $decoded = decode_json($json);
is_deeply($decoded, $data, 'decode_json: round-trip successful');

# Aliases
can_ok('Nobody::JSON', qw(json_encode json_decode));

done_testing();
