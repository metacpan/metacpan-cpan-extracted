#!/usr/bin/env perl

use Test::Most tests => 2;

use Renard::Incunabula::Common::Setup;
use Renard::API::MuPDF::mutool::DateObject;

subtest "Date parsing" => sub {
	my @tests = (
		{
			input => "D:20061118211043-02'30'",
			output => {
				data => {
					year => '2006', month => '11', day => '18',
					hour => '21', minute => '10', second => '43',
					tz => {
						offset => '-',
						hour => '02', minute => '30',
					},
				},
				string => '2006-11-18T21:10:43-02:30',
			}
		}
	);


	plan tests => 0+@tests;

	for my $test (@tests) {
		subtest $test->{input} => sub {
			my $date = Renard::API::MuPDF::mutool::DateObject->new(
				string => $test->{input}
			);
			is_deeply( $date->data, $test->{output}{data}, 'correct data' );
			is( $date, $test->{output}{string}, 'correct string' );
		};
	}
};

subtest "as DateTime" => sub {
	eval { require DateTime; 1 } or plan skip_all => 'DateTime not loaded';

	my $date_string_base = "D:20061118211043";
	my $datetime_base = '2006-11-18T21:10:43';

	my @tz_data_tests = (
		{
			note => 'no timezone',
			input => "",
			output => { tz => 'floating' },
		},
		{
			note => 'Z timezone',
			input => "Z",
			output => { tz => 'UTC' },
		},
		{
			note => 'negative timezone',
			input => "-02'30'",
			output => { tz => '-0230' },
		},
		{
			note => 'positive timezone',
			input => "+02'30'",
			output => { tz => '+0230' },
		},
	);

	plan tests => 0 + @tz_data_tests;

	for my $tz (@tz_data_tests) {
		subtest $tz->{note} => sub {
			my $dt = Renard::API::MuPDF::mutool::DateObject->new(
				string => $date_string_base . $tz->{input}
			)->as_DateTime;
			is( $dt, $datetime_base, 'DateTime string correct' );
			is( $dt->time_zone->short_name_for_datetime,
				$tz->{output}{tz},
				'time zone correct' );

		};
	}

};

done_testing;
