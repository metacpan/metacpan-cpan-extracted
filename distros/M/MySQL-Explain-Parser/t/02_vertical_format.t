use strict;
use warnings;
use utf8;
use MySQL::Explain::Parser qw/parse_vertical/;
use Test::More;
use Test::Deep;

subtest 'not contains multi-byte characters' => sub {
    my $explain = <<'...';
*************************** 1. row ***************************
           id: 1
  select_type: PRIMARY
        table: t1
         type: index
possible_keys: NULL
          key: PRIMARY
      key_len: 4
          ref: NULL
         rows: 4
     filtered: 100.00
        Extra:
*************************** 2. row ***************************
           id: 2
  select_type: SUBQUERY
        table: t2
         type: index
possible_keys: a
          key: a
      key_len: 5
          ref: NULL
         rows: 3
     filtered: 100.00
        Extra: Using index
...

    my $expected = [
        {
            id            => 1,
            select_type   => 'PRIMARY',
            table         => 't1',
            type          => 'index',
            possible_keys => undef,
            key           => 'PRIMARY',
            key_len       => 4,
            ref           => undef,
            rows          => 4,
            filtered      => "100.00",
            Extra         => '',
        },
        {
            id            => 2,
            select_type   => 'SUBQUERY',
            table         => 't2',
            type          => 'index',
            possible_keys => 'a',
            key           => 'a',
            key_len       => 5,
            ref           => undef,
            rows          => 3,
            filtered      => "100.00",
            Extra         => 'Using index',
        },
    ];

    subtest 'basic case' => sub {
        my $parsed = parse_vertical($explain);
        cmp_deeply($parsed, $expected);
    };

    subtest 'should pass if tail of description exists' => sub {
        my $parsed = parse_vertical($explain . "2 rows in set, 1 warning (0.00 sec)");
        cmp_deeply($parsed, $expected);
    };

    subtest 'should pass if blank lines are on both ends' => sub {
        my $parsed = parse_vertical("\n" . $explain . "\n");
        cmp_deeply($parsed, $expected);
    };
};

subtest 'should pass when explain contains multi-byte characters' => sub {
    my $explain = <<'...';
*************************** 1. row ***************************
           id: 1
  select_type: SIMPLE
        table: てすつ
         type: index
possible_keys: NULL
          key: ほげ
      key_len: 4
          ref: NULL
         rows: 5
        Extra: Using index
...

    my $expected = [
        {
            id            => 1,
            select_type   => 'SIMPLE',
            table         => 'てすつ',
            type          => 'index',
            possible_keys => undef,
            key           => 'ほげ',
            key_len       => 4,
            ref           => undef,
            rows          => 5,
            Extra         => 'Using index',
        },
    ];

    my $parsed = parse_vertical($explain);
    cmp_deeply($parsed, $expected);
};

done_testing;

