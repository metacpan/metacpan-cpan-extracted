use strict;
use warnings;

use Test::More;

use SQL::Composer::Quoter;

subtest 'quote simple column' => sub {
    my $quoter = SQL::Composer::Quoter->new();

    is $quoter->quote('foo'), '`foo`';
};

subtest 'quote with driver' => sub {
    my $quoter = SQL::Composer::Quoter->new(driver => 'Pg');

    is $quoter->quote('foo'), '"foo"';
};

subtest 'quote with prefix' => sub {
    my $quoter = SQL::Composer::Quoter->new();

    is $quoter->quote('foo', 'prefix'), '`prefix`.`foo`';
};

subtest 'not add prefix when already prefixed' => sub {
    my $quoter = SQL::Composer::Quoter->new();

    is $quoter->quote('prefixed.foo', 'prefix'), '`prefixed`.`foo`';
};

subtest 'quote column with table' => sub {
    my $quoter = SQL::Composer::Quoter->new();

    is $quoter->quote('table.foo'), '`table`.`foo`';
};

subtest 'quote column with custom quote char' => sub {
    my $quoter = SQL::Composer::Quoter->new(quote_char => '"');

    is $quoter->quote('table.foo'), '"table"."foo"';
};

subtest 'quote column with custom name separator' => sub {
    my $quoter =
      SQL::Composer::Quoter->new(quote_char => '"', name_separator => ':');

    is $quoter->quote('table:foo'), '"table":"foo"';
};

subtest 'split column with custom name separator' => sub {
    my $quoter =
      SQL::Composer::Quoter->new(quote_char => '"', name_separator => ':');

    is_deeply [$quoter->split('table:foo')], ['table', 'foo'];
};

subtest 'return only column' => sub {
    my $quoter =
      SQL::Composer::Quoter->new(quote_char => '"', name_separator => ':');

    is_deeply [$quoter->split('foo')], ['', 'foo'];
};

subtest 'quote string' => sub {
    my $quoter = SQL::Composer::Quoter->new();

    is $quoter->quote_string('foo'), q{'foo'};
};

subtest 'quote string with quotes' => sub {
    my $quoter = SQL::Composer::Quoter->new();

    is $quoter->quote_string(q{fo'o}), q{'fo\'o'};
};

done_testing;
