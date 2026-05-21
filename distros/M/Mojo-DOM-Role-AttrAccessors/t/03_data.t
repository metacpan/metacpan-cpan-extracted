use strict;
use warnings;
use Test::More;
use Mojo::DOM;
use Mojo::JSON qw(encode_json decode_json);

my $dom = Mojo::DOM->with_roles('+AttrAccessors')
                   ->new('<a href="https://example.com">Example</a>')
                   ->at('a');

# plain string inbound/outbound
$dom->data('label', 'hello');
is $dom->data('label'), 'hello', 'plain string round-trips';

# reference inbound -> JSON stored, hashref outbound
$dom->data('config', { foo => 1, bar => 2 });
is_deeply $dom->data('config'), { foo => 1, bar => 2 }, 'hashref round-trips';

# arrayref
$dom->data('items', [1, 2, 3]);
is_deeply $dom->data('items'), [1, 2, 3], 'arrayref round-trips';

# raw JSON already in the attribute comes back as ref
$dom->attr('data-raw' => encode_json({ pre => 'encoded' }));
is_deeply $dom->data('raw'), { pre => 'encoded' }, 'pre-encoded JSON attribute decoded outbound';

# plain string attribute not touched by JSON logic
$dom->attr('data-plain' => 'just a string');
is $dom->data('plain'), 'just a string', 'plain string attribute returned as-is';

# undef for missing attribute
is $dom->data('nonexistent'), undef, 'missing attribute returns undef';

# invalid JSON returns raw string
$dom->attr('data-broken' => 'not { json }');
is $dom->data('broken'), 'not { json }', 'invalid JSON returned as raw string';

# bare JSON scalar ("42") returns raw string, not the number
$dom->attr('data-num' => '42');
is $dom->data('num'), '42', 'bare JSON scalar returned as plain string';

done_testing;
