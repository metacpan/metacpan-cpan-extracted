use strict;
use Test::More 0.98;
use TOON::XS qw(encode_line_toon decode_line_toon validate_line_toon);

# Test 1: Valid simple object
{
    my $toon_text = <<'TOON';
id: 123
name: Alice
TOON
    
    my $is_valid = validate_line_toon($toon_text);
    ok($is_valid, 'simple object is valid');
}

# Test 2: Valid array
{
    my $toon_text = <<'TOON';
tags[3]: admin,ops,dev
TOON
    
    my $is_valid = validate_line_toon($toon_text);
    ok($is_valid, 'primitive array is valid');
}

# Test 3: Valid tabular array
{
    my $toon_text = <<'TOON';
items[2]{sku,qty,price}:
  A1,2,9.99
  B2,1,14.5
TOON
    
    my $is_valid = validate_line_toon($toon_text);
    ok($is_valid, 'tabular array is valid');
}

done_testing;
