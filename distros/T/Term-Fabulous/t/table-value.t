use v5.32;
use warnings;
use utf8;

use POSIX ();

# Before anything reads the clock: Test2 seeds srand from the local date,
# and the C library of Windows, which has no tzset, settles the time zone
# at its first localtime.
BEGIN {
	$ENV{TZ} = 'UTC';
	POSIX::tzset() unless $^O eq 'MSWin32';
}

use Test2::V0;

use Term::Fabulous::Widget::Table::Value qw(is_blank number_of date_epoch date_interval compare_values natural_compare);
use Term::Fabulous::Widget::Table::Mutator qw(:all !number);    # Test2::V0 has a number of its own

my $DAY = 86400;

subtest 'numbers and blanks' => sub {
	is [ map { is_blank($_) } undef, '', 0, ' ' ],            [ 1, 1, 0, 0 ],                        'is_blank';
	is number_of('12.50'),                                    12.5,                                  'a number string';
	is [ map { number_of($_) } undef, '', 'n/a', 'inf', [] ], [ undef, undef, undef, undef, undef ], 'blank, words, infinity and references are no numbers';
};

subtest 'date intervals' => sub {
	my $may3 = 1714694400;    # 2024-05-03 00:00 UTC
	is date_interval('2024-05-03'),           [ $may3, $may3 + $DAY ], 'a day';
	is date_interval('2024-05'),              [ 1714521600, 1717200000 ], 'a month';
	is date_interval('2024'),                 [ 1704067200, 1735689600 ], 'a year';
	is date_interval('2024-12'),              [ 1733011200, 1735689600 ], 'December ends with the year';
	is date_interval('2024-05-03 14:30'),     [ $may3 + 52200, $may3 + 52260 ], 'a minute';
	is date_interval('2024-05-03T14:30:15Z'), [ $may3 + 52215, $may3 + 52216 ], 'a second in UTC';
	is date_interval('2024-02-29')->[1] - date_interval('2024-02-29')->[0],                  $DAY,            'a leap day exists';
	is [ map { date_interval($_) } '2023-02-29', '2024-13', '2024-05-03Z', 'May 3', undef ], [ (undef) x 5 ], 'no date, no interval';
};

subtest 'date values' => sub {
	is date_epoch(1714694400),               1714694400, 'epoch seconds stay';
	is date_epoch('2024-05-03'),             1714694400, 'a date string is its first second';
	is date_epoch( bless {}, 'My::Moment' ), 42,         'an object with an epoch method';
	is date_epoch('soon'),                   undef,      'anything else is no date';
};

subtest 'ordering' => sub {
	is compare_values( number => '10',         9 ),           1, 'numbers';
	is compare_values( date   => '2024-01-02', 1704067200 ),  1, 'dates of any form';
	is compare_values( string => 'apple',      'Banana' ),   -1, 'text is case-insensitive';
	is [ sort { natural_compare( $a, $b ) } qw(file10 File9 file1) ], [qw(file1 File9 file10)], 'natural order';
	like dies { compare_values( color => 1, 2 ) }, qr/unknown column type 'color'/, 'an unknown type dies';
};

subtest 'mutators' => sub {
	is datetime()->(1714746600),                                                                                                     '2024-05-03 14:30', 'datetime';
	is datetime( '%d.%m.%Y', utc => 1 )->('2024-05-03 14:30'),                                                                       '03.05.2024',       'datetime from a date string';
	is date()->(1714746600),                                                                                                         '2024-05-03',       'date';
	is Term::Fabulous::Widget::Table::Mutator::number()->(1234567.5),                                                                '1,234,567.5',      'number keeps its decimals';
	is Term::Fabulous::Widget::Table::Mutator::number( decimals => 2, separator => '.', point => ',', suffix => ' EUR' )->(-1234.5), '-1.234,50 EUR',    'number with options';
	is Term::Fabulous::Widget::Table::Mutator::number( decimals => 2 )->(-0.001),                                                    '0.00',             'no negative zero';
	is percent( decimals => 1 )->(0.1534),                                                                                           '15.3%',            'percent';
	is bytes()->(1536),                                                                                                              '1.5 KiB',          'bytes';
	is bytes( binary => 0, decimals => 0 )->(2_600_000),                                                                             '3 MB',             'decimal bytes';
	is bytes()->(512),                                                                                                               '512 B',            'small sizes are whole bytes';
	is duration()->(3725),                                                                                                           '1h 02m',           'duration';
	is duration( parts => 3 )->(-90061),                                                                                             '-1d 01h 01m',      'a negative duration';
	is boolean()->(0),                                                                                                               'no',               'boolean false';
	is boolean( "\x{2714}", '' )->(1),                                                                                               "\x{2714}",         'boolean with texts';
	is lookup( { r => 'running' }, default => '?' )->('x'),                                                                          '?',                'lookup default';
	is lookup( { r => 'running' } )->('z'),                                                                                          'z',                'lookup without default shows the value';
	is truncate(5)->('Hello world'),                                                                                                 "Hell\x{2026}",     'truncate';
	is truncate(5)->('日本語テキスト'),                                                                                                     "日本\x{2026}",       'truncate counts wide characters';
	is truncate(5)->('short'),                                                                                                       'short',            'short text stays';
	is sprintf_format('%05d')->(42),                                                                                                 '00042',            'sprintf_format';
	is chain( Term::Fabulous::Widget::Table::Mutator::number( decimals => 1 ), sub { "[$_[0]]" } )->(3),                             '[3.0]',            'chain';
	is [ map { $_->(undef) } datetime(), Term::Fabulous::Widget::Table::Mutator::number(), bytes(), duration(), truncate(3), sprintf_format('%d') ], [ ('') x 6 ], 'undef shows nothing';
	is Term::Fabulous::Widget::Table::Mutator::number()->('n/a'), 'n/a', 'a value that is not a number shows as it is';
	like dies { Term::Fabulous::Widget::Table::Mutator::number( digits => 2 ) }, qr/number does not accept digits \(known: decimals, point, prefix, separator, suffix\)/, 'unknown options die';
	like dies { truncate( 0, ellipsis => '...' ) },                              qr/truncate needs more columns than the ellipsis takes/,                                 'truncate checks its room';
};

done_testing;

package My::Moment;    ## no critic (Modules::RequireFilenameMatchesPackage) a stand-in date object
sub epoch { return 42 }
