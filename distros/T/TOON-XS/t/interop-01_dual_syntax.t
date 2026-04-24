use strict;
use warnings;
use Test::More;

use TOON::XS qw(
    encode_line_toon
    encode_brace_toon
    decode_line_toon
    decode_brace_toon
);

my $line_text = <<'TOON';
users[2]{id,name,role}:
  1,Alice,admin
  2,Bob,user
TOON

my $brace_text = '{users: [{id: 1, name: "Alice", role: "admin"}, {id: 2, name: "Bob", role: "user"}]}';

my $line_data = decode_line_toon($line_text);
my $brace_data = decode_brace_toon($brace_text);
is_deeply($line_data, $brace_data, 'line and brace decoders produce same model');

my $input = {
    users => [
        { id => 1, name => 'Alice', role => 'admin' },
        { id => 2, name => 'Bob', role => 'user' },
    ],
};

my $encoded_line = encode_line_toon($input, column_priority => ['id', 'name', 'role']);
my $line_roundtrip = decode_line_toon($encoded_line);
is_deeply($line_roundtrip, $input, 'line encode round-trips through auto decode');

my $encoded_brace = encode_brace_toon($input, canonical => 1);
my $brace_roundtrip = decode_brace_toon($encoded_brace);
is_deeply($brace_roundtrip, $input, 'brace encode round-trips through auto decode');

my $brace_via_class = TOON::XS->new(syntax => 'brace', canonical => 1)->encode($input);
my $line_via_class = TOON::XS->new(syntax => 'line', column_priority => ['id', 'name', 'role'])->encode($input);

is_deeply(
    TOON::XS->new(syntax => 'brace')->decode($brace_via_class),
    TOON::XS->new(syntax => 'line')->decode($line_via_class),
    'class line and brace encoders interoperate through shared model'
);

done_testing();
