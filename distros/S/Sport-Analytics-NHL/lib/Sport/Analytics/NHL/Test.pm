package Sport::Analytics::NHL::Test;

use v5.10.1;
use strict;
use warnings FATAL => 'all';
use experimental qw(smartmatch);

use parent 'Exporter';

use Carp;
use Data::Dumper;
use Storable;

use List::MoreUtils qw(uniq);

use Sport::Analytics::NHL::Config qw(:all);
use Sport::Analytics::NHL::Vars qw(:test $IS_AUTHOR);
use Sport::Analytics::NHL::Util qw(:debug);
use Sport::Analytics::NHL::Tools qw(:parser :path);
use Sport::Analytics::NHL::Errors;

=head1 NAME

Sport::Analytics::NHL::Test - Utilities to test NHL reports data.

=head1 SYNOPSYS

Utilities to test NHL report data

 These are utilities that test and validate the data contained in the NHL reports to detect errors. They are also used to test and validate the permutations that are performed by this software on the data.
 Ideally, that method should extend Test::More, but first, I was too lazy to figure out how to do it, and second, I notice that in the huge number of tests that are run, Test::More begins to drag things down.

    use Sport::Analytics::NHL::Test;
    test_team_id('SJS') # pass
    test_team_id('S.J') # fail and die (usually)

 The failures are usually bad enough to force the death of the program and an update to Sport::Analytics::NHL::Errors (q.v.), but see the next section

=head1 GLOBAL VARIABLES

 The behaviour of the tests is controlled by several global variables:
 * $TEST_COUNTER - contains the number of the current test in Curr_Test field and the number of passes/fails in Test_Results.
 * $DO_NOT_DIE - when set to 1, failed test will not die.
 * $MESSAGE - the latest failure message
 * $TEST_ERRORS - accumulation of errors by type (event, player, boxscore, team)

=head1 FUNCTIONS

=over 2

=item C<my_die>

Either dies with a stack trace dump, or aggregates the error messages, based on $DO_NOT_DIE
 Arguments: the death message
 Returns: void

=item C<my_test>

Executes a test subroutine and sets the failure message in case of failure. Updates test counters.
 Arguments: the test subroutine and its arguments
 Returns: void

=item C<my_like>

Approximately the same as Test::More::like()

=item C<my_is>

Approximately the same as Test::More::is()

=item C<my_ok>

Approximately the same as Test::More::ok()

=item C<my_is_one_of>

Approximately the same as grep {$_[0] == $_} $_[1]

=item C<test_season>

For the test_* functions below the second argument is always the notification message. Sometimes third parameter may be passed. This one tests if the season is one between $FIRST_SEASON (from Sports::Analytics::NHL::Config) and $CURRENT_SEASON (from Sports::Analytics::NHL::LocalConfig)

=item C<test_stage>

Tests if the stage is either Regular (2) or Playoff (3)

=item C<test_season_id>

Tests the season Id to be between 1 and 1500 (supposedly maximum number of games per reg. season)

=item C<test_game_id>

Tests the game Id to be of the SSSSTIIII form. In case optional parameter is_nhl, tests for the NHL id SSSSTTIIII

=item C<test_team_code>

Tests if the string is a three-letter team code, not necessarily the normalized one.

=item C<test_team_id>

Tests if the string is a three-letter franchise code, as specified in keys of Sports::Analytics::NHL::Config::TEAMS

=item C<test_ts>

Tests the timestamp to be an integer (negative for pre-1970 games) number.

=item C<test_game_date>

Tests the game date to be in YYYYMMDD format.

=item C<is_unapplicable>

Check if the particular stat is measured in season being processed, stored in $THIS_SEASON

=item C<set_tested_stats>

Set the stats tested for a player

=item C<test_assists_and_servedby>

Tests the correct values in assists and servedby fields

=item C<test_boxscore>

Overall sequence to test the entire boxscore

=item C<test_coords>

Tests the event coordinates

=item C<test_decision>

Tests the decision for the goaltender being one of W,L,O,T

=item C<test_event>

Overall sequence to test the event

=item C<test_event_by_type>

Route the particular event testing according to its type

=item C<test_event_coords>

Checks the applicability of coordinates for the event and tests them

=item C<test_event_description>

Tests the event's description (for existence, actually)

=item C<test_event_strength>

Checks the applicability of strength setting for the event and tests it

=item C<test_events>

Test the boxscore's events (loops over test_event (q.v.))

=item C<test_goal>

Tests the goal event

=item C<test_header>

Tests the header information of the boxscore

=item C<test_name>

Tests the player's name (to have a space between two words, more or less)

=item C<test_officials>

Tests the officials definition in the boxscore

=item C<test_penalty>

Tests the penalty event

=item C<test_periods>

Tests the periods' reports from the boxscore

=item C<test_player>

Tests a player entry in the team's roster

=item C<test_player1>

Tests valid population of the player1 event field

=item C<test_player2>

Tests valid population of the player2 event field

=item C<test_player_id>

Tests the player id to be the valid 7-digit one one starting with 8

=item C<test_position>

Tests the position of the player to be one of C L R F D G

=item C<test_strength>

Tests the event's strength to be one of EV, SH, PP, PS or XX (unknown)

=item C<test_team_header>

Tests "header" information for a team: shots, score, coach etc.

=item C<test_teams>

Tests teams that played in the game

=item C<test_time>

Tests the time to be of format M{1,3}:SS

=item C<test_merged_boxscore>

Tests the boxscore after it was merged with other files (e.g. via Sport::Analytics::NHL::Merger). Test options are set according to the types of reports that have been merged ($boxscore->{sources})

=item C<test_merged_events>

Tests the events of the merged boxscore

=item C<test_merged_header>

Tests the header of the merged boxscore

=item C<test_merged_teams>

Tests the teams of the merged boxscore

=item C<my_cmp_ok>

Approximately the same as Test::More::cmp_ok()

=item C<test_arranged_events>

Tests that the normalized events have been arranged correctly

=item C<test_consistency>

Tests the consistency between the event summary and the boxscore

=item C<test_consistency_goalie>

Tests the consistency between the goaltender data and the event summary

=item C<test_consistency_penalty_minutes>

Tests the consistency between the penalty minutes of the players in the boxscore and in the event summary

=item C<test_consistency_playergoals>

Tests the consistency between the goals scored in the events and the goals in the boxscore teams/players

=item C<test_consistency_skater>

Tests the consistency between the skater data and the event summary

=item C<test_normalized_boxscore>

Full test of the normalized boxscore

=item C<test_normalized_events>

Tests the normalized boxscore events

=item C<test_normalized_header>

Tests the normalized boxscore's header

=item C<test_normalized_roster>

Tests the normalized roster of a team

=item C<test_normalized_teams>

Tests the normalized boxscore's teams

=item C<test_bio>

Tests the player's bio and draft data retrieved from the NHL website

=item C<test_career>

Tests the player's career data retrieved from the NHL website and amended with the preserved errata.

=item C<test_player_report>

Calls test_bio() and test_career() to test the player report from the NHL website. Executes presence, syntactic and sanity value checks.

=back

=cut

our $TEST_COUNTER = {Curr_Test => 0, Test_Results => []};

our @EXPORT = qw(
	my_like my_ok my_is
	test_game_id test_team_id test_team_code
	test_stage test_season test_season_id
	test_ts test_game_date
	test_header test_periods test_officials test_teams test_events
	test_boxscore test_merged_boxscore
	test_consistency test_normalized_boxscore
	test_player_report
	$TEST_COUNTER
	$EVENT $BOXSCORE $PLAYER $TEAM
);

our $DO_NOT_DIE = 0;
our $TEST_ERRORS = {};
our $MESSAGE = '';
our $THIS_SEASON;

our $EVENT;
our $BOXSCORE;
our $PLAYER;

$Data::Dumper::Trailingcomma = 1;
$Data::Dumper::Deepcopy      = 1;
$Data::Dumper::Sortkeys      = 1;
$Data::Dumper::Deparse       = 1;

sub my_die ($) {

	my $message = shift;
	if ($DO_NOT_DIE) {
		my $field;
		my $object;
		if ($EVENT) {
			$field = 'events';
			$object = $EVENT;
		}
		elsif ($PLAYER) {
			$field = 'players';
			$object = $PLAYER;
		}
		else {
			$field = 'boxscore';
			$object = $BOXSCORE;
		}
		$TEST_ERRORS->{$field} ||= [];
		push(
			@{$TEST_ERRORS->{$field}},
			{
				_id => $object->{_id} || $object->{event_idx} || $object->{number},
				message => $MESSAGE,
			}
		);
		return;
	}
	$message .= "\n" unless $message =~ /\n$/;
	my $c = 0;
	my $offset = '';
	while (my @caller = caller($c++)) {
		$message .= sprintf(
			"%sCalled in %s::%s, line %d in %s\n",
			$offset, $caller[0], $caller[3], $caller[2], $caller[1]
		);
		$offset .= '  ';
	}
	die $message;
}

sub my_test ($@) {

	my $test = shift;
	$TEST_COUNTER->{Curr_Test}++;
	no warnings 'uninitialized';
	if (@_ == 2) {
		$MESSAGE = "Failed $_[-1]: $_[0]";
	}
	else {
		if (ref $_[1] && ref $_[1] eq 'ARRAY') {
			my $arg1 = join('/', @{$_[1]});
			$MESSAGE = "Failed $_[-1]: $_[0] vs $arg1\n";
		}
		else {
			$MESSAGE = "Failed $_[-1]: $_[0] vs $_[1]\n";
		}
	}
	if ($test->(@_)) {
		$TEST_COUNTER->{Test_Results}[0]++;
	}
	else {
		$TEST_COUNTER->{Test_Results}[1]++;
		my_die($MESSAGE);
	}
	use warnings FATAL => 'all';
	debug "ok_$TEST_COUNTER->{Curr_Test} - $_[-1]" if $IS_AUTHOR && $0 =~ /\.t$/;
}

sub my_like ($$$) { my_test(sub { no warnings 'uninitialized'; $_[0] =~ $_[1]  }, @_) }
sub my_is   ($$$) { my_test(sub { no warnings 'uninitialized'; $_[0] eq $_[1]  }, @_) }
sub my_ok   ($$)  { my_test(sub { no warnings 'uninitialized'; $_[0]           }, @_) }
sub my_is_one_of ($$$) { my_test(sub { no warnings 'uninitialized'; grep { $_[0] ==  $_ } @{$_[1]}}, @_) }

sub my_cmp_ok ($$$$) {
	my ($got, $type, $expect, $message) = @_;
	my $test;
	eval qq{
\$test = (\$got $type \$expect);
1;
};
	my_die($@) if $@;
	my_ok($test, $message);
}


sub test_season ($$) {
	my $season  = shift;
	my $message = shift;
	my_ok($season >= $FIRST_SEASON, $message); my_ok($season <= $CURRENT_SEASON, $message);
	$THIS_SEASON = $season;
}

sub test_stage ($$) {
	my $stage   = shift;
	my $message = shift;
	my_ok($stage >= $REGULAR, 'stage ok'); my_ok($stage <= $PLAYOFF, $message);
}

sub test_season_id ($$) {
	my $id      = shift;
	my $message = shift;
	my_ok($id > 0, $message); my_ok($id < 1500, $message);
}

sub test_game_id ($$;$) {
	my $id      = shift;
	my $message = shift;
	my $is_nhl  = shift || 0;

	$is_nhl
		? $id =~ /^(\d{4})(\d{2})(\d{4})$/
		: $id =~ /^(\d{4})(\d{1})(\d{4})$/;
	test_season($1, $message);
	test_stage($2, $message);
	test_season_id($3, $message);
}

sub test_team_code ($$) {
	my_like(shift, qr/^\w{3}$/, shift .' tri letter code a team');
}

sub test_team_id ($$)   { test_team_code($_[0],$_[1]) && my_ok($TEAMS{$_[0]}, "$_[0] team defined")};
sub test_ts ($$)        { my_like(shift, qr/^-?\d+$/, shift) }
sub test_game_date ($$) { my_like(shift, qr/^\d{8}$/,  shift) }

sub is_unapplicable ($) {
	my $data = shift;

	$THIS_SEASON < (
		$DATA_BY_SEASON{$data}->{season} ||
		$STAT_RECORD_FROM{$data} || $data
	) || $EVENT && $EVENT->{time} eq '00:00' && $EVENT->{period} < 2;
};

sub test_header ($) {

	my $bs = shift;

	test_season(   $bs->{season},    'header season ok');
	test_stage(    $bs->{stage},     'header stage ok');
	test_season_id($bs->{season_id}, 'header season id ok');
	test_game_id(  $bs->{_id},       'header game id ok');

	my_is($bs->{status}, 'FINAL', 'only final games');
	my_ok($bs->{location}, 'location set') unless is_unapplicable('location');

	my_like($bs->{ot}, qr/^0|1$/, 'OT detected')
		if @{$bs->{periods}} > 3;
	my_like($bs->{so}, qr/^0|1$/, 'SO detected')
		if @{$bs->{periods}} > 4 && $bs->{stage} == $REGULAR;
	if ($bs->{so} && ref $bs->{shootout}) {
		for my $team (qw(away home)) {
			for my $stat (qw(attempts scores)) {
				my_like($bs->{shootout}{$team}{$stat}, qr/^\d+$/, 'shootout stat ok');
			}
		}
	}
}

sub test_officials ($;$) {

	my $officials = shift;
	return 1; # for now

	for my $o (qw(referees linesmen)) {
		for my $of (@{$officials->{$o}}) {
			my_ok($of->{name}, 'name set');
		}
	}
}

sub test_name      ($$) { my_like(shift, qr/\w|\.\s+\w/,           shift.' first and last name')   ; }
sub test_player_id ($$) { my_like(shift, qr/^8\d{6}$/,             shift.' valid player id')       ; }
sub test_time      ($$) { my_like(shift, qr/^\-?\d{1,3}:\d{1,2}$/, shift.' valid time')            ; }
sub test_position  ($$) { my_like(shift, qr/^(C|R|W|F|D|L|G)$/,      shift.' valid pos defined')     ; }
sub test_decision  ($$) { my_like(shift, qr/^W|L|O|T|N$/,            shift.' valid decision')        ; }
sub test_strength  ($$) { my_like(shift, qr/^EV|SH|PP|PS|XX$/,     shift.' valid strength')        ; }

sub test_periods ($) {

	my $periods = shift;

	for my $p (0..4) {
		my $period = $periods->[$p];
		next if ! $period && $p > 2;
		my_is($period->{id}, $p+1, 'period id ok');
		my_like($period->{type}, qr/^REGULAR|OVERTIME$/, 'period time ok');
		my_is(scalar(@{$period->{score}}), 4, '4 items in score');
		for my $gssg (@{$period->{score}}) {
			my_like($gssg, qr/^\d+$/, 'gssg in period a number');
		}
	}
}

sub test_coords ($) {

	my $coords = shift;

	return if scalar keys %{$coords} < 2;
	my_is(scalar(keys %{$coords}), 2, '2 coords');

	for my $coord (keys %{$coords}) {
		my_like($coord, qr/^x|y$/, 'coord x or y');
		my_like($coords->{$coord}, qr/^\-?\d+$/, 'event coord ok');
	}
}

sub test_team_header ($;$) {

	my $team = shift;
	my $opts = shift || {};

	test_team_code($team->{name},  'team name ok')
		unless $opts->{es} || $opts->{gs} || $opts->{ro};
	test_name(     $team->{coach}, 'team coach ok')
		unless $opts->{es} || $opts->{gs} || $opts->{ti};
	my_like($team->{shots}, qr/^\d{1,2}$/, 'shots a number') if $opts->{bs};
	my_like($team->{score}, qr/^1?\d$/, 'goals < 20');
	my_like($team->{pull},  qr/^1|0$/, 'goalie either pulled or not') if $opts->{bs};
	for my $scratch (@{$team->{scratches}}) {
		$opts->{ro} ?
			test_name($scratch->{name}, 'scratch name ok in ro') :
			test_player_id($scratch, 'scratch id ok');
	}
}

sub set_tested_stats ($$) {

	my $player = shift;
	my $opts   = shift || {};

	my @stats;
	return () if $player->{missing};
	if ($opts->{gs}) {
		@stats = $player->{old} ?
			qw(timeOnIce shots saves goals) :
			qw(timeOnIce number powerPlayTimeOnIce shortHandedTimeOnIce evenTimeOnIce shots saves goals);
	}
	elsif ($opts->{ro}) {
		@stats = qw(number start);
	}
	elsif ($opts->{es}) {

	}
	else {
		@stats = $player->{position} eq 'G' ?
			qw(pim evenShotsAgainst shots timeOnIce shortHandedShotsAgainst assists shortHandedSaves powerPlayShotsAgainst powerPlaySaves evenSaves number saves goals) :
			qw(penaltyMinutes shortHandedAssists goals evenTimeOnIce takeaways blocked assists hits powerPlayTimeOnIce plusMinus powerPlayGoals giveaways faceoffTaken faceOffWins shortHandedGoals powerPlayAssists number timeOnIce shots shortHandedTimeOnIce);
		$stats[0] = 'penaltyMinutes' if $opts->{merged};
	}
	@stats;
}

sub test_player ($;$) {

	my $player = shift;
	my $opts   = shift || {};

	my @stats = set_tested_stats($player, $opts);
#	dumper $player;
	test_position($player->{position}, 'roster position ok');
	return if $player->{_id} && $BROKEN_PLAYERS{BS}{$BOXSCORE->{_id}} && $BROKEN_PLAYERS{BS}{$BOXSCORE->{_id}}->{$player->{_id}} && $BROKEN_PLAYERS{BS}{$BOXSCORE->{_id}}->{$player->{_id}}{_notest};
	for my $stat (@stats) {
		next if is_unapplicable($STAT_RECORD_FROM{$stat})
			|| $player->{position} eq 'G' && ($opts->{es} || ! $player->{timeOnIce});
		if (! defined $player->{$stat}) {dumper $stat, $player;exit;}
		$stat =~ /timeonice/i ?
			$player->{toi_converted} || $opts->{es} || $opts->{gs} || $BROKEN_PLAYERS{BS}{$BOXSCORE->{_id}} && $BROKEN_PLAYERS{BS}{$BOXSCORE->{_id}}->{$player->{_id}} && $BROKEN_PLAYERS{BS}{$BOXSCORE->{_id}}->{$player->{_id}}{number} ?
				my_like($player->{$stat}, qr/^\d{1,5}$/, "ES $stat ok") :
				test_time($player->{$stat}, "$stat timeonice ok") :
			my_like($player->{$stat}, qr/\-?\d{1,2}/, "stat $stat an integer");
	}
	test_name($player->{name}, 'player name ok');
	test_player_id($player->{_id}, 'roster id ok')
		unless $opts->{es} || $opts->{gs} || $opts->{ro};

}

sub test_teams ($;$) {

	my $teams = shift;
	my $opts  = shift || {};

	for my $team (@{$teams}) {
		test_team_header($team, $opts);
		my $decision = '';
		my $broken = 0;
		for my $player (@{$team->{roster}}) {
			next if $player->{_id} && $player->{_id} =~ /^80/;
			$PLAYER = $player;
			if ($player->{broken}) {
				$broken = 1;
				next;
			}
			test_player($player, $opts);
			if (! $decision) {
				$decision = $player->{decision};
			}
			elsif ($player->{decision}) {
				die "Cannot have two decisions";
			}
			undef $PLAYER;
		}
		test_decision($decision, 'game decision ok')
			unless $broken
			|| $BOXSCORE->{_gs_no_g}
			|| $opts->{es} || $opts->{ro} || $opts->{ti};
		$team->{decision} = $decision if $opts->{merged};
	}
	undef $PLAYER;
}

sub test_event_strength ($$$) {

	my $event   = shift;
	my $opts    = shift;
	my $message = shift;

	test_strength($event->{strength}, $message)
		if $event->{type} eq 'GOAL' || $opts->{merged} && (
			!$BROKEN_TIMES{$BOXSCORE->{_id}}
				&& $event->{type} ne 'CHL'
				&& !($event->{type} eq 'PENL' && ! $event->{sources}{PL})
				&& ($event->{type} eq 'GOAL' || $BOXSCORE->{sources}{PL}
				&& ! is_noplay_event($event))
				&& !($event->{type} eq 'MISS' && ! $event->{sources}{PL})
		);
}

sub test_event_coords ($) {
	my $event = shift;

	test_coords($event->{coordinates})
		if !is_unapplicable('coordinates')
			&& !is_noplay_event($event)
			&& !($event->{penalty})
			&& !($BROKEN_COORDS{$BOXSCORE->{_id}});
}

sub test_event_description ($) {
	my $event = shift;

	my_like($event->{description}, qr/\w/, 'event description exists')
		if $BOXSCORE->{sources}{BS}
			&& !$BROKEN_FILES{$BOXSCORE->{_id}}->{BS}
			|| $BOXSCORE->{sources}{PL};
}

sub test_assists_and_servedby ($$) {
	my $event = shift;
	my $opts  = shift || {};

	if ($event->{servedby}) {
		$opts->{pl} ?
			my_like($event->{player1}, qr/^(\d{1,2}|80\d{5})$/, 'pl player1 number ok') :
			test_player_id($event->{servedby}, 'servedby player id ok');
	}
	if ($event->{assists} && @{$event->{assists}}) {
		for my $assist (@{$event->{assists}}) {
			$opts->{pl} ?
				my_like($event->{player1}, qr/^(\d{1,2}|80\d{5})$/, 'pl assist number ok') :
				test_player_id($assist, 'assist id ok');
		}
	}
}

sub test_player1 ($$) {
	my $event = shift;
	my $opts  = shift;

	if (($opts->{gs} && ! $event->{old}) || $opts->{pl}) {
		my_like($event->{player1}, qr/^(\d{1,2}|80\d{5})$/, 'gs pl player1 number ok');
	}
	else {
		$DO_NOT_DIE = 1;
		test_player_id($event->{player1}, 'event player1 ok')
			unless $opts->{gs}
				|| ($event->{type} eq 'PENL'
				&& ($event->{time} eq '20:00'
				|| $PENALTY_POSSIBLE_NO_OFFENDED{$event->{penalty}})
			);
		$DO_NOT_DIE = 0;
	}
}

sub test_player2 ($$) {
	my $event = shift;
	my $opts  = shift;

	test_player_id($event->{player2}, 'event player2 ok')
		unless ($event->{type} eq 'GOAL' && $event->{en})
			|| ($event->{type} eq 'GOAL' && $opts->{bh} || $opts->{gs} || $opts->{pl})
			|| ($opts->{merged} && ! $event->{sources}{BS} && $event->{type} eq 'GOAL')
			|| ($event->{time} eq '0:00' && $event->{type} ne 'FAC');
}

sub test_goal ($$) {
	my $event = shift;
	my $opts  = shift;

	unless (
		$opts->{pb} || $opts->{pl} || $event->{so}
		|| $BROKEN_FILES{BS}->{$BOXSCORE->{_id}} && $BROKEN_FILES{BS}->{$BOXSCORE->{_id}} == $NO_EVENTS
	) {
		my_like($event->{en}, qr/^0|1$/, 'en definition') if $event->{sources}{BS} || $event->{sources}{GS};
		my_like($event->{gwg}, qr/^0|1$/, 'gwg definition')
			if $opts->{bs};
	}
}

sub test_penalty ($$) {
	my $event = shift;
	my $opts  = shift;
	unless ($opts->{pb}) {
		my_like(
			$event->{severity},
			qr/^major|misconduct|minor|game|match|double|shot$/i, 'severity defined'
		) unless ! defined $event->{severity} || is_unapplicable('severity')
			|| $opts->{bh}
			|| $opts->{gs}
			|| $opts->{pl}
			|| !$event->{length}
			|| $BROKEN_FILES{BS}->{$BOXSCORE->{_id}} && $BROKEN_FILES{BS}->{$BOXSCORE->{_id}} == $NO_EVENTS;
		my_ok($VOCABULARY{penalty}->{$event->{penalty}}, "$event->{penalty} Good penalty type");
		my_like($event->{length}, qr/^0|2|3|4|5|10$/, 'length defined');
	}
}

sub test_event_by_type ($$) {
	my $event = shift;
	my $opts  = shift;

	my_ok($VOCABULARY{events}->{$event->{type}}, "$event->{type} Good event type");
	my_ok($VOCABULARY{strength}->{$event->{strength}}, 'Good event strength')
		if exists $event->{strength};
	for ($event->{type}) {
		when ([ qw(FAC HIT BLOCK GOAL SHOT PENL MISS GIVE TAKE) ]) {
			test_player1($event, $opts);
			continue;
		}
		when ([ qw(FAC HIT BLOCK GOAL) ]) {
			test_player2($event, $opts);
			continue;
		}
		when ('STOP') {
			my_is(ref $event->{stopreason}, 'ARRAY', 'stopreason is array');
			for my $reason (@{$event->{stopreason}}) {
				my_ok(
					$VOCABULARY{stopreason}->{$reason},
					"$reason there is a good reason to stop",
				);
			}
			continue;
		}
		when ([ qw(GOAL SHOT) ]) {
			my_ok(
				$VOCABULARY{shot_type}->{$event->{shot_type}},
				"$event->{shot_type} shot type normalized",
			);
			continue;
		}
		when ([ qw(GOAL) ]) {
			test_goal($event, $opts);
			continue;
		}
		when ([ qw(MISS) ]) {
			my_ok(
				$VOCABULARY{miss}->{$event->{miss}},
				'miss type normalized',
			);
			my_like($event->{description}, qr/\w/, 'miss needs description')
				unless $event->{penaltyshot};
			continue;
		}
		when ([ qw(PENL) ]) {
			test_penalty($event, $opts);
			continue;
		}
	}

}

sub test_event ($;$) {

	my $event = shift;
	my $opts  = shift || {};

	$EVENT = $event;
	my_like($event->{period}, qr/^\d$/, 'event period ok');
	test_time($event->{time}, 'event time ok');
	test_event_strength($event, $opts, "event $event->{type}/$event->{time}");
	test_event_coords($event);
	test_event_description($event);
	my_ok($VOCABULARY{events}->{$event->{type}}, 'valid type');
	test_assists_and_servedby($event, $opts);
	test_event_by_type($event, $opts);
	undef $EVENT;
}

sub test_events ($;$) {

	my $events = shift;
	my $opts   = shift || {};

	my $event_n = scalar @{$events};

	my_ok($event_n >= $REASONABLE_EVENTS{
		$BOXSCORE->{season} < 2010 ? 'old' : 'new'
	}, " $BOXSCORE->{_id} enough events($event_n) read")
		unless
		$ZERO_EVENT_GAMES{$BOXSCORE->{_id}} ||
		($BROKEN_FILES{$BOXSCORE->{_id}}{BS} && $BROKEN_FILES{$BOXSCORE->{_id}}{BS} == $NO_EVENTS) &&
		(!$BOXSCORE->{sources}{GS} && !$BOXSCORE->{sources}{PL})
			|| $opts->{bh} || $opts->{gs};
	for my $event (@{$events}) {
		test_event($event, $opts);
	}
	undef $EVENT;
}

sub test_boxscore ($;$) {

	my $boxscore = shift;
	my $opts     = shift || {bs => 0};

	$BOXSCORE = $boxscore;
	test_header($boxscore);
	test_periods($boxscore->{periods}) if $opts->{bs};
	test_officials($boxscore->{officials}, $opts)
		if ! $opts->{es} && ! $opts->{pl} && $boxscore->{season} >= $DATA_BY_SEASON{officials}->{season};
	test_teams($boxscore->{teams}, $opts)
		if ! $opts->{pl} && ! $opts->{tv} && ! $opts->{th};
	test_events($boxscore->{events}, $opts) unless
		$BROKEN_FILES{BS}->{$BOXSCORE->{_id}} && $BROKEN_FILES{BS}->{$BOXSCORE->{_id}} == $NO_EVENTS || $opts->{es} || $opts->{ro} || $opts->{tv} || $opts->{th} || $opts->{ti};
	undef $BOXSCORE;
	undef $PLAYER;
	undef $EVENT;
}

sub test_merged_header ($) {

	my $bs = shift;
	test_header($bs);

	my_like($bs->{attendance}, qr/^\d+$/, 'attendance set')
		if $BOXSCORE->has_html() || ! is_unapplicable('attendance');
	my_like($bs->{tz}, qr/^\w{1,2}T$/, 'tz ok') if $bs->has_html();
	my_like($bs->{month}, qr/^(0|1)?\d?/, 'month ok');
}

sub test_merged_teams ($) {

	my $teams = shift;
	my $opts = {merged => 1};
	test_teams($teams, $opts);
}

sub test_merged_events ($) {

	my $events = shift;
	my $opts = {merged => 1};

	test_events($events, $opts);
}

sub test_merged_boxscore ($) {

	my $boxscore = shift;
	$BOXSCORE = $boxscore;
	test_merged_header($boxscore);
	test_merged_teams($boxscore->{teams});
	test_periods($boxscore->{periods});
	test_merged_events($boxscore->{events});
	undef $BOXSCORE;
	undef $EVENT;
	undef $PLAYER;
}

sub test_consistency_penalty_minutes ($$) {

	my $roster_player = shift;
	my $event_player  = shift;

	$event_player->{penaltyMinutes}  ||= 0;
	$event_player->{servedbyMinutes} ||= 0;
	my_is_one_of(
		$roster_player->{penaltyMinutes},
		[
			$event_player->{penaltyMinutes},
			$event_player->{penaltyMinutes} + $event_player->{servedbyMinutes},
			$event_player->{penaltyMinutes} - $event_player->{servedbyMinutes},
		],
		"Player $roster_player->{_id}/$roster_player->{name} penaltyMinutes consistent"
	) if defined $roster_player->{penaltyMinutes} && $roster_player->{penaltyMinutes} != -1;
	if ($roster_player->{penaltyMinutes} == $event_player->{penaltyMinutes} - $event_player->{servedbyMinutes}) {
		$roster_player->{penaltyMinutes} += $event_player->{servedbyMinutes};
	}
}

sub test_consistency_goalie ($$$) {

	my $roster_player = shift;
	my $event_player  = shift;
	my $boxscore_id   = shift;

	return unless $roster_player->{timeOnIce};
	my_is(
		$roster_player->{shots} - $roster_player->{saves},
		$event_player->{goalsAgainst} || 0,
		"Player $roster_player->{_id}/$roster_player->{name} goalsAgainst consistent"
	) unless $BROKEN_FILES{$boxscore_id}->{BS} || is_unapplicable('saves');
}

sub test_consistency_skater ($$$$) {

	my $roster_player = shift;
	my $event_player  = shift;
	my $boxscore_id   = shift;
	my $stats         = shift;

	for my $stat (@{$stats}) {
		next if $stat eq 'penaltyMinutes';
		if ($stat eq 'goals' || (
			$stat eq 'assists' &&
				$BOXSCORE->{season} != 1934 && $BOXSCORE->{season} != 1935
			)) {
			if ($roster_player->{_from_na}) {
				debug "Fixing the NA player";
				$roster_player->{$stat} ||= $event_player->{$stat} || 0;
			}
			my_is(
				$roster_player->{$stat},
				$event_player->{$stat} || 0,
				"Player $roster_player->{_id}/$roster_player->{name} $stat consistent"
			);
			return;
		}
		next unless defined $roster_player->{$stat};
		my_is_one_of(
			$roster_player->{$stat},
			[
				$event_player->{$stat} - 1,
				$event_player->{$stat},
				$event_player->{$stat} + 1,
			],
			"Player $roster_player->{_id}/$roster_player->{name} $stat consistent"
		) unless $BROKEN_FILES{BS}->{$boxscore_id} || is_unapplicable($stat);
	}
}

sub test_consistency_playergoals ($$) {

	my $boxscore      = shift;
	my $event_summary = shift;

	return if $SPECIAL_EVENTS{$boxscore->{_id}};
	for my $t (0, 1) {
		my $team = $boxscore->{teams}[$t];
		for my $player (@{$team->{roster}}) {
			$player->{goals} ||= 0;
			if ($player->{position} eq 'G') {
				$event_summary->{$team->{name}}{playergoals} +=
					($event_summary->{$player->{_id}}{g_goals} || 0);
			}
			else {
				$event_summary->{$team->{name}}{playergoals} += $player->{goals}
			}
		}
		my_is(
			$team->{score},
			$event_summary->{$team->{name}}{playergoals} + $event_summary->{so}[$t],
			"Team $team->{name} ($t) playergoals consistent",
		);
	}
}

sub test_consistency ($$) {

	my $boxscore      = shift;
	my $event_summary = shift;

	$THIS_SEASON = $boxscore->{season};
	$BOXSCORE = $boxscore;
	for my $t (0,1) {
		my $team = $boxscore->{teams}[$t];
		my_is(
			($event_summary->{$team->{name}}{score} || 0),
			$team->{score},
			"Team $team->{name} score $team->{score} consistent"
		) unless $BROKEN_FILES{$boxscore->{_id}}->{BS};
		for my $player (@{$team->{roster}}) {
#			dumper $player->{number};
			next if $player->{broken} || $player->{position} eq 'N/A';
			$PLAYER = $player;
			test_consistency_penalty_minutes($player, $event_summary->{$player->{_id}});
			$player->{position} eq 'G' ?
				test_consistency_goalie($player, $event_summary->{$player->{_id}}, $boxscore->{_id}) :
				test_consistency_skater($player, $event_summary->{$player->{_id}}, $boxscore->{_id}, $event_summary->{stats});
		}
		undef $PLAYER;
	}
	test_consistency_playergoals($boxscore, $event_summary)
		unless $BROKEN_FILES{$boxscore->{_id}}->{BS};
}

sub test_normalized_header ($) {

	my $boxscore = shift;

	if ($boxscore->{teams}[0]{score} > $boxscore->{teams}[1]{score}) {
		my_is($boxscore->{result}[0], 2, 'winner correct in result');
		my_is($boxscore->{result}[1], $boxscore->{season} > 1998 && $boxscore->{ot} ? 1 : 0, 'loser correct in result');
	}
	elsif ($boxscore->{teams}[0]{score} < $boxscore->{teams}[1]{score}) {
		my_is($boxscore->{result}[1], 2, 'winner correct in result');
		my_is($boxscore->{result}[0], $boxscore->{season} > 1998 && $boxscore->{ot} ? 1 : 0, 'loser correct in result');
	}
	else {
		my_is($boxscore->{result}[0], 1, 'tie correct in result');
		my_is($boxscore->{result}[1], 1, 'tie correct in result');
	}
	my_like($boxscore->{date}, qr/^\d{8}$/, 'game date set correctly');
	my_ok($boxscore->{location}, 'location set') unless is_unapplicable('location');
	my $path = get_game_path_from_id($boxscore->{_id});
	for my $source (qw(BS PL RO GS ES)) {
		my_is($boxscore->{sources}{$source}, 1 , "source $source registered")
			if $source eq 'BS' || (-f "$path/$source.html" && ! $BROKEN_FILES{$boxscore->{_id}}{$source});
	}
	for my $field (qw(_id attendance last_updated month date ot start_ts stop_ts stage season season_id)) {
		my_like($boxscore->{$field}, qr/^\-?\d+$/, "$field a number");
	}
}

sub test_normalized_roster ($$) {

	my $roster    = shift;
	my $team_name = shift;

	for my $player (@{$roster}) {
		for (keys %{$player}) {
			my $field = $_;
			when ('position') {
#				dumper $player, $BOXSCORE->{_id};
				eval { test_position($player->{$_}, 'position ok') };
				if ($@) {
					dumper $player, $BOXSCORE->{_id};
					die $@;
				}
			}
			when ('name')     { test_name($player->{$_}, 'name ok') };
			when ('status') {
				my_like($player->{$field}, qr/^(C|A| |X)$/, 'status ok');
			}
			when ('start') {
				my_like($player->{$field}, qr/^(0|1|2)$/, 'start ok');
			}
			when ('plusMinus') {
				my_like($player->{$field}, qr/^\-?\d+$/, '+- ok');
			}
			when ('decision') {
				if ($player->{position} eq 'G') {
					test_decision($player->{$field}, 'decision ok');
				}
				else {
					my_die("skater $player->{_id} should not have decision");
				}
			}
			when ('team') {
				my_is($player->{team}, $team_name, 'team in player ok');
			}
			default {
				my_like(
					$player->{$field},
					qr/[+-]?([0-9]*[.])?[0-9]+/, "stat $field a number"
				) if defined $player->{$field};
			}
		}
	}
}

sub test_normalized_teams ($) {

	my $boxscore = shift;
	for my $t (0,1) {
		my $team = $boxscore->{teams}[$t];
		for my $stat (keys %{$team->{stats}}) {
			my_like($team->{stats}{$stat}, qr/[+-]?([0-9]*[.])?[0-9]+/, "team $stat a number");
		}
		for my $field (qw(pull shots score)) {
			my_like($team->{$field}, qr/[+-]?([0-9]*[.])?[0-9]+/, "team $field a number");
		}
		my_ok(! exists $team->{_decision}, 'pseudo-decision removed');
		test_normalized_roster($team->{roster}, $team->{name});
	}
}

sub test_normalized_events ($) {

	my $boxscore = shift;

	return if $BROKEN_FILES{$boxscore->{_id}}->{BS} &&
		$BROKEN_FILES{$boxscore->{_id}}->{BS} == $UNSYNCHED;
	for my $event (@{$boxscore->{events}}) {
		test_game_id($event->{game_id}, 'event has game');
		my_like($event->{zone}, qr/^(OFF|DEF|NEU|UNK)$/, 'event has zone')
			unless is_noplay_event($event);
		my_is(length($event->{strength}), 2, 'event has strength')
			unless is_noplay_event($event);
		for my $field (qw(period season stage so ts)) {
			my_like($event->{$field}, qr/^\d+$/, "field $field a number")
				if defined $event->{$field};
		}
		test_event_coords($event)
			if $event->{coords};
		my_like($event->{t}, qr/^(-1|0|1)$/, 'event t index ok')
			unless is_noplay_event($event);
		my_like($event->{en}, qr/^(0|1)$/, 'event en ok')
			if exists $event->{en};
		my_is(
			$event->{team2},
			$boxscore->{teams}[1-$event->{t}]{name}, 'team2 ok'
		) if defined $event->{t} && $event->{t} != -1;
		for my $field (qw(player1 player2 assist1 assist2)) {
			test_player_id($event->{$field}, "field $field ok")
				if exists $event->{$field};
		}
		if ($event->{on_ice}) {
			for my $t (0,1) {
				for my $o (@{$event->{on_ice}[$t]}) {
					test_player_id($o, 'valid player id on ice');
				}
			}
		}
		for ($event->{type}) {
			when ('GOAL') {
				test_player_id($event->{player1}, "goal scorer player1 ok");
#				dumper $event;
				test_player_id($event->{player2}, "goal goalie player2 ok")
					unless $event->{en};
				for my $field (qw(en gwg penaltyshot)) {
					my_like($event->{$field}, qr/^0|1$/, "goal $field ok")
				}
				if ($event->{assist1}) {
					test_player_id($event->{assist1}, 'assist1 ok');
					my_is($event->{assist1}, $event->{assists}[0], 'in array');
					if ($event->{assist2}) {
						test_player_id($event->{assist2}, 'assist2 ok');
						my_is($event->{assist2}, $event->{assists}[1], 'in array');
					}
				}
				when ('PENL') {
					my_ok($event->{ps_penalty}, 'ps penalty')
						if $event->{length} == 0;
					test_penalty($event->{penalty}, 'penalty defined');
					test_player_id($event->{servedby}, 'servedby ok')
						if $event->{servedby};
				}
				when ('FAC')  {
					test_team($event->{winning_team}, 'FAC winning team ok');
				}
				if ($event->{type} ne 'GOAL') {
					my_ok(!defined $event->{assist1}, 'no goal no assist1');
					my_ok(!defined $event->{assist2}, 'no goal no assist2');
					my_ok(!defined $event->{assists}, 'no goal no assists');
				}
				my_ok(
					$VOCABULARY{shot_type}->{$event->{shot_type}},
					"$event->{shot_type} shot type normalized",
				);
				my @fields = keys %{$event};
				for my $field (@fields) {
					my_ok(defined $field, "existing field $field defined");
					next if $field eq 'file' || ref $event->{$field};
					if ($event->{$field} =~ /\D/) {
						my_is($event->{$field}, uc($event->{$field}), 'all UC ok');
					}
					else {
						my_like($event->{$field}, qr/^\d+$/, 'numeric field ok');
					}
				}
			}
		}
	}
}

sub test_arranged_events ($) {

	my $boxscore = shift;

	my $gp = scalar @{$boxscore->{periods}};
	$gp += $boxscore->{so} || 0 if $gp == 4;
	my_is($boxscore->{events}[-1]{type}, 'GEND', 'gend at the end');
	my_is($boxscore->{events}[-2]{type}, 'PEND', 'pend penultimate');
	my_is(scalar(grep{$_->{type} eq 'PSTR'} @{$boxscore->{events}}), $gp, "$gp pstr");
	my_is(scalar(grep{$_->{type} eq 'PEND'} @{$boxscore->{events}}), $gp, "$gp pend");
	my_is(scalar(grep{$_->{type} eq 'GEND'} @{$boxscore->{events}}), 1, '1 gend');

	for my $e (0..$#{$boxscore->{events}}-1) {
#		dumper 	$boxscore->{events}[$e], 	$boxscore->{events}[$e+1];
		my_cmp_ok(
			$boxscore->{events}[$e]{period},
			'<=',
			$boxscore->{events}[$e+1]{period},
			'period ordered'
		);
		my_cmp_ok(
			$boxscore->{events}[$e]{ts},
			'<=',
			$boxscore->{events}[$e+1]{ts},
			'ts ordered'
		) if $boxscore->{events}[$e]{period} ==
			$boxscore->{events}[$e+1]{period};
		my_cmp_ok(
			$Sport::Analytics::NHL::Normalizer::EVENT_PRECEDENCE{
				$boxscore->{events}[$e]{type}
			},
			'<=',
			$Sport::Analytics::NHL::Normalizer::EVENT_PRECEDENCE{
				$boxscore->{events}[$e+1]{type}
			},
			'precedence ordered'
		) if
			$boxscore->{events}[$e]{period} ==
			$boxscore->{events}[$e+1]{period}
			&& $boxscore->{events}[$e]{ts} ==
			$boxscore->{events}[$e+1]{ts} &&
			($boxscore->{events}[$e]{period} < 5 || $boxscore->{stage} == $PLAYOFF);
		my $event = $boxscore->{events}[$e];
		my_like($event->{_id}, qr/^$boxscore->{_id}\d{4}$/, '_id created');
		if ($event->{type} eq 'PSTR') {
			my_like($event->{ts}, qr/^(0|\d{2,3}00)$/, 'period starts at 00');
			my_like($event->{time}, qr/^\d+:00$/,  'period starts at :00');
		}
		elsif ($event->{type} eq 'PEND') {
			my_ok($event->{ts}, 'pend timestamp defined');
		}
		elsif ($event->{type} eq 'GEND') {
			my_die "Should not get to GEND";
		}
	}
}

sub test_normalized_boxscore ($) {

	my $boxscore = shift;

	$THIS_SEASON = $boxscore->{season};
	test_normalized_header($boxscore);
	test_normalized_teams($boxscore);
	test_normalized_events($boxscore);
	test_arranged_events($boxscore);
}

sub test_bio ($) {

	my $report = shift;

	test_player_id($report->{_id}, 'report player id ok');
	test_name($report->{name}, 'report playername ok');
	test_position($report->{position}, 'report position ok');
	my_like($report->{number},    qr/^\d{1,2}$/,     "number $report->{number} ok") if defined $report->{number};
	my_like($report->{height},    qr/^\d+$/,         "height $report->{height} ok") if defined $report->{height};
	my_like($report->{weight},    qr/^\d+$/,         "weight $report->{weight} ok") if defined $report->{weight};;
	my_like($report->{shoots},    qr/^L|R$/,         "shoots $report->{shoots} ok");
	my_like($report->{birthdate}, qr/^\-?\d+$/,      "birthdate $report->{birthdate} ok");
	my_like($report->{city},      qr/^\S.*\S/,       "city $report->{city} ok");
	my_like($report->{state},     qr/^\w\w$/,        "state $report->{state} ok");
	my_like($report->{country},   qr/^\S.*\S/,       "country $report->{country} ok");
	my_like($report->{active},    qr/^(0|1)$/,       "active $report->{active} ok");
	my_like($report->{rookie},    qr/^(0|1)$/,       "active $report->{rookie} ok");
	test_team_id($report->{team}, "name $report->{team} ok") if $report->{active};
	my_like($report->{pick}, qr/^\d{1,3}$/, "pick $report->{pick} ok");
	if ($report->{pick} == $UNDRAFTED_PICK) {
		my_is($report->{undrafted}, 1, 'player is undrafted');
	}
	else {
		test_team_id($report->{draftteam}, "draftteam $report->{draftteam} ok");
		my_like($report->{draftyear}, qr/^\d{4}$/, "year $report->{draftyear} ok");
		my_like($report->{round}, qr/^\d{1,2}$/, "round $report->{round} ok")
	}
}

sub test_career ($) {

	my $report = shift;
	my $n_career = $report->{career};

	for my $stage (@{$n_career}) {
		for my $season (@{$stage}) {
			if ($season->{season} ne 'total' && $season->{league} ne 'bogus') {
				next unless $season->{league} eq 'NHL';
				my_ok($season->{start} > 1890 && $season->{start} < $CURRENT_SEASON + 1, "Valid start $season->{start}");
				my_ok($season->{end}   > 1890 && $season->{end}   < $CURRENT_SEASON + 2, "Valid end   $season->{end}");
				next unless length($season->{gp});
				my_ok($season->{gp}  < 100,  "reasonable gp  $season->{gp}") if length($season->{gp});
				if ($report->{position} eq 'G') {
					my_ok($season->{w}   < 80, "reasonable w $season->{w}")
						if length($season->{w});
					my_ok($season->{l}   < 80, "reasonable l $season->{l}")
						if length($season->{l});
					my_ok($season->{t}   < 80, "reasonable t $season->{t}")
						if length($season->{t});
					my_ok($season->{ot}   < 80, "reasonable ot $season->{ot}")
						if $season->{ot} && length($season->{ot});
					my_ok($season->{so}   < 50, "reasonable so $season->{so}")
						if length($season->{so});
					my_ok($season->{ga}   < 500, "reasonable ga $season->{ga}")
						if length($season->{ga});
				}
				else {
					my_ok($season->{g}   < 200,  "reasonable g   $season->{g}")
						if length($season->{g});
					my_ok($season->{a}   < 200,  "reasonable a   $season->{a}")
						if length($season->{a});
					my_ok($season->{pim} < 1000, "reasonable pim $season->{pim}")
						if length($season->{pim});
				}
				if ($season->{league} eq 'NHL' && $season->{start} >= 1988) {
					if ($report->{position} eq 'G') {
						if (length($season->{gp}) && $season->{gp}) {
							my_ok($season->{gaa} < 200,   "reasonable gaa $season->{gaa}");
							my_ok($season->{'sv%'} <= 1,  "reasonable sv\% $season->{'sv%'}");
							my_ok($season->{sa} < 5000,   "reasonable sa $season->{sa}");
							my_ok($season->{min} < 10000, "reasonable min $season->{min}");
						}
					}
					else {
						my_ok($season->{gwg} < 50,   "reasonable gwg $season->{gwg}");
						my_ok($season->{shg} < 20,   "reasonable shg $season->{shg}");
						my_ok($season->{ppg} < 50,   "reasonable ppg $season->{ppg}");
						my_ok($season->{s}   < 1000, "reasonable s   $season->{s}")
							if length($season->{s});
						my_ok(
							$season->{'s%'} >= 0 && $season->{'s%'} <= 100,
							"reasonable s\%  $season->{'s%'}"
						) if $season->{s};
						my_like($season->{'+/-'}, qr/^\-?\d+$/, "reasonable +\/- $season->{'+/-'}")
							if length($season->{'+/-'});
					}
				}
			}
			else {
				next if $season->{league} eq 'bogus';
				my_is($season->{team}, 'NHL TOTALS', "valid $season->{team} pseudo team");
				my_ok($season->{career_start} >= $FIRST_SEASON && $season->{career_start} <= $CURRENT_SEASON,
					  "Valid career_start $season->{career_start}");
				my_ok($season->{career_end}   >= $FIRST_SEASON && $season->{career_end}   <= $CURRENT_SEASON,
					  "Valid career_end   $season->{career_end}");
				my_is($season->{league}, 'NHL', 'only NHL totals are available');
			}
		}
	}
}

sub test_player_report ($) {

	my $report = shift;

	test_bio($report);
	test_career($report);
}

END {
	if ($BOXSCORE) {
		$Data::Dumper::Varname = 'BOXSCORE';
	}
	if ($EVENT) {
		$Data::Dumper::Varname = 'EVENT';
		dumper $EVENT;
	}
	if ($PLAYER) {
		$Data::Dumper::Varname = 'PLAYER';
		dumper $PLAYER;
	}
}

1;

=head1 AUTHOR

More Hockey Stats, C<< <contact at morehockeystats.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<contact at morehockeystats.com>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Sport::Analytics::NHL::Test>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Sport::Analytics::NHL::Test

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Sport::Analytics::NHL::Test>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Sport::Analytics::NHL::Test>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Sport::Analytics::NHL::Test>

=item * Search CPAN

L<https://metacpan.org/release/Sport::Analytics::NHL::Test>

=back
