#!perl

use v5.10.1;
use strict;
use warnings FATAL => 'all';
use experimental qw(smartmatch);

use Test::More;
use File::Basename;

use Sport::Analytics::NHL::Tools;

use t::lib::Util;

test_env();
plan tests => 19;
$ENV{HOCKEYDB_DATA_DIR} = 't/data';
for my $id (193020010, 201120010) {
	my @game_files = get_game_files_by_id($id);
	if ($id =~ /^1930/) {
		is(scalar(@game_files), 1, 'just one JS file');
		is($game_files[0], "$ENV{HOCKEYDB_DATA_DIR}/1930/0002/0010/BS.json");
	}
	else {
		is(scalar(@game_files), 6, 'full set of six');
		for my $game_file (@game_files) {
			is(dirname($game_file), "$ENV{HOCKEYDB_DATA_DIR}/2011/0002/0010", "directory correct");
			like(basename($game_file), qr/^[A-Z]{2}\.(html|json)/, 'XX.yyyy file');
		}
	}
}

eval { vocabulary_lookup('xx', 'yy')};
like($@, qr/unknown word/i, 'exception in vocabulary caught');
is(vocabulary_lookup('strength', 'EV'), 'EV', 'vocabulary by key ok');
is(vocabulary_lookup('miss', 'OVER NET'), 'OVER', 'vocabulary single synonym ok');
is(vocabulary_lookup('penalty', 'ATTEMPT TO INJURE'), 'ATTEMPT TO/DELIBERATE INJURY - MATCH PENALTY', 'vocabulary multiple synonym ok');
