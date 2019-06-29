#!perl

use v5.10.1;
use strict;
use warnings FATAL => 'all';
use experimental qw(smartmatch);

use Test::More;

use Sport::Analytics::NHL::PenaltyAnalyzer;
use Sport::Analytics::NHL::Vars qw($DB $MONGO_DB);
use Sport::Analytics::NHL::DB;
use Sport::Analytics::NHL::Test;
use Sport::Analytics::NHL::Tools qw(get_catalog_map);

if ($ENV{HOCKEYDB_NODB} || ! $MONGO_DB) {
        plan skip_all => 'Mongo not defined';
        exit;
}

plan tests => 20;

$DB = Sport::Analytics::NHL::DB->new();
my $PENL_c = $DB->get_collection('PENL');
my $penalties = get_catalog_map('penalties');
my $PENL_i = $PENL_c->find({
	game_id => 201720010,
});
my $penls = [];
my $gross_misconduct = $penalties->{'GROSS MISCONDUCT'};
while (my $penl = $PENL_i->next()) {
	ok(!Sport::Analytics::NHL::PenaltyAnalyzer::is_major_penalty($penl, $penalties), 'not a major');
	Sport::Analytics::NHL::PenaltyAnalyzer::check_gross_misconduct($penl, $gross_misconduct, $penls);
	is(scalar(@{$penls}), 0, 'not a gross misconduct');
}
