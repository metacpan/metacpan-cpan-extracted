package Sport::Analytics::NHL::Generator;

use v5.10.1;
use strict;
use warnings FATAL => 'all';
use experimental qw(smartmatch);

use Carp;

use parent 'Exporter';

use Sport::Analytics::NHL::Util qw(:debug :utils);
use Sport::Analytics::NHL::DB;
use Sport::Analytics::NHL::Tools qw(:gameutils get_zones);
use Sport::Analytics::NHL::Normalizer qw(%EVENT_PRECEDENCE);
use Sport::Analytics::NHL::Errors;
use Sport::Analytics::NHL::Config qw(:seasons :icing);
use Sport::Analytics::NHL::Vars qw($DB $CACHES $CURRENT_SEASON);

use List::MoreUtils qw(part indexes firstidx firstval);
use Date::Parse;
use Date::Format;

our @EXPORT = qw(
	generate generate_game
);

=head1 NAME

Sport::Analytics::NHL::Generator - generate derived data from the NHL reports, after normalization and population.

=head1 SYNOPSIS

Generates derived data from the NHL reports, after normalization and population.

 use Sport::Analytics::NHL::Generator
 # Let $opts have the parsed CLI options
 # from Usage.pm
 # Let $game be a game retrieved from the database
 my $generated = generate_game($opts, $game);
 # generates data, returns all things generated, updates the DB
 # unless dry_run mode is specified.
 #
 # or
 #
 generate($opts, 201820001);
 # just specify the options and the game ID.

Only the functions generate() and generate_game() are exported.

All the internal generate_* functions accept the second optional argument $dry_run which, when specified, prevents the database from being updated. Another way of controlling this behavior is by specifying HOCKEYDB_DRYRUN environment variable.
This second argument is not mentioned below as well as the first one which is always the game structure.

=head1 FUNCTIONS

=over 2

=item C<guess_pulled_goalie_through_en>

Tries to guess if the goalie was pulled during the game through against/with EN goals.

 Arguments: the game
            the structure holding the pulled goalies

 Returns: whether at least one team pulled the goalie

=item C<guess_pulled_goalie_on_ice>

Tries to guess if the goalie was pulled during the game through on ice list of players in an event.

 Arguments: the double array of players on ice
            the current score
            the structure holding the pulled goalies

 Returns: whether at least one team pulled the goalie

=item C<guess_pulled_goalie_through_events>

Tries to guess if the goalie was pulled during the game through the game events containing on ice players information.

 Arguments: the game
            the structure holding the pulled goalies

 Returns: whether at least one team pulled the goalie

=item C<guess_pulled_goalie_through_toi>

Tries to guess if the goalie was pulled during the game through the time on ice spent by goalies during the game.

 Arguments: the game
            the structure holding the pulled goalies

 Returns: whether at least one team pulled the goalie

=item C<guess_pulled_goalies>

Tries to guess if the goalie was pulled during the game through one of the methods described above.

 Arguments: the game

 Returns: the structure holding the pulled goalies

=item C<get_pulled_goalies>

Gets goalie pulls from the list of player shifts in the game. Limited to period since 2007/08 season.

 Arguments: the game

 Returns: the structure holding the pulled goalies

=item C<generate_pulled_goalie>

Generates the information about the pulled goalies and updates the database with pull counts for each team in the field goalie_pull.

 Returns: the goalie pull 2-member array ref.

=item C<generate_ne_goals>

Generates goals that were scored with net empty. In general superseded by event processing during the merge process (see Sport::Analytics::NHL::Merger)

 Returns: the list of goals that were scored with net empty.

=item C<get_icing_iterator>

Gets an iterator of icings in the game.

 Arguments: the game

 Returns: a MongoDB Cursor with the icings,
          or undef if there are no icings.

=item C<set_icing_properties>

Sets some of the icing's properties: the ensuing faceoff, whether the icing team won that faceoff, the team that iced the puck as team1, and the other as team2.

 Arguments: the icing event
            the ensuing faceoff event
            the zone codes

 Returns: the update hashref desribed above

=item C<adjudicate_icing_quality>

Adjudicates the quality of the icing: $ICING_GOOD for icing without consequences, $ICING_NEUTRAL for an icing followed by another icing by the same team,
$ICING_BAD if followed by a penalty and $ICING_DISASTER if followed by a goal.

 Arguments: the ensuing event
            the faceoff after that event
            the team committing the icing
            the zone codes

 Returns: the quality of the icing.

=item C<generate_icings_info>

Generates the information about the icing: the properties described above, the quality and the ensuing event.

 Returns: the array or the arrayref of updates to the icing events

=item C<generate_fighting_majors>

Generates obvious fighting majors opponents from the era predating indication of the player drawing the penalty.
The opponent is assigned as player2 of the event.

 Returns: the list of the updates to the fights in the game.

=item C<check_strikeback>

Checks if the goal flow of the game indicates a strikeback (a comeback).

 Arguments: the winner of the game
            array of the game goals, excluding shootout

 Returns: the biggest strikeback delta.

=item C<generate_strikebacks>

Generates strikebacks (comebacks) in the NHL game. Only the full strikebacks (resulting in wins of a trailing team) are generated.

 Returns: the strikeback team and size.

=item C<generate_lead_changing_goals>

Generates lead changing and lead swinging goal indicators for goals in the game.

 Returns: the list of lcg and lsg goals detected.

=item C<generate_icecount_mark>

Generates a special icecount mark based on either given on-ice presence of players or known on-ice strengths (produced by Sport::Analytics::NHL::PenaltyAnalyzer)
The icecount of 4150 means 4 skaters for away team, 1 goalie, 5 for home team, goalie pulled, derived from on-ice protocol.
The icecount of 15151 means 5 skaters, one goalie for each team, derived from strengths.

 Returns: hashref of icecounts per event id.

=item C<get_stops_and_challenges>

Gets the CHL event and the STOP CHLG events associated with given game ID.

 Arguments: Game ID

 Returns: array of such stops and challenges

=item C<check_missing_challenges>

Checks if there are registered broken/missing challenges with an artificial ID and populates them in the DB.

 Arguments: Game ID

 Returns: void

=item C<process_broken_challenge>

Processes the challenge that has been identified as broken and populates it with data from Sport::Analytics::NHL::Config

 Arguments: the event
            the hashref of the populated challenge
            the game

 Returns: 0 if the event is indeed broken and populated
          0 if the event is marked as missing
          1 if the event is whole

=item C<process_stop_challenge>

Processes a STOP-based challenge, populating the challenge type and the description of the event.

 Arguments: the event
            the hashref of the generated challenge

 Returns: 0 if the challenge has already been marked
          1 otherwise

=item C<configure_nhl_offside_challenge>

Configures the offside challenge initiated by the NHL. Winner and loser of the challenge are set.

 Arguments: the challenge being populated
            the event
            the game
            the coordinates normalizer (1 or -1)

 Returns: void

=item C<configure_offside_challenge>

Configures a generic offside challenge. Result (1/0) and winner and loser are set.

 Arguments: the challenge being populated
            the event
            the game
            the coordinates normalizer (1 or -1)

 Returns: void

=item C<configure_goalie_challenge>

Configures a goaltender interference challenge. Result (1/0) and winner and loser are set.

 Arguments: the challenge being populated
            the event
            the game

 Returns: void

=item C<configure_league_challenge>

Configures a generic NHL challenge (video review). Winner and loser are set.

 Arguments: the challenge being populated
            the event
            the game
            the coordinates normalizer (1 or -1)

 Returns: void

=item C<configure_challenge>

Dispatches the configuration of the challenge and fills the common fields: the timestamp, the coach, the type, the event id, the game id, the event type as the source and the challenging team (-1 in the case of the NHL).

 Arguments: the challenge being populated
            the event
            the game
            the coordinates normalizer (1 or -1)

 Returns: void

=item C<generate_challenges>

Generates the coach and the NHL challenges that happen during a game.

 Returns: the aggregation of all challenges.

=item C<apply_leading_trailing>

Applies the time elapsed since the last check to leading and trailing time counts of the game. Only leading and tied times are updated. The trailing is the inverse of the leading.

 Arguments: the leading-trailing hashref
            the delta of the score (absolute)
            the elapsed time
            the game

 Returns: void

=item C<generate_leading_trailing>

Generates the times the teams were leading, tied and trailing during a game.

 Returns: the hashref with the leading/trailing information.

=item C<get_offsides_iterator>

Gets an iterator over offside events in a game.

 Arguments: the game

 Returns: the MongoDB Cursor ready to iterate,
          or undef if no offsides happened in a game.

=item C<get_offside_faceoff>

Returns the faceoff following the offside

 Arguments: the offside event
            the faceoffs of the game
            the zones

 Returns: the faceoff
          0 if the faceoff is not on the right dots
          undef if there's no faceoff

=item C<generate_offsides_info>

Generate the information about offsides: team committing the offside and the other one as team1 and team2.

 Returns: array or arrayref of updated offside events.

=item C<generate_gamedays>

Generate the length of a break before a game for each team.

 Returns: the arrayref of the length of the break for each team.
 The break is set to 30 for the first game of the season.

=item C<generate_common_games>

Generates the common game between pairs of players in a game.

 Returns: the list of combination of ids of such players.

=item C<get_clutch_type>

Gets a type of a clutch goal: GEG, GWG, GTG, L(ate)GWG, LGTG. The definition of the GWG differs from the NHL one.

 Arguments: the goal
 [optional] the presumed type, default: gtg

 Returns: mapping goal_id to clutch type.

=item C<get_clutch_goals>

Gets the clutch goals from all goals of the game and sets their types.

 Arguments: the game
            the goals

 Returns: the hashref of mappings of clutch goals.

=item C<generate_clutch_goals>

Generates clutch goal information in a game.

 Returns: the mapping of clutch goals.

=item C<generate_game>

Generates all of the above, or part of it if specified explicitly by options.

 Arguments: the options hash
            the game

 Returns: all the generations by type.

=item C<generate>

Generates all of the above, per given game id or a list of games.

 Arguments: the options hash
            the array of games or game IDs

 Returns: void

=back

=cut

sub guess_pulled_goalie_through_en ($$) {

	my $game              = shift;
	my $has_pulled_goalie = shift;

	my @en_goals = $DB->get_collection('GOAL')->find({
		en => 1, game_id => $game->{_id},
	})->all();
	$has_pulled_goalie->[1-$_->{t}]++ for @en_goals;
	my @ne_goals = $DB->get_collection('GOAL')->find({
		ne => 1, game_id => $game->{_id},
	})->all();
	$has_pulled_goalie->[ $_->{t} ]++ for @ne_goals;

	$has_pulled_goalie->[0] || $has_pulled_goalie->[1];
}

sub guess_pulled_goalie_on_ice ($$$) {

	my $on_ice            = shift;
	my $score             = shift;
	my $has_pulled_goalie = shift;

	TEAM:
	for my $t (0,1) {
		for my $player (@{$on_ice->[$t]}) {
			my $position = get_player_position($player);
			next TEAM if $position eq 'G';
		}
		next if $score->[$t] > $score->[1-$t];
		next if $score->[$t] < $score->[1-$t] - 3;
		$has_pulled_goalie->[$t] = 1;
	}

	$has_pulled_goalie->[0] || $has_pulled_goalie->[1];
}

sub guess_pulled_goalie_through_events ($$) {

	my $game              = shift;
	my $has_pulled_goalie = shift;

	my $events_c = $DB->get_collection('events');
	my $events_i = $events_c->find({game_id => $game->{_id}});
	my $score = [0,0];

	while (my $_event = $events_i->next()) {
		next if is_noplay_event($_event);
		my $collection = $DB->get_collection($_event->{type});
		my $event      = $collection->find_one({_id => $_event->{event_id}});
		next if $event->{so};
		$score->[$event->{t}]++ if $_event->{type} eq 'GOAL';
		next if $event->{ts} < 3360
			|| $has_pulled_goalie->[$event->{t}] || ! has_on_ice($event);
		guess_pulled_goalie_on_ice($event->{on_ice}, $score, $has_pulled_goalie);
		return 1 if $has_pulled_goalie->[0] && $has_pulled_goalie->[1];
	}

	$has_pulled_goalie->[0] || $has_pulled_goalie->[1];
}

sub guess_pulled_goalie_through_toi ($$) {

	my $game              = shift;
	my $has_pulled_goalie = shift;

	my $goalies = get_game_goalies($game);
	return unless defined $goalies->[0][0]{timeonice};
	my $toi = [0,0];
	for my $t (0,1) {
		$toi->[$t] += $_->{timeonice} for @{$goalies->[$t]};
		$has_pulled_goalie->[$t] = 1  if $toi->[$t] + 40 < $game->{length};
	}
	$has_pulled_goalie->[0] || $has_pulled_goalie->[1];
}

sub guess_pulled_goalies ($) {

	my $game = shift;

	my $has_pulled_goalie = [0,0,0];
	$DB ||= Sport::Analytics::NHL::DB->new();
	gamedebug $game, "Goalie pull";
	guess_pulled_goalie_through_en($game, $has_pulled_goalie)
		|| guess_pulled_goalie_through_events($game, $has_pulled_goalie)
		|| guess_pulled_goalie_through_toi($game, $has_pulled_goalie);

	$has_pulled_goalie;
}

sub get_pulled_goalies ($) {

	my $game = shift;

	my $goalies = get_game_goalies($game);
	my $shifts_c = $DB->get_collection('shifts');
	my $has_pulled_goalie = [0,0,1];
	for my $t (0,1) {
		my $goalie_ids = [ map($_->{_id}, @{$goalies->[$t]})];
		my $shifts_i = $shifts_c->find({
			player  => { '$in' => $goalie_ids },
			game_id => $game->{_id},
			period  => 3,
			finish  => {
				'$gt' => 3300,
				'$lt' => 3600,
			},
		})->sort({finish => 1});
		my $shift_finish = 0;
		while (my $shift = $shifts_i->next()) {
			#dumper $shift;
			$has_pulled_goalie->[$t] += $shift->{start} - $shift_finish
				if $shift_finish && ($shift->{start} - $shift->{finish} > 1);
			$shift_finish = $shift->{finish};
		}
		next unless $shift_finish;
		
		$has_pulled_goalie->[$t] += $game->{length} - $shift_finish;
	}
	$has_pulled_goalie;
}

sub generate_pulled_goalie ($;$) {

	my $game    = shift;
	my $dry_run = shift || $ENV{DRY_RUN} || 0;

	my $game_id = $game->{_id};
	$DB ||= Sport::Analytics::NHL::DB->new();
	my $games_c = $DB->get_collection('games');
	verbose "Generating pulled goalie";
	my $goalie_pull = $game->{season} < 2007
		? guess_pulled_goalies($game)
		: get_pulled_goalies($game);
	if ($goalie_pull->[0] || $goalie_pull->[1]) {
		$games_c->update_one(
			{ '_id' => $game_id },
			{ '$set' => { goalie_pull => $goalie_pull } },
		) if $dry_run;
	}
	$goalie_pull;
}

sub generate_ne_goals ($;$) {

	my $game    = shift;
	my $dry_run = shift || $ENV{HOCKEYDB_DRYRUN} || 0;

	return if $game->{season} < $GOAL_HAS_ON_ICE;

	my $game_id = $game->{_id};
	$DB ||= Sport::Analytics::NHL::DB->new();
	my $score = [0,0];
	my $update = [];
	my $players_c = $DB->get_collection('players');
	my $GOAL_c = $DB->get_collection('GOAL');
	my $GOAL_i = $GOAL_c->find({game_id => $game_id+0});
	while (my $goal = $GOAL_i->next()) {
		$score->[$goal->{t}]++ unless $goal->{so};
		next if $goal->{en} || $goal->{so} || $goal->{ts} < 3420
			|| !has_on_ice($goal);
		eventdebug $goal, "NE goals";
		my $ne = 0;
		TEAM:
		for my $t (0,1) {
			for (@{$goal->{on_ice}[$t]}) {
				next TEAM if get_player_position($_) eq 'G';
			}
			next if $score->[$t] > $score->[1-$t]
				|| $score->[$t] < $score->[1-$t] - 3;
			if ($t == $goal->{t}) {
				push(@{$update}, $goal->{_id});
				last TEAM;
			}
		}
	}
	return unless @{$update};
	update(1, $GOAL_c, {_id => { '$in' => $update }}, {'$set' => {ne => 1}})
		unless $dry_run;
	return $update;
}

sub get_icing_iterator ($) {

	my $game = shift;

	my $game_id = $game->{_id};
	$DB ||= Sport::Analytics::NHL::DB->new();
	my $STOP_c = $DB->get_collection('STOP');
	$CACHES->{stopreasons}{icing} ||=
		$DB->get_collection('stopreasons')->find_one({name => 'ICING'})->{_id};
	my $icing_count = $STOP_c->count_documents({
		game_id     => $game_id+0,
		stopreasons => $CACHES->{stopreasons}{icing},
	});
	return undef unless $icing_count;
	my $icing_i = $STOP_c->find({
		game_id     => $game_id+0,
		stopreasons => $CACHES->{stopreasons}{icing},
	})->sort({ts => 1});

	$icing_i;
}

sub set_icing_properties ($$$) {

	my $icing  = shift;
	my $faceoff = shift;
	my $zones   = shift;

	my $update = {_id => $icing->{_id}, faceoff => $faceoff->{_id} };
	my $icing_win = $faceoff->{zone} eq $zones->{DEF} ? 1 : 0;
	$update->{faceoff_win} = $icing_win;
	$update->{'team'.(2-$icing_win)} = $faceoff->{winning_team};
	$update->{'team'.(1+$icing_win)} = $faceoff->{team2};

	$update;
}

sub adjudicate_icing_quality ($$$$) {

	my $event        = shift;
	my $next_faceoff = shift;
	my $icing_team   = shift;
	my $zones        = shift;

	return $ICING_GOOD if $event->{ts} > $next_faceoff->{ts} + $ICING_TIMEOUT;
	my $quality;
	for ($event->{type}) {
		when ('STOP') {
			$quality = (grep {
				$_ eq $CACHES->{stopreasons}{icing}
			} @{$event->{stopreasons}})
				? $ICING_NEUTRAL
				: $ICING_GOOD;
		}
		when ('PEND') {
			$quality = $ICING_GOOD;
		}
		when ('PENL') {
			$quality = $event->{team1}   eq $icing_team
				&& $next_faceoff->{zone} ne $zones->{NEU}
				&& $event->{zone}        eq $zones->{DEF}
				&& ! $event->{matched}
				? $ICING_BAD
				: $ICING_GOOD;
		}
		when ('GOAL') {
			$quality = $event->{team1} ne $icing_team
				? $ICING_DISASTER
				: $ICING_GOOD;
		}
	}
	$quality;
}

sub generate_icings_info ($;$) {

	my $game    = shift;
	my $dry_run = shift || $ENV{DRY_RUN} || 0;

	gamedebug $game, 'Team icings';
	my $game_id = $game->{_id};
	my $icing_i = get_icing_iterator($game) || return;
	my $zones = get_zones();

	my $FAC_c    = $DB->get_collection('FAC');
	my $events_c = $DB->get_collection('events');
	my @faceoffs = $FAC_c->find({ game_id => $game_id})->sort({ ts => 1 })->all();
	my @events = $events_c->find({
		game_id => $game_id, type => {'$in' => [qw(PEND STOP PENL GOAL)]}
	})->sort({ _id => 1 })->all();
	my @updates;
	while (my $icing = $icing_i->next()) {
		eventdebug $icing, 'Team icings';
		my $f_index = firstidx {$_->{ts} >= $icing->{ts} - 1} @faceoffs;
		if ($f_index == -1) {
			warn "No faceoff follows $icing->{_id}";
			next;
		}
		splice(@faceoffs, 0, $f_index);
		my $faceoff = shift @faceoffs;
		next if $faceoff->{zone} eq $zones->{NEU}
			|| $faceoff->{zone} eq $zones->{UNK};
		my $update = set_icing_properties($icing, $faceoff, $zones);
		@events = grep {$_->{event_id} > $faceoff->{_id}} @events;
		if (!@events || !@faceoffs) {
			$update->{quality} = $ICING_GOOD;
			push(@updates, $update);
			last;
		}
		my $event_candidate = shift @events;
		my $event = $DB->get_collection($event_candidate->{type})
			->find_one({ _id => $event_candidate->{event_id} + 0 });
		$update->{quality} = adjudicate_icing_quality(
			$event, $faceoffs[0], $update->{team1}, $zones,
		);
		$update->{ensuing_event} = {
			id   => $event->{_id},
			type => $event->{type}
		};
		$update->{t} = $update->{team1} eq $game->{teams}[0]{name} ? 0 : 1;
		push(@updates, $update);
	}
	if (! $dry_run) {
		for my $update (@updates) {
			update(0, 'STOP', { _id => delete $update->{_id} }, { '$set' => $update })
		}
	}
	wantarray ? @updates : \@updates;
}

sub generate_fighting_majors ($;$) {

	my $game = shift;
	my $dry_run = shift || $ENV{DRY_RUN} || 0;

	my $PENL_c = $DB->get_collection('PENL');
	my $fighting = $DB->get_collection('penalties')->find_one({name => 'FIGHTING'})->{_id};
	my $PENL_i = $PENL_c->find({
		game_id => $game->{_id},
		penalty => $fighting,
	});
	gamedebug $game, "Generate f majors";
	my $fights = {};
	while (my $penl = $PENL_i->next()) {
		next if $penl->{player2};
		$fights->{$penl->{ts}} ||= [];
		push(@{$fights->{$penl->{ts}}}, $penl);
	}
	my @updated;
	for my $fight (values %{$fights}) {
		next if @{$fight} != 2;
		next if $fight->[0]{team1} eq $fight->[1]{team1};
		for (0, 1) {
			update(0, $PENL_c, {_id => $fight->[$_]{_id}}, {
				'$set' => { player2 => $fight->[1-$_]{player1} }
			}) unless $dry_run;
		}
		push(@updated, $fight);
	}
	wantarray ? @updated : [@updated];
}

sub check_strikeback ($@) {

	my $winner = shift;
	my @goals  = @_;

	my $delta = 0;
	my $biggest_delta = 0;

	for my $goal (@goals) {
		$delta += 2*$goal->{t} - 1;
		$biggest_delta = abs($delta)
			if $delta * $winner < 0 && abs($delta) > $biggest_delta;
	}
	$biggest_delta;
}

sub generate_strikebacks ($;$) {

	my $game    = shift;
	my $dry_run = shift || $ENV{DRY_RUN} || 0;

	return if     $game->{result}[0]       == $game->{result}[1];
	return unless $game->{teams}[0]{score} && $game->{teams}[1]{score};

	my $game_id = $game->{_id};
	my $GOAL_c  = $DB->get_collection('GOAL');
	my $games_c = $DB->get_collection('games');
	gamedebug $game, 'Strikebacks';

	my $winner = $game->{result}[0] > $game->{result}[1] ? -1 : 1;
	my @goals = $GOAL_c->find({game_id => $game_id + 0})
		->sort({_id => 1})->all();
	my $_strikeback = check_strikeback($winner, @goals);
	if ($_strikeback) {
		my $wteam = $game->{teams}[$winner == 1 ? $winner : 0]{name};
		my $lteam = $game->{teams}[$winner == 1 ? 0 : $winner]{name};
		debug "Strikeback: $wteam vs $lteam from -$_strikeback";
		my $strikeback = {
			winner => $wteam,
			loser  => $lteam,
			size   => $_strikeback,
		};
		$games_c->update_one({
			_id => $game_id,
		}, {
			'$set' => { strikeback => $strikeback }
		}) unless $dry_run;
		return $strikeback;
	}
	$_strikeback;
}

sub generate_lead_changing_goals ($;$) {

	my $game    = shift;
	my $dry_run = shift || $ENV{HOCKEYDB_DRYRUN} || 0;

	my $game_id = $game->{_id};
	my $GOAL_c  = $DB->get_collection('GOAL');
	gamedebug $game, 'Lead changing goal';
	my @goals = $GOAL_c->find({game_id => $game_id + 0})
		->sort({_id => 1})->all();

	my $score = [0,0];
	my $last_leader;
	my @updates;
	for my $goal (@goals) {
		$last_leader = $score->[0] > $score->[1] ? 0 : 1
			if ($score->[0] != $score->[1]);
		my $update = {
			lcg => is_lead_changing_goal($score, $goal->{t}),
			lsg => is_lead_swinging_goal($score, $goal->{t}, $last_leader),
			_id => $goal->{_id},
		};
		$score->[$goal->{t}]++;
		$GOAL_c->update_one({
			_id => $goal->{_id}
		}, {
			'$set' => $update,
		}) unless $dry_run;
		push(@updates, $update);
	}
	unless ($dry_run) {
		$GOAL_c->update_one({ _id => delete $_->{_id} }, { '$set' => $_ })
			for (@updates);
	}
	wantarray ? @updates : [@updates];
}

sub generate_icecount_mark ($;$) {

	my $game = shift;
	my $dry_run = shift || $ENV{HOCKEYDB_DRYRUN} || 0;

	my $events_c  = $DB->get_collection('events');
	my $players_c = $DB->get_collection('players');
	my $str_c     = $DB->get_collection('str');

	my $events_i  = $events_c->find({game_id => $game->{_id}});
	my @strengths = $str_c->find({game_id => $game->{_id}})->all();
	my %collections = ();
	my $icecounts = {};
	while (my $_event = $events_i->next()) {
		next if is_noplay_event($_event);
		$collections{$_event->{type}} ||= $DB->get_collection($_event->{type});
		my $event = $collections{$_event->{type}}->find_one({_id => $_event->{event_id}+0});
		next if $event->{penaltyshot};
		my $str = get_event_strength($event, @strengths) || next;
		my $icecount;
		if (
			$event->{on_ice} && @{$event->{on_ice}} &&
			@{$event->{on_ice}[0]} > 3 && @{$event->{on_ice}[1]} > 3
		) {
			my @g = (0, 0);
			for my $t (0, 1) {
				for my $on_ice (@{$event->{on_ice}[$t]}) {
					$CACHES->{players}{$on_ice} ||= $players_c->find_one(
						{ _id => $on_ice + 0 }
					);
					$g[$t] = 1 if $CACHES->{players}{$on_ice}{position} &&
						$CACHES->{players}{$on_ice}{position} eq 'G';
				}
			}
			my $i0 = $str->{on_ice}[0] + (1 - $g[0]);
			my $i1 = $str->{on_ice}[1] + (1 - $g[1]);
			$icecount = $i0 * 1000 + $g[0] * 100 + $i1 * 10 + $g[1];
		}
		else {
			$icecount = 10000 + $str->{on_ice}[0] * 1000 + 100 + $str->{on_ice}[1] * 10 + 1;
			if ($event->{en}) {
				print "T $event->{t} I $icecount\n";
				$icecount -= 1*10**($event->{t}*2);
				$icecount += 1*10**($event->{t}*2+1);
			}
		}
		$collections{$event->{type}}->update_one({
			_id => $event->{_id},
		}, {
			'$set' => { icecount => $icecount },
		}) unless $dry_run;
		$icecounts->{$event->{_id}} = $icecount;
	}
	$icecounts;
}

sub get_stops_and_challenges ($) {

	my $game_id = shift;

	my $CHL_c    = $DB->get_collection('CHL');
	my $STOP_c   = $DB->get_collection('STOP');

	my $stopreasons_c = $DB->get_collection('stopreasons');
	my $stopreasons = [ map {
		$_->{_id}
	} $stopreasons_c->find({ name => { '$regex' => qr/^(CH|VID)/ }})->all() ];
#	print Dumper $stopreasons;
	my @stops_and_challenges = sort {
		$a->{ts} <=> $b->{ts}
			||
		$EVENT_PRECEDENCE{$a->{type}} <=> $EVENT_PRECEDENCE{$b->{type}}
	} (
		$CHL_c->find({game_id => $game_id})->all(),
		$STOP_c->find({
			game_id => $game_id,
			stopreasons => { '$in' => $stopreasons },
		})->all()
	);
	@stops_and_challenges;
}

sub check_missing_challenges ($) {

	my $game_id = shift;

	my $missing_id    = $game_id * 10000 + 9999;
	my $coaches_c    = $DB->get_collection('coaches');
	my $challenges_c = $DB->get_collection('challenges');

	if (defined $BROKEN_CHALLENGES{$missing_id}) {
		my $challenge = $BROKEN_CHALLENGES{$missing_id};
		$challenge->{_id} = $missing_id;
		$challenge->{coach} = $coaches_c->find_one({name => $challenge->{coach_name}})->{_id};
		$challenges_c->replace_one({
			_id => $challenge->{_id},
		}, $challenge, {
			upsert => 1,
		}) unless $ENV{HOCKEYDB_DRYRUN};
	}
}

sub process_broken_challenge ($$$) {

	my $chl       = shift;
	my $challenge = shift;
	my $game      = shift;

	my $coaches_c    = $DB->get_collection('coaches');
	my $challenges_c = $DB->get_collection('challenges');

	if (defined $BROKEN_CHALLENGES{$chl->{_id}}) {
		return 0 unless $BROKEN_CHALLENGES{$chl->{_id}};
		fill_broken($challenge, $BROKEN_CHALLENGES{$chl->{_id}});
		$challenge->{coach} = $challenge->{coach_name} eq 'NHL'
			? 'NHL'
			: $coaches_c->find_one({name => $challenge->{coach_name}})->{_id};
		$challenge->{ts}  = $chl->{ts};
		$challenge->{_id} = $chl->{_id};
		$challenge->{t} = $challenge->{team} eq $game->{teams}[0]{name} ? 0 : 1;
		$challenges_c->replace_one({
			_id => $challenge->{_id},
		}, $challenge, {
			upsert => 1,
		}) unless $ENV{HOCKEYDB_DRYRUN};
		return 0;
	}
	1;
}

sub process_stop_challenge ($$) {

	my $chl = shift;
	my $challenge = shift;

	return 0 unless $chl->{type} eq 'STOP';
	my $stopreasons_c = $DB->get_collection('stopreasons');
	for my $stopreason (@{$chl->{stopreasons}}) {
		my $reason = $stopreasons_c->find_one({_id => $stopreason})->{name};
		next unless $reason =~ /^(CH|VIDEO)/;
		$chl->{t} = $reason =~ /VIS|AWAY/ ? 0 : $reason =~ /LEAGUE|VIDEO/ ? -1 : 1;
		return 0 if $challenge->{ts}
			&& $challenge->{ts} == $chl->{ts} && $challenge->{t} == $chl->{t};
		$chl->{challenge} = $reason;
		$chl->{description} = $reason;
		return 1;
	}
	1;
}

sub configure_nhl_offside_challenge ($$$$) {

	my $challenge = shift;
	my $chl       = shift;
	my $game      = shift;
	my $z         = shift;

	my $STOP_c = $DB->get_collection('STOP');
	my $stop   = $STOP_c->find_one({
		game_id => $game->{_id}+0,
		ts => $chl->{ts}+0,
		description => qr/CHLG/,
	});
	if ($stop) {
		$chl->{t} = $stop->{description} =~ /VIS|AWAY/ ? 0 :
			$stop->{description} =~ /HM|HOME/ ? 1 : -1;
		if ($chl->{t} != -1) {
			$challenge->{winner} = $game->{teams}[ $chl->{t} ]{name};
			$challenge->{loser}  = $game->{teams}[1-$chl->{t}]{name};
			return;
		}
	}

	my $FAC_c   = $DB->get_collection('FAC');
	my $faceoff = $FAC_c->find_one({
		game_id => $game->{_id}+0,
		ts => $chl->{ts}+0
	}) || ($FAC_c->find({
		game_id => $game->{_id}+0,
		ts => { '$gte' =>  $chl->{ts} }
	})->sort({ts => 1})->all())[0];
	if ($faceoff) {
		my $i = ($faceoff->{period} % 2) * 2 - 1;
		if ($faceoff->{coordinates}{x} * $i * $z > 0) {
			$challenge->{winner} = $game->{teams}[1]{name};
			$challenge->{loser}  = $game->{teams}[0]{name};
		}
		else {
			$challenge->{winner} = $game->{teams}[0]{name};
			$challenge->{loser}  = $game->{teams}[1]{name};
		}
	}
	return;
}

sub configure_offside_challenge ($$$$) {

	my $challenge = shift;
	my $chl       = shift;
	my $game      = shift;
	my $z         = shift;

	my $GOAL_c    = $DB->get_collection('GOAL');
	my $goal = $GOAL_c->find_one({
		game_id => $chl->{game_id},
		ts => { '$gte' => $chl->{ts}-1, '$lte' => $chl->{ts}+1 },
	});
	if ($goal) {
		$challenge->{result} = 0;
		$challenge->{winner} = $goal->{team1};
		$challenge->{loser}  = $goal->{team2};
	}
	else {
		$challenge->{result} = 1;
		if ($chl->{t} != -1) {
			$challenge->{winner} = $game->{teams}[ $chl->{t} ]{name};
			$challenge->{loser}  = $game->{teams}[1-$chl->{t}]{name};
			return;
		}
		configure_nhl_offside_challenge($challenge, $chl, $game, $z);
	}
}

sub configure_goalie_challenge ($$$) {

	my $challenge = shift;
	my $chl       = shift;
	my $game      = shift;

	my $GOAL_c = $DB->get_collection('GOAL');
	my $goal   = $GOAL_c->find_one({
		game_id => $chl->{game_id},
		ts => {	'$gte' => $chl->{ts}-1, '$lte' => $chl->{ts}+1 },
		penaltyshot => 0,
	});
	if ($goal) {
		$challenge->{winner} = $goal->{team1};
		$challenge->{loser}  = $goal->{team2};
		$challenge->{result} = $chl->{t} == $goal->{t} ? 1 : 0;
	}
	elsif ($chl->{t} == -1) {
		$challenge->{winner} = 'NHL';
		$challenge->{loser}  = 'NHL';
		$challenge->{result} = -1;
	}
	else {
		my $stopreasons_c = $DB->get_collection('stopreasons');
		my $tv_timeout = $stopreasons_c->find_one({ name => { '$regex' => qr/^(TV.*TIME.*)/ }})->{_id};
		my $STOP_c = $DB->get_collection('STOP');
		my $stop = $STOP_c->find_one({
			game_id => $chl->{game_id},
			ts => {	'$gte' => $chl->{ts}, '$lte' => $chl->{ts}+1 },
			description => { '$regex' => qr/TIME.*OUT/i },
			stopreasons => { '$ne' => $tv_timeout},
		});
		if ($stop) {
			$challenge->{result} = 0;
			$challenge->{winner} = $game->{teams}[1-$chl->{t}]{name};
			$challenge->{loser}  = $game->{teams}[$chl->{t}]{name};
		}
		else {
			$challenge->{result} = 1;
			$challenge->{winner} = $game->{teams}[$chl->{t}]{name};
			$challenge->{loser} = $game->{teams}[1-$chl->{t}]{name};
		}
	}
}

sub configure_league_challenge ($$$$) {

	my $challenge = shift;
	my $chl       = shift;
	my $game      = shift;
	my $z         = shift;

	my $GOAL_c = $DB->get_collection('GOAL');
	my $FAC_c  = $DB->get_collection('FAC');
	my $goal = $GOAL_c->find_one({
		game_id => $game->{_id}+0, ts => {
			'$gte' => $chl->{ts}-1,
			'$lte' => $chl->{ts}+1,
		}
	});
	$challenge->{result} = -1;
	if ($goal) {
		$challenge->{winner} = $goal->{team1};
		$challenge->{loser}  = $goal->{team2};
	}
	else {
		my $faceoff =
			$FAC_c->find_one({
				game_id => $game->{_id}+0,
				ts => $chl->{ts}+0
			}) ||
			($FAC_c->find({
				game_id => $game->{_id}+0,
				ts => { '$gte' =>  $chl->{ts} }
			})->sort({ts => 1})->all())[0] ||
			($FAC_c->find({
				game_id => $game->{_id}+0,
			})->sort({ts => 1})->all())[-1];
		my $i = ($faceoff->{period} % 2) * 2 - 1;
#		debug Dumper $faceoff;
		if ($faceoff->{coordinates}{x} * $i * $z > 0) {
			$challenge->{winner} = $game->{teams}[1]{name};
			$challenge->{loser}  = $game->{teams}[0]{name};
		}
		elsif ($faceoff->{coordinates}{x} * $i * $z < 0) {
			$challenge->{winner} = $game->{teams}[0]{name};
			$challenge->{loser}  = $game->{teams}[1]{name};
		}
	}
}

sub configure_challenge ($$$$) {

	my $challenge = shift;
	my $chl       = shift;
	my $game      = shift;
	my $z         = shift;


	dumper $chl;
	$challenge->{type} =
		$chl->{challenge} =~ /OFF/i        ? 'o' :
			$chl->{challenge} =~ /INTERFER,*/i ? 'i' : 'x';
	$challenge->{coach} = $chl->{t} != -1 ?
		$game->{teams}[$chl->{t}]{coach} : 'NHL';

	for ($challenge->{type}) {
		when ('o') { configure_offside_challenge($challenge, $chl, $game, $z); }
		when ('i') { configure_goalie_challenge( $challenge, $chl, $game);     }
		default    { configure_league_challenge( $challenge, $chl, $game, $z); }
	}
	$challenge->{ts}  = $chl->{ts};
	$challenge->{t}   = $chl->{t};
	$challenge->{_id} = $chl->{_id};
	$challenge->{game_id} = $chl->{game_id};
	$challenge->{source} = $chl->{type};

}

sub generate_challenges ($;$$) {

	my $game    = shift;
	my $dry_run = shift || $ENV{HOCKEYDB_DRYRUN} || 0;

	return if $game->{season} < 2015;
	$DB ||= Sport::Analytics::NHL::DB->new();

	my $GOAL_c   = $DB->get_collection('GOAL');
	my $FAC_c    = $DB->get_collection('FAC');
	my $events_c = $DB->get_collection('events');
	my $coaches_c = $DB->get_collection('coaches');

	my @stops_and_challenges = get_stops_and_challenges($game->{_id});
	return unless @stops_and_challenges;
	check_missing_challenges($game->{_id});

	my $timeouts = [1,1];
	my $zones = get_zones();
	my $z = get_game_coords_adjust($game, $zones);
	my $challenge = {team => ''};
	my $challenge_c = $DB->get_collection('challenges');
	my $agg = [];
	CHL:
	for my $chl (@stops_and_challenges) {
		process_broken_challenge($chl, $challenge, $game) || next;
		next unless $chl->{challenge};
		if ($challenge->{type} && $challenge->{coach} && $challenge->{loser} && defined $challenge->{result} && $challenge->{winner}) {
			next if $challenge->{ts} == $chl->{ts} && $challenge->{t} == $chl->{t};
		}
		(process_stop_challenge($chl, $challenge) || next) if $chl->{type} eq 'STOP';
		$challenge = {};
		if ($chl->{t} != -1 && ! $timeouts->[$chl->{t}]) {
			print "Challenge $game->{_id} @ $chl->{period} / $chl->{time} $game->{teams}[$chl->{t}]{name} cannot happen - timeouts exhausted\n";
			next;
		}
		configure_challenge($challenge, $chl, $game, $z);
		$challenge->{coach_name} = $chl->{t} == -1 ? 'NHL' : $coaches_c->find_one({_id => $challenge->{coach}})->{name};
		$challenge->{to_status} = $timeouts;
		#		print "CHL $challenge->{_id} $chl->{t} $challenge->{type} $challenge->{coach_name}\n";
		push(@{$agg}, {
			game_id => $game->{_id}, ts => $chl->{ts},
			challenger => $chl->{t} == -1 ? 'NHL' : $game->{teams}[$chl->{t}]{name},
			coach => $challenge->{coach_name},
			type => $challenge->{type}, result => $challenge->{result},
			winner => $challenge->{winner}, loser => $challenge->{loser},
		});
		$timeouts->[$chl->{t}]-- unless $challenge->{result};
		$challenge_c->replace_one({
			_id => $challenge->{_id},
		}, $challenge, {
			upsert => 1,
		}) unless $dry_run;
#		exit;
	}
	$agg;
}

sub apply_leading_trailing ($$$$) {

	my $lt      = shift;
	my $delta   = shift;
	my $elapsed = shift;
	my $game    = shift;

	if ($delta == 0)   { $lt->{tied}                             += $elapsed }
	elsif ($delta > 0) { $lt->{leading}{$game->{teams}[1]{name}} += $elapsed }
	else               { $lt->{leading}{$game->{teams}[0]{name}} += $elapsed }

}

sub generate_leading_trailing ($;$) {

	my $game = shift;
	my $dry_run = shift || $ENV{HOCKEYDB_DRYRUN} || 0;

	my $game_id = $game->{_id};
	my $GOAL_c  = $DB->get_collection('GOAL');
	my $games_c = $DB->get_collection('games');
	gamedebug $game, 'Leading/trailing';
	my @goals = $GOAL_c->find({game_id => $game_id + 0})
		->sort({_id => 1})->all();
	my $delta = 0;
	my $lt = {};
	my $last_ts = 0;
	for my $goal (@goals) {
		apply_leading_trailing($lt, $delta, $goal->{ts} - $last_ts, $game);
		$last_ts = $goal->{ts};
		$goal->{t} ? $delta++ : $delta--;
	}
	apply_leading_trailing($lt, $delta, $game->{length} - $last_ts, $game);
	for (0..1) {
		$lt->{leading}{$game->{teams}[$_]{name}} ||= 0;
		$lt->{trailing}{$game->{teams}[1-$_]{name}} =
			$lt->{leading}{$game->{teams}[$_]{name}};
	}
	my $result = $games_c->update_one({
		_id => $game_id + 0
	}, {
		'$set' => {
			leading_trailing => $lt,
		}
	}) unless $dry_run;
	$lt;
}

sub get_offsides_iterator ($) {

	my $game    = shift;

	$CACHES->{stopreasons}{offside} ||=
		$DB->get_collection('stopreasons')->find_one({name => 'OFFSIDE'})->{_id};

	my $os_stopreason = $CACHES->{stopreasons}{offside};
	my $filter = {
		game_id     => $game->{_id},
		stopreasons => $os_stopreason,
	};
	my $STOP_c = $DB->get_collection('STOP');
	my $os_count = $STOP_c->count_documents($filter);
	return unless $os_count;
	my $offside_i = $STOP_c->find($filter);
	$offside_i;
}

sub get_offside_faceoff ($$$) {

	my $offside  = shift;
	my $faceoffs = shift;
	my $zones    = shift;

	my $first_f = firstidx {
		$_->{ts} >= $offside->{ts}
	} @{$faceoffs};
	return if $first_f == -1;
	splice(@{$faceoffs}, 0, $first_f);
	my $faceoff = shift @{$faceoffs};
	return 0 if $faceoff->{zone} ne $zones->{NEU}
		|| ! ($faceoff->{coordinates}{x} && $faceoff->{coordinates}{y});
	$faceoff;
}

sub generate_offsides_info ($;$) {

	my $game    = shift;
	my $dry_run = shift || $ENV{HOCKEYDB_DRYRUN} || 0;

	my $zones  = get_zones();
	my $FAC_c  = $DB->get_collection('FAC');
	my $STOP_c = $DB->get_collection('STOP');
	gamedebug $game, 'Team offsides';
	my $offside_i = get_offsides_iterator($game) || return;
	my @faceoffs = $FAC_c->find({ game_id => $game->{_id} })->sort({ ts => 1 })->all();
	my @updates;
	while (my $offside = $offside_i->next()) {
		my $faceoff = get_offside_faceoff($offside, \@faceoffs, $zones);
		return unless defined $faceoff;
		next   unless $faceoff;
		my $update;
		my $z = get_game_coords_adjust($game, $zones);
		my $i = ($faceoff->{period} % 2) * 2 - 1;
		$update->{t} = $faceoff->{coordinates}{x} * $i * $z > 0 ? 0 : 1;
		$update->{team1} = $game->{teams}[ $update->{t} ]{name};
		$update->{team2} = $game->{teams}[1-$update->{t}]{name};
		$STOP_c->update_one({
			_id => $offside->{_id},
		}, {
			'$set' => $update,
		}) unless $dry_run;
		push(@updates, $update);
	}
	wantarray ? @updates : [@updates];
}

sub generate_gamedays ($;$) {

	my $game = shift;
	my $dry_run = shift || $ENV{HOCKEYDB_DRYRUN} || 0;

	my $games_c = $DB->get_collection('games');
	my $breaks = [];
	for my $t (0,1) {
		my $team = $game->{teams}[$t]{name};
		my $last_ts_a = $games_c->aggregate([
			{
				'$match' => {
					start_ts => { '$lt' => $game->{start_ts} },
					'teams.name' => $team,
				},
			},
			{
				'$group' => {
					_id => '', ts => { '$max' => '$start_ts' },
				},
			}
		]);
		my $last_ts = $last_ts_a->next();
		if (! $last_ts) {
			$breaks->[$t] = 30;
		}
		else {
			$breaks->[$t] = sprintf("%0.f", (
				$game->{start_ts} - $last_ts->{ts}
			) / 86400) - 1;
			$breaks->[$t] = 30 if $breaks->[$t] > 30;
		}
	}
	$DB ||= Sport::Analytics::NHL::DB->new();
	$games_c->update_one({
		_id => $game->{_id},
	}, {
		'$set' => {
			break => $breaks,
		},
	}) unless $dry_run;
	$breaks;
}

sub generate_common_games ($;$) {

	my $game = shift;
	my $dry_run = shift || $ENV{HOCKEYDB_DRYRUN} || 0;

	my $update = [];
	gamedebug $game, 'Common games';
	my $common_games_c = $DB->get_collection('common_games');
	for my $t (0,1) {
		my @ids = sort { $a <=> $b } map($_->{_id},@{$game->{teams}[$t]{roster}});
		for my $x (0..$#ids) {
			for my $y ($x+1..$#ids) {
				my $common_id = ($ids[$x] . $ids[$y]) + 0;
				$common_games_c->update_one({
					_id => $common_id,
				}, {
					'$addToSet' => { games => $game->{_id} }
				}) unless $dry_run;
				push(@{$update}, $common_id);
			}
		}
	}
	$update;
}

sub get_clutch_type ($;$) {

	my $goal = shift;
	my $type = shift || 'gtg';

	return if ! $goal || $goal->{so};

	$type = 'geg' if $goal->{ts} >= 3600;
	my $ltype = $type eq 'geg' ? $type : "l$type";
	my $clutch = $goal->{ts} > 3420 ? $ltype : $type;
	($goal->{_id} => $clutch);
}

sub get_clutch_goals ($@) {

	my $game  = shift;
	my @goals = @_;

	return {} unless @goals;

	return { get_clutch_type($goals[-1]) }
		if $game->{result}[0] == $game->{result}[1] || $game->{so};
	return { get_clutch_type($goals[-1]), get_clutch_type($goals[-2]) } if
		$game->{result}[0] && $game->{result}[1];
	my $win_t = $game->{result}[0] == 2 ? 0 : 1;
	return {} if $goals[-1]->{t} != $win_t;
	my $diff = abs($game->{teams}[0]{score} - $game->{teams}[1]{score});
	return {} if $goals[-$diff]->{t} != $win_t;
	return { get_clutch_type($goals[-1], 'gwg'), get_clutch_type($goals[-2]) }
		if $diff == 1 && @goals > 1;
	return { get_clutch_type($goals[-$diff], 'gwg') }
}

sub generate_clutch_goals ($;$) {

	my $game = shift;
	my $dry_run = shift || $ENV{HOCKEYDB_DRYRUN} || 0;

	my $GOAL_c  = $DB->get_collection('GOAL');
	gamedebug $game, 'Clutch goals';
	my @goals = grep {
		! $_->{so}
	} $GOAL_c->find({game_id => $game->{_id}})->sort({_id => 1})->all();

	my $clutch = get_clutch_goals($game, @goals);
	for my $goal_id (keys %{$clutch}) {
		$GOAL_c->update_one({
			_id => $goal_id + 0,
		}, {
			'$set' => { clutch => $clutch->{$goal_id} }
		}) unless $dry_run;
	}
	$clutch;
}

sub generate_game ($$) {

	my $opts = shift;
	my $game = shift;

	$DB ||= Sport::Analytics::NHL::DB->new();
	my $generated = {};
	my @options = @{$Sport::Analytics::NHL::Usage::OPTS{generator}};
	no strict 'refs';
	for my $option (@options) {
		my $opt = $option->{long};
		next if $opt eq 'all';
		my $_opt = $opt; $_opt =~ s/\-/_/g;
		my $func = "generate_$_opt";
		$generated->{$_opt} = $func->($game)
			if $opts->{all} || $opts->{$_opt};
	}
	use strict 'refs';
	$generated;
}

sub generate ($@) {

	my $opts  = shift;
	my @games = @_;

	$DB ||= Sport::Analytics::NHL::DB->new();
	my $games_c = $DB->get_collection('games');
	if (! @games) {
		my $s1 = $opts->{start_season} || $FIRST_SEASON;
		my $s2 = $opts->{stop_season}  || $CURRENT_SEASON;
		for my $season ($s1 .. $s2) {
			@games = map(
				$_->{_id},
				sort {
					$a->{start_ts} <=> $b->{start_ts}
				} $games_c->find({
					season         => $season,
					($opts->{stage} ? (stage => $opts->{stage}+0) : ()),
				})
					->fields({_id => 1, start_ts => 1})->all()
			);
			for my $game (@games) {
				$game = $games_c->find_one({_id => $game+0}) if ! ref $game;
				next unless $game;
				debug "Generate: $game->{_id}";
				generate_game($opts, $game);
			}
		}
	}
	else {
		for my $game (@games) {
			$game = $games_c->find_one({_id => $game+0}) if ! ref $game;
			next unless $game;
			debug "Generate: $game->{_id}";
			generate_game($opts, $game);
		}
	}
}

1;

=head1 AUTHOR

More Hockey Stats, C<< <contact at morehockeystats.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<contact at morehockeystats.com>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Sport::Analytics::NHL::Generator>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Sport::Analytics::NHL::Generator

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Sport::Analytics::NHL::Generator>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Sport::Analytics::NHL::Generator>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Sport::Analytics::NHL::Generator>

=item * Search CPAN

L<https://metacpan.org/release/Sport::Analytics::NHL::Generator>

=back

=cut
