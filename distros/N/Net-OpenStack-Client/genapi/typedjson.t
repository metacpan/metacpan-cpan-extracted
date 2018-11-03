use strict;
use warnings;

use Test::More;

use typedjson;


my $txt = '{"a":{"b":1,"c":true},"d":{"b":"what","e":[1,2]}}';
my $result = {
    a_b => {'path' => ['a', 'b'], 'type' => 'long'},
    c => {'path' => ['a', 'c'], 'type' => 'boolean'},
    d_b => {'path' => ['d', 'b'], 'type' => 'string'},
    d_e => {'islist' => 1, 'path' => ['d', 'e'], 'type' => 'long'},
};


my $parsed = typedjson::parse_json($txt);

#diag "parsed ",explain $parsed;
is_deeply($parsed, [$result->{a_b}, $result->{c}, $result->{d_b}, $result->{d_e}], "parse_json returns list of scalars");

my $options = process_json($txt, ['e']);
#diag "options ",explain $options;
is_deeply($options, $result, "generated options hashref");

done_testing();
