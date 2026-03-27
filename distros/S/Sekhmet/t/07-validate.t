use strict;
use warnings;
use Test::More tests => 20;
use Sekhmet qw(ulid ulid_validate);

# Valid ULIDs
is(ulid_validate(ulid()), 1, 'Generated ULID validates');
is(ulid_validate("01AN4Z07BY79KA1307SR9X4MV3"), 1, 'Known ULID validates');
is(ulid_validate("00000000000000000000000000"), 1, 'Zero ULID validates');
is(ulid_validate("7ZZZZZZZZZZZZZZZZZZZZZZZZZ"), 1, 'Max ULID validates');

# Case insensitive — lowercase should also validate
is(ulid_validate("01an4z07by79ka1307sr9x4mv3"), 1, 'Lowercase ULID validates');

# Invalid: wrong length
is(ulid_validate(""), 0, 'Empty string fails');
is(ulid_validate("01AN4Z07BY"), 0, 'Too short fails');
is(ulid_validate("01AN4Z07BY79KA1307SR9X4MV3X"), 0, 'Too long fails');

# Invalid: bad characters
is(ulid_validate("01AN4Z07BY79KA1307SR9X4MVI"), 0, 'Contains I - invalid');
is(ulid_validate("01AN4Z07BY79KA1307SR9X4MVL"), 0, 'Contains L - invalid');
is(ulid_validate("01AN4Z07BY79KA1307SR9X4MVO"), 0, 'Contains O - invalid');
is(ulid_validate("01AN4Z07BY79KA1307SR9X4MVU"), 0, 'Contains U - invalid');

# Invalid: first char > 7 (overflow)
is(ulid_validate("8ZZZZZZZZZZZZZZZZZZZZZZZZZ"), 0, 'First char 8 fails (overflow)');
is(ulid_validate("9ZZZZZZZZZZZZZZZZZZZZZZZZZ"), 0, 'First char 9 fails');

# Invalid: special characters
is(ulid_validate("01AN4Z07BY79KA1307SR9X4MV!"), 0, 'Contains ! fails');
is(ulid_validate("01AN4Z07BY79KA1307SR9X4MV-"), 0, 'Contains - fails');
is(ulid_validate("01AN4Z07BY79KA1307SR9X4MV "), 0, 'Contains space fails');

# Valid edge: all zeros
is(ulid_validate("00000000000000000000000000"), 1, 'All zeros is valid');

# Valid edge: first char 7
is(ulid_validate("70000000000000000000000000"), 1, 'First char 7 is valid');

# Multiple generated ULIDs all validate
my $all_valid = 1;
for (1..100) {
    unless (ulid_validate(ulid())) {
        $all_valid = 0;
        last;
    }
}
ok($all_valid, '100 generated ULIDs all validate');
