use v5.32;
use warnings;
use utf8;

use Test2::V0;

use Term::Fabulous::Chart::Format qw(number_formatter time_formatter format_value decimals_of check_number_format check_time_format);

sub labels {
	my ( $format, $step, $largest, @values ) = @_;
	my $formatter = number_formatter( $format, $step, $largest );
	return [ map { $formatter->($_) } @values ];
}

subtest 'decimals_of' => sub {
	is [ map { decimals_of($_) } 0, 1, 250, 0.1, 0.25, 2.5, -0.05, 0.3 ], [ 0, 0, 0, 1, 2, 1, 2, 1 ], 'the decimals a number needs';
	is decimals_of(1e-12),                                                10,                         'at most 10';
};

subtest 'number_formatter' => sub {
	is labels( 'auto', 0.25, 2, 1.5, 0, -0.5 ),        [ '1.50', '0.00', '-0.50' ], 'auto: the decimals of the step';
	is labels( undef, 0.25, 2, 1 ),                    ['1.00'],                    'auto is the default';
	is labels( 'auto', 0.5, 1, -0.01 ),                ['0.0'],                     'no negative zero';
	is labels( 'auto', 5000, 40000, 25000, 0, 40000 ), [ '25k', '0', '40k' ],       'auto: SI prefixes from 10000 on';
	is labels( 'auto', 2500, 10000, 2500, 10000 ),     [ '2.5k', '10.0k' ],         'with the decimals the step needs in that unit';
	is labels( 'si', 0.5, 2, 1.5 ),                    ['1.5'],                     'si: small values without a prefix';
	is labels( 'si', 250000, 1e6, 750000, 1e6 ),       [ '750k', '1.00M' ],         'si: the largest prefix each value reaches';
	is labels( 'integer', 0.5, 3, 2.4, 2.6, -0.4 ),    [ '2', '3', '0' ],           'integer: rounded whole numbers';
	is labels( 'percent', 0.1, 1, 0.3, 1 ),            [ '30%', '100%' ],           'percent';
	is labels( 'percent', 0.025, 1, 0.125, 0.1 ),      [ '12.5%', '10.0%' ],        'percent with the decimals of the step';
	is labels( '%.1f C', 1, 1, 2 ),                    ['2.0 C'],                   'a sprintf format';
	my $code = sub { "<$_[0]>" };
	ref_is number_formatter( $code, 1, 1 ), $code, 'a code reference is the formatter';
};

subtest 'format_value' => sub {
	is [ map { format_value($_) } 1234.5678, 3.14159, 2.5, 2, 0.012345, 0, -0.0001, 1e-9 ], [ '1234.6', '3.14', '2.5', '2', '0.0123', '0', '-0.0001', '0' ],
		'up to two decimals, three significant digits below 1, no trailing zeros';
	is [ map { format_value($_) } 999999, 1.5e6, 2e6, 123e6, -2.5e9 ],                          [ '999999', '1.5M', '2M', '123M', '-2.5G' ], 'SI prefixes from a million on';
	is [ format_value( 1500, 'si' ), format_value( 999, 'si' ), format_value( 250000, 'si' ) ], [ '1.5k', '999', '250k' ],                   'si from a thousand on';
	is [ format_value( 0.05, 'percent' ), format_value( 0.25, 'percent' ) ],                    [ '5.0%', '25%' ],                           'percent';
	is format_value( 2.6, 'integer' ),                                                          '3',                                         'integer';
	is format_value( 3, '%d items' ),                                                           '3 items',                                   'a sprintf format';
	is format_value( 3, sub { "v$_[0]" } ),                                                     'v3',                                        'a code reference';
	is format_value(undef),                                                                     '',                                          'no value';
};

subtest 'time_formatter' => sub {
	is time_formatter( '%H:%M',          1 )->(0),          '00:00',            'a strftime format';
	is time_formatter( '%Y-%m-%d %H:%M', 1 )->(1780272000), '2026-06-01 00:00', 'in UTC';
	my $code = sub { 'then' };
	ref_is time_formatter( $code, 0 ), $code, 'a code reference is the formatter';
};

subtest 'checks' => sub {
	is [ map { check_number_format( 'Chart', 'format', $_ ) } qw(auto si integer percent %d) ], [qw(auto si integer percent %d)], 'number formats are returned';
	is check_number_format( 'Chart', 'format', undef ),                                         undef,                            'undef is no format';
	like dies { check_number_format( 'Chart', 'format', 'fancy' ) }, qr/\AChart: format must be auto, si, integer, percent, a sprintf format with one % conversion or a code reference, got 'fancy'/,
		'an unknown number format dies';
	like dies { check_number_format( 'Chart', 'format', [] ) }, qr/got ARRAY reference/, 'so does a reference';

	is check_time_format( 'Chart', 'format', '%H' ), '%H', 'a time format is returned';
	like dies { check_time_format( 'Chart', 'format', 'HH:MM' ) }, qr/\AChart: format must be a strftime format or a code reference, got 'HH:MM'/, 'a time format without % dies';
	like dies { check_time_format( 'Chart', 'format', {} ) },      qr/got HASH reference/,                                                         'so does a reference';
};

done_testing;
