use Test::More tests => 4;

use qbit;
use QBit::Validator;

ok(
    QBit::Validator->new(
        data     => undef,
        template => {
            type => 'palindrome',
        },
      )->has_errors,
    'Type "palindrome" and data undefined'
  );

ok(
    QBit::Validator->new(
        data     => [],
        template => {
            type => 'palindrome',
        },
      )->has_errors,
    'Type "palindrome" and data type "ARRAY"'
  );

ok(
    !QBit::Validator->new(
        data     => 'rotor',
        template => {
            type => 'palindrome',
        },
      )->has_errors,
    'Type "palindrome" (no error)'
  );

ok(
    QBit::Validator->new(
        data     => 'car',
        template => {
            type => 'palindrome',
        },
      )->has_errors,
    'Type "palindrome" (error)'
  );