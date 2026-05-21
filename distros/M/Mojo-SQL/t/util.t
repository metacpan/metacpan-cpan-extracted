use Mojo::Base -strict, -signatures;

use Test::More;

use Mojo::SQL qw(escape_identifier escape_literal);

subtest 'escape_identifier' => sub {
  is escape_identifier(''),                   '""',                    'empty string';
  is escape_identifier('0'),                  '"0"',                   'zero';
  is escape_identifier("Ain't misbehaving "), q{"Ain't misbehaving "}, 'apostrophe';
  is escape_identifier('NULL'),               '"NULL"',                'NULL';
  is escape_identifier('some"identifier'),    '"some""identifier"',    'embedded double quote';
  is escape_identifier(23),                   '"23"',                  'number';
};

subtest 'escape_literal' => sub {
  is escape_literal(''),                               "''",                                    'empty string';
  is escape_literal('0'),                              "'0'",                                   'zero';
  is escape_literal("Ain't misbehaving "),             "'Ain''t misbehaving '",                 'apostrophe';
  is escape_literal('NULL'),                           "'NULL'",                                'NULL';
  is escape_literal('some"identifier'),                q{'some"identifier'},                    'embedded double quote';
  is escape_literal(qq{backslash \\all' \the things}), qq{ E'backslash \\\\all'' \the things'}, 'backslash';
  is escape_literal(23),                               "'23'",                                  'number';
};

done_testing;
