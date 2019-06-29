#!perl

use v5.10.1;
use strict;
use warnings FATAL => 'all';

use Test::More;

use Sport::Analytics::NHL::Generator;
use Sport::Analytics::NHL::Vars qw($DB $CACHES $MONGO_DB);
use Sport::Analytics::NHL::Util qw(:debug);
use Sport::Analytics::NHL::Usage;
if ($ENV{HOCKEYDB_NODB} || ! $MONGO_DB) {
        plan skip_all => 'Mongo not defined';
        exit;
}
plan tests => 21;

use Sport::Analytics::NHL::DB;
#$ENV{HOCKEYDB_DEBUG} = 1;
$ENV{HOCKEYDB_DRYRUN} = 1;
$DB = Sport::Analytics::NHL::DB->new();

my $games_c = $DB->get_collection('games');
my $game = $games_c->find_one(
	{_id => 201830187}
);
my $generated = generate_game({icings_info => 1}, $game);
ok(ref $generated->{icings_info}, 'single option generated');
is(scalar(keys %{$generated}), 1, 'it is indeed single');
$generated = generate_game({all => 1}, $game);

my @options = @{$Sport::Analytics::NHL::Usage::OPTS{generator}};
for my $option (@options) {
	my $opt = $option->{long};
	next if $opt eq 'all';
	my $_opt = $opt;
	$_opt =~ s/\-/_/g;
	ok(ref $generated->{$_opt}, "$_opt generated");
}
$game = $games_c->find_one(
	{_id => 191820002}
);
$generated = generate_game({all => 1}, $game);
is($generated->{challenges}, undef, 'no challenges in 1918');
is($generated->{icings_info}, undef, 'no icings recorded in 1918');
is($generated->{offsides_info}, undef, 'no offsides recorded in 1918');
is($generated->{ne_goals}, undef, 'no NE goals recorded in 1918');
is_deeply($generated->{icecount_mark}, {}, 'no icecount available in 1918');
is(scalar(@{$generated->{fighting_majors}}), 0, 'no fighting majors in 1918');

