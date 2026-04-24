use strict;
use Test::More 0.98;
use TOON::XS qw(encode_line_toon decode_line_toon validate_line_toon);
use JSON::PP;

# Test 1: Simple object encoding
{
    my $data = {
        id => 123,
        name => 'Alice',
        active => 1,
    };
    
    my $toon = encode_line_toon($data);
    ok($toon, 'encode() returns non-empty string');
    like($toon, qr/id:/, 'encoded TOON contains id key');
    like($toon, qr/name:/, 'encoded TOON contains name key');
}

# Test 2: Array of objects encoding
{
    my $data = {
        users => [
            { id => 1, name => 'Alice', role => 'admin' },
            { id => 2, name => 'Bob', role => 'user' }
        ]
    };
    
    my $toon = encode_line_toon($data);
    ok($toon, 'encode() with array of objects returns string');
    like($toon, qr/users\[2\]/, 'encoded TOON contains array header with length');
}

# Test 3: Simple object decoding
{
    my $toon_text = <<'TOON';
id: 123
name: Alice
active: true
TOON
    
    my $data = decode_line_toon($toon_text);
    ok($data, 'decode() returns data structure');
    is($data->{id}, 123, 'decoded id is correct');
    is($data->{name}, 'Alice', 'decoded name is correct');
}

# Test 4: Array decoding
{
    my $toon_text = <<'TOON';
users[2]{id,name,role}:
  1,Alice,admin
  2,Bob,user
TOON
    
    my $data = decode_line_toon($toon_text);
    ok($data, 'decode() with array returns data structure');
    is(ref $data->{users}, 'ARRAY', 'users is an array');
    is(scalar @{$data->{users}}, 2, 'users array has 2 elements');
}

done_testing;
