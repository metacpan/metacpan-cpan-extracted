use Parse::Range qw(parse_range);

print parse_range('1-7,^(2,4)'), $/;

print parse_range('^(2,4),1-7'), $/;

print parse_range('1-9,^(5-9,^(8-9))'), $/;