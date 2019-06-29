package Sport::Analytics::NHL::Normalizer;

use v5.10.1;
use strict;
use warnings FATAL => 'all';
use experimental qw(smartmatch);

use Carp;
use Storable qw(store retrieve dclone);
use POSIX qw(strftime);

use Date::Parse;
use File::Basename;
use List::MoreUtils qw(uniq part);

use Sport::Analytics::NHL::Config qw(:ids :vocabularies :basic);
use Sport::Analytics::NHL::DB;
use Sport::Analytics::NHL::Util qw(:debug :times);
use Sport::Analytics::NHL::Errors;
use Sport::Analytics::NHL::Report;
use Sport::Analytics::NHL::Test;
use Sport::Analytics::NHL::Tools qw(:parser :db);
use Sport::Analytics::NHL::Scraper;

=head1 NAME

Sport::Analytics::NHL::Normalizer - normalize the merged boxscore, providing default values and erasing extra and redundant data.

=head1 SYNOPSYS

Normalizes the merged boxscore, providing default values and erasing extra and redundant data.

These functions first summarize the events in the boxscore to help to try to find incosistencies with the summary in the player stats and in the team stats. Then all data in the boxscore is normalized and standardized, the PSTR, PEND and GEND events are added where necessary, and events are sorted and _id-ed properly.

    use Sport::Analytics::NHL::Normalizer;
    my $event_summary = summarize($boxscore);
    normalize($boxscore);

=head1 GLOBAL VARIABLES

 The behaviour of the tests is controlled by several global variables:
 * $PLAYER_IDS - hashref of all player ids encountered.

=head1 FUNCTIONS

=over 2

=item C<assign_event_ids>

Assigns flowing event ids to the boxscore events of the form:

 * event_id : 1..@events
 * _id: game_id*10000 + event_id

Arguments: the events array reference
Returns: void. Sets the events in the boxscore.

=item C<insert_pend>

Inserts a PEND (Period End) event into the group of events of a given period.

Arguments:

 * The arrayref of the events of the period
 * The number of the period
 * The last event of the period
 * The flag if the event ended the period (e.g. OT goal)

Returns: void. Modifies the period arrayref

=item C<insert_pstr>

Inserts a PSTR (Period Start) event into the group of events of a given period.

Arguments:

 * The arrayref of the events of the period
 * The number of the period
 * The first event of the period

Returns: void. Modifies the period arrayref

=item C<normalize_boxscore>

Does the module's main purpose: normalizes the boxscore

Arguments:

 * boxscore to normalize
 * flag whether to skip summarizing

Returns: the $PLAYER_IDS hashref (q.v.) of all player ids encountered. Boxscore is modified.

=item C<normalize_event_by_type>

Normalizes event according to its type.

Arguments: the event

Returns: void. The event is modified.

=item C<normalize_event_header>

Normalizes event's "header" - the general data such as zone, game, strength, time data.

Arguments:

 * The event
 * The boxscore

Returns: void. The event is modified.

=item C<normalize_event_on_ice>

Normalizes event's on ice player data - makes sure that only NHL player ids are there, and if a team's on ice data is not present, removes it completely.

Argument: the event

Returns: void. The event is modified.

=item C<normalize_event_players_teams>

Normalizes the teams and the players actively participating in the event.

=item C<normalize_events>

Normalizes the boxscore's event and calls the lesser functions according to the event's data.

Argument: the boxscore

Returns: void. The boxscore is modified.

=item C<normalize_goal_event>

Normalizes the specifics of the GOAL event.

Argument: the event

Returns: void. The event is modified.

=item C<normalize_header>

Normalizes the game's header: date, location, attendance etc.

Argument: the boxscore

Returns: void. The boxscore is modified.

=item C<normalize_penl_event>

Normalizes the specifics of the PENL event.

Argument: the event

Returns: void. The event is modified.

=item C<normalize_players>

Normalizes the players on the rosters of the boxscore, their stats and strings.

Argument: the roster from the boxscore.

Returns: void. The roster is modified.

=item C<normalize_result>

Produces and normalizes an extra sub-structure of game result of one of the forms: [2,0], [0,2], [2,1], [1,2], [1,1] - points gained by each of the teams. First number indicates away, second indicates home team.

Argument: the boxscore

Returns: void. The result is set in the boxscore.

=item C<normalize_team>

Normalizes the data of a team in the NHL boxscore - coach, score, name, etc.

Argument: the boxscore team

Returns: void. The team is modified.

=item C<normalize_teams>

Normalizes the teams in the NHL boxscore. Calls normalize_team (q.v.) and normalize_roster (q.v.)

Argument: the boxscore

Returns: void. The boxscore is modified.

=item C<sort_events>

Sorts the events of the boxscore, inserting the PSTR, PEND and GEND events if necessary. The events are sorted by:

 * Period
 * Timestamp
 * Event precedence rank (from PSTR (highest) to GEND (lowest))
 * Event type
 * Event's active team

Argument: the boxscore

Returns: void. The boxscore is modified.

=item C<summarize>

Generates a summary of events of a boxscore. Each playing event is converted into stats of the players and teams participating in it.

Argument: the boxscore

Returns: the summary of the events

=item C<summarize_goal>

Summarizes the data of a GOAL event.

Arguments:

 * the event summary
 * the goal event
 * the boxscore
 * the positions cache generated with Sport::Analytics::NHL::Tools (q.v.)

Returns: void. The event summary is modified.

=item C<summarize_other_event>

Summarizes an event that is not a GOAL or a PENL.

Arguments:

 * the event summary
 * the event

Returns: void. The event summary is modified.

=item C<summarize_penalty>

Summarizes the data of a PENL event.

Arguments:

 * the event summary
 * the penalty event

Returns: void. The event summary is modified.

=item C<add_playoff_info>

Adds information specific to playoff series to the game: the round, the series number and the game number in the series.

 Arguments: the boxscore

 Returns: void. The boxscore is modified.

=back

=cut

use parent 'Exporter';

our @EXPORT = qw(%EVENT_PRECEDENCE set_roster_positions summarize normalize_boxscore);

our $PLAYER_IDS = {};

our %EVENT_PRECEDENCE = (
	PSTR  => 1,
	GIVE  => 7,
	BLOCK => 8,
	HIT   => 8,
	TAKE  => 9,
	SHOT  => 9,
	MISS  => 9,
	GOAL  => 10,
	PENL  => 11,
	CHL   => 12,
	STOP  => 13,
	FAC   => 14,
	PEND  => 98,
	GEND  => 99,
);

our %EVENT_TYPE_TO_STAT = (
	SHOT  => 'shots',
	MISS  => 'misses',
	HIT   => 'hits',
	BLOCK => 'blocked',
	GIVE  => 'giveaways',
	TAKE  => 'takeaways',
	FAC   => 'faceOffWins',
);

=over 2

=item C<set_roster_positions>

Prepares a hash with positions of each player id in the boxscore for future caching and resolving purposes.

Arguments: the boxscore
Returns: the positions hash.

=back

=cut

sub set_roster_positions ($) {

	my $boxscore = shift;
	my $positions = {};

	for my $t (0,1) {
		my $team = $boxscore->{teams}[$t];
		for my $player (@{$team->{roster}}) {
			$positions->{$player->{_id}} = $player->{position};
		}
	}
	$positions;
}

sub summarize_goal ($$$$;$) {

	my $event_summary = shift;
	my $event         = shift;
	my $boxscore      = shift;
	my $positions     = shift;
	my $no_stats      = shift || 0;

	$event->{assists} ||= [];
	for my $assist (@{$event->{assists}}) {
		$event_summary->{$assist}{assists}++;
		push(@{$event_summary->{stats}}, 'assists');
	}
	$event_summary->{$boxscore->{teams}[$event->{t}]{name}}{score}++;
	$positions->{$event->{player1}} ||= 'S';
	if ($event->{player1} && ! $SPECIAL_EVENTS{$boxscore->{_id}}) {
#		dumper $positions, $event;
		if ($positions->{$event->{player1}} eq 'G') {
			$event_summary->{$event->{player1}}{g_goals}++;
			$event_summary->{$event->{player1}}{g_shots}++;
			push(@{$event_summary->{stats}}, 'g_goals', 'g_shots');
		}
		else {
			$event_summary->{$event->{player1}}{goals}++;
			$event_summary->{$event->{player1}}{shots}++;
			push(@{$event_summary->{stats}}, 'goals', 'shots');
		}
	}
	if ($event->{player2}) {
		$event_summary->{$event->{player2}}{shots}++;
		$event_summary->{$event->{player2}}{goalsAgainst}++ if $event->{ts} && ! $event->{en};
		push(@{$event_summary->{stats}}, 'goalsAgainst', 'shots');
	}
	delete $event_summary->{stats} if $no_stats;
}

sub summarize_penalty ($$;$) {

	my $event_summary = shift;
	my $event = shift;
	my $no_stats = shift || 0;

	$event_summary->{$event->{player1}}{penaltyMinutes} += $event->{length};
	push(@{$event_summary->{stats}}, 'penaltyMinutes');
	if ($event->{servedby}) {
		$event_summary->{$event->{servedby}}{servedbyMinutes} += $event->{length};
		push(@{$event_summary->{stats}}, 'servedbyMinutes');
		$event_summary->{$event->{servedby}}{servedby}++;
		push(@{$event_summary->{stats}}, 'servedby');
	}
	elsif ($event->{_servedby}) {
		$event_summary->{$event->{player1}}{_servedbyMinutes} += $event->{length};
	}
	delete $event_summary->{stats} if $no_stats;
}

sub summarize_other_event ($$) {

	my $event_summary = shift;
	my $event         = shift;

	return unless $event->{sources}{PL} || $event->{sources}{BS};
	if ($event->{type} eq 'FAC') {
		$event->{player1} ||= $UNKNOWN_PLAYER_ID;
		$event->{player2} ||= $UNKNOWN_PLAYER_ID;
		$event_summary->{$event->{player1}}{faceoffTaken}++;
		$event_summary->{$event->{player2}}{faceoffTaken}++;
		push(@{$event_summary->{stats}}, 'faceoffTaken');
	}
	$event_summary->{$event->{player1}}{$EVENT_TYPE_TO_STAT{$event->{type}}}++;
}

sub summarize ($) {

	my $boxscore = shift;

	debug "Generating event summary";
	my $event_summary = {so => [0,0], stats => []};
	my $positions = set_roster_positions($boxscore);
	my @stats = qw(goals assists);

	for my $event (@{$boxscore->{events}}) {
		if ($event->{so}) {
			$event_summary->{so}[$event->{t}]++ if $event->{type} eq 'GOAL';
			next unless $event->{type} eq 'PENL';
		}
		for ($event->{type}) {
			when ('GOAL') { summarize_goal($event_summary, $event, $boxscore, $positions); }
			when ('PENL') { summarize_penalty($event_summary, $event); }
			when ([ qw(SHOT MISS HIT BLOCK TAKE GIVE FAC) ]) {
				summarize_other_event($event_summary, $event);
				push(@stats, $EVENT_TYPE_TO_STAT{$event->{type}});
			}
		}
	}
	my $so = $event_summary->{so};
	if ($so->[0] || $so->[1]) {
		die "Strange shootout count for $boxscore->{_id}" if $so->[0] == $so->[1];
		$event_summary->{$boxscore->{teams}[$so->[0] > $so->[1] ? 0 : 1]{name}}{score}++;
		$event_summary->{so} = $so->[0] > $so->[1] ? [ 1, 0 ] : [ 0, 1 ];
	}
	$event_summary->{stats} = [ uniq @{$event_summary->{stats}}, @stats ];
	for my $t (0,1) {
		for my $player (@{$boxscore->{teams}[$t]{roster}}) {
			$event_summary->{$player->{_id}} ||= {};
		}
	}
	for my $key (keys %{$event_summary}) {
		next unless $key =~ /^\d{7}$/;
		for my $stat (@{$event_summary->{stats}}) {
			$event_summary->{$key}{$stat} ||= 0;
		}
	}
	$event_summary;
}

sub normalize_result ($) {

	my $game = shift;
	if ($game->{teams}[0]{score} == $game->{teams}[1]{score}) {
		$game->{result} = [ 1, 1 ];
	}
	elsif ($game->{teams}[0]{score} > $game->{teams}[1]{score}) {
		$game->{result} = [ 2, $game->{ot} && $game->{season} >= 1999 ? 1 : 0 ];
		$game->{winner} = $game->{teams}[0]{name};
		$game->{loser}  = $game->{teams}[1]{name};
	}
	else {
		$game->{result} = [ $game->{ot} && $game->{season} >= 1999 ? 1 : 0, 2 ];
		$game->{winner} = $game->{teams}[1]{name};
		$game->{loser}  = $game->{teams}[0]{name};
	}
}

sub normalize_header ($) {

	my $game = shift;

	debug "Normalizing header";
	$game->{date} = strftime("%Y%m%d", localtime($game->{start_ts}));
	if ($game->{location}) {
		$game->{location} =~ s/^\s+//;
		$game->{location} =~ s/\s+$//;
		$game->{location} =~ s/\s+/ /g;
		$game->{location} = uc $game->{location};
	}
	for my $field (qw(last_updated _id attendance month date ot start_ts stop_ts stage season season_id)) {
		$game->{$field} += 0;
	}
	$game->{tz} ||= 'EST';
	normalize_result($game);

	delete @{$game}{qw(_t type scratches resolve_cache)};
}

sub normalize_team ($) {

	my $team = shift;

	for my $stat (keys %{$team->{stats}}) {
		$team->{stats}{$stat} += 0.0;
	}
	for my $field (qw(pull shots score)) {
		$team->{$field} += 0;
	}
	delete @{$team}{qw(teamid orig _decision)};
	my $roster = [];
	for my $player (@{$team->{roster}}) {
		push(@{$roster}, $player)
			unless $player->{_id} =~ /^80/ || (!$player->{shifts} && grep {
				$player->{_id} eq $_
			} @{$team->{scratches}});
	}
	$team->{roster} = $roster;
	$team->{scratches} ||= [];
}

sub normalize_players ($) {

	my $team = shift;

	for my $player (@{$team->{roster}}) {
		for my $toi (qw(evenTimeOnIce shortHandedTimeOnIce powerPlayTimeOnIce timeOnIce)) {
			$player->{$toi} = get_seconds($player->{$toi})
				if defined $player->{$toi} && $player->{$toi} =~ /\:/;
		}
		unless ($player->{position} eq 'G') {
			delete $player->{wl};
		}
		else {
			$player->{decision} ||= delete $player->{wl} || 'N';
		}
		if (!
			defined $player->{faceoffTaken}
			|| $player->{faceoffTaken} eq -1
		) {
			for (grep { /faceoff/i } keys %{$player}) {
				delete $player->{$_};
			}
		}
		for my $p (1..15) {
			my $_p = "p$p";
			if (defined $player->{$_p}) {
				$player->{$_p} =~ /(\d+)\-(\d+)/;
				$player->{"SHOT$p"} = [ $1, $2 ];
				delete $player->{$_p};
			}
		}
		delete @{$player}{'Saves - Shots', qw(void EV SH PP TOITOT pt)};
		for (keys %{$player}) {
			when ('faceOffPercentage') {
				$player->{$_} = $player->{faceoffTaken}
					? $player->{faceOffWins} / $player->{faceoffTaken}
					: 0;
			}
			when ('status') { $player->{$_} //= ' ' }
			when ('start')  { $player->{$_} //=  2  }
			when ($_ ne 'plusMinus' && $player->{$_} eq -1 ) {
				delete $player->{$_}
			}
		}
		$player->{team} = $team->{name};
		$PLAYER_IDS->{$player->{_id}} = \$player;
	}
	for my $player (@{$team->{scratches}}) {
		$player += 0;
	}
}

sub normalize_teams ($) {

	my $boxscore = shift;
	$PLAYER_IDS = {};

	for my $t (0,1) {
		my $team = $boxscore->{teams}[$t];
		normalize_team($team);
		normalize_players($team);
	}
}

sub normalize_event_header ($$) {

	my $event    = shift;
	my $game     = shift;

	$event->{game}  ||= $game->{_id};
	$event->{game_id} = delete $event->{game};
	$event->{zone}    = uc(delete $event->{location} || 'UNK')
		unless ! $event->{location} && is_noplay_event($event);
	$event->{strength} ||= 'XX';
	$event->{strength} =~ s/\W//g;
	if ($event->{ts} > $event->{period} * 1200) {
		$event->{ts} = $event->{ts} % 1200 + ($event->{period}-1)*1200;
		$event->{time} = sprintf(
			"%d:%02d",
			($event->{ts}-($event->{period}-1)*1200)/60,
			$event->{ts}%60
		);
	}
	delete @{$event}{qw(bsjs_id event_code event_idx file teamid)};
	for my $field (qw(game_id id period season stage so t ts distance)) {
		$event->{$field} += 0 if defined $event->{$field};
	}
	$event->{penaltyshot} += 0 if defined $event->{penaltyshot};
}

sub normalize_event_players_teams ($$) {

	my $event = shift;
	my $game  = shift;

	if (! $event->{team2} && defined $event->{t} && $event->{t} != -1) {
		$event->{team2} = $game->{teams}[1-$event->{t}]{name};
	}
	for my $field (qw(en player1 player2 assist1 assist2)) {
		if ($field =~ /assist(\d)/) {
			my $as = $1;
			if ($event->{$field} && $event->{$field} =~ /\D/ && $event->{assists}[$as-1] !~ /\D/) {
				$event->{$field} = $event->{assists}[$as-1];
			}
		}
		$event->{$field} += 0 if exists $event->{$field};
	}
}

sub normalize_event_on_ice ($) {

	my $event = shift;
	if (is_noplay_event($event) && (
		! $event->{on_ice} || ! @{$event->{on_ice}} || @{$event->{on_ice}} != 2 || ! $event->{on_ice}[0] || ! $event->{on_ice}[1])
	) {
		delete $event->{on_ice};
		return;
	}
	if ($event->{on_ice} && @{$event->{on_ice}}
		&& @{$event->{on_ice}[0]} && @{$event->{on_ice}[1]}) {
		for my $t (0,1) {
			$event->{on_ice}[$t] = [grep {
				/\d/ && ! /^800/
			} @{$event->{on_ice}[$t]} ];
		}
	}
	if ($event->{on_ice} && @{$event->{on_ice}}
		&& @{$event->{on_ice}[0]} && @{$event->{on_ice}[1]}) {
		for my $o (@{$event->{on_ice}}) {
			for my $on_ice (@{$o}) {
				$on_ice += 0;
			}
		}
	}
	else {
		delete $event->{on_ice};
	}
}

sub normalize_goal_event ($) {

	my $event = shift;

	$event->{en}          ||= 0;
	$event->{gwg}         ||= 0;
	$event->{assists}     ||= [];
	if ($event->{assist1}) {
		$event->{assists}[0] = $event->{assist1};
	}
	if ($event->{assist2}) {
		$event->{assists}[1] = $event->{assist2};
	}
	$event->{assist1} = $event->{assists}[0];
	$event->{assist2} = $event->{assists}[1];
	if (! $event->{player2} && $event->{on_ice} && @{$event->{on_ice}}) {
		for my $o (@{$event->{on_ice}[1-$event->{t}]}) {
			$event->{player2} = $o if ${$PLAYER_IDS->{$o}}->{position} eq 'G';
		}
	}
}

sub normalize_penl_event ($) {

	my $event = shift;

	$event->{length} += 0;
	$event->{servedby} += 0 if defined $event->{servedby};
	if ($event->{penalty} =~ /PS\s+\-\s+(\S.*)/) {
		debug "Converting a PS penalty";
		$event->{penalty} = $1;
		$event->{length} = 0;
		$event->{ps_penalty} = 1;
	}
	delete $event->{servedby} if $event->{servedby} && $event->{servedby} =~ /^80/;
}

sub normalize_event_by_type ($) {

	my $event = shift;

	for ($event->{type}) {
		when ('FAC')  { $event->{winning_team} = resolve_team($event->{winning_team}); }
		when ('GOAL') { normalize_goal_event($event); }
		when ('PENL') { normalize_penl_event($event); }
	}
	if ($event->{type} ne 'GOAL') {
		delete $event->{$_} for qw(assist1 assist2 assists);
	}

	if ($event->{type} eq 'MISS' || $event->{type} eq 'GOAL'
		|| $event->{type} eq 'SHOT' || $event->{type} eq 'BLOCK') {
		$event->{shot_type}   ||= 'UNKNOWN';
		$event->{penaltyshot} ||= 0;
	}

	if ($event->{player2} && $event->{player2} !~ /^80/ && defined $REVERSE_STAT{$event->{player2}}) {
		${$PLAYER_IDS->{$event->{player2}}}->{$REVERSE_STAT{$event->{player2}}} ||= 0;
		${$PLAYER_IDS->{$event->{player2}}}->{$REVERSE_STAT{$event->{player2}}}++;
	}
	my @fields = keys %{$event};
	for my $field (@fields) {
		if (! defined $event->{$field}) {
			delete $event->{$field};
			next;
		}
		next if $field eq 'file' || ref $event->{$field};
		if ($event->{$field} =~ /^\d+$/) {
			$event->{$field} += 0;
		}
		else {
			$event->{$field} = uc $event->{$field};
		}
	}
}

sub normalize_events ($) {

	my $boxscore = shift;

	my $gp = scalar @{$boxscore->{periods}};
	for my $event (@{$boxscore->{events}}) {
		$EVENT = $event;
		if ($event->{period} == 4 && $gp < 4) {
			if ($event->{time} eq '0:00') {
				$event->{period} = 3;
				$event->{ot} = 0;
				$event->{time} = '20:00';
			}
			else {
				push(
					@{$boxscore->{periods}},
					{
						type => 'OVERTIME',
						start_ts => $boxscore->{periods}[-1]{stop_ts} + 300,
						stop_ts  => $boxscore->{periods}[-1]{stop_ts} + 900,
						id => 4,
						score => [0,0,0,0],
					},
				);
				$gp = @{$boxscore->{periods}};
			}
		}
		normalize_event_header($event, $boxscore);
		normalize_event_players_teams($event, $boxscore);
		normalize_event_on_ice($event);
		normalize_event_by_type($event);
	}
}

sub insert_pstr ($$$) {

	my $period = shift;
	my $p      = shift;
	my $event  = shift;

	debug "Inserting PSTR";
	unshift(
		@{$period},
		{
			ts => 0, period => $p, stage => $event->{stage}, season => $event->{season},
			game_id => $event->{game_id} || $event->{_id}, time => '00:00', type => 'PSTR',
		},
	);
}

sub insert_pend ($$$$) {

	my $period  = shift;
	my $p       = shift;
	my $event   = shift;
	my $is_last = shift;

	debug "Inserting PEND";
	my $pend_event = {
		ts => 0, period => $p,
		stage => $event->{stage}, season => $event->{season},
		game_id => $event->{game_id} || $event->{_id},
		time => '00:00', type => 'PEND',
	};
	if ($p <= 3 || ! $is_last && $event->{stage} != $REGULAR) {
		$pend_event->{ts}   = $p*1200;
		$pend_event->{time} = '20:00';
	}
	elsif ($is_last) {
		$pend_event->{ts}   = $event->{ts} ||
			($event->{stage} == $REGULAR ? 3900 : $p * 1200);
		$pend_event->{time} = $event->{time} ||
			($event->{stage} == $REGULAR ? '5:00' : '20:00');
	}
	else {
		$pend_event->{ts}   = $event->{season} < 1942 ? 4200 : 3900;
		$pend_event->{time} = $event->{season} < 1942 ? '10:00' : '5:00';
	}
	push(@{$period}, $pend_event);
}

sub sort_events ($) {

	my $boxscore = shift;

	my $events = $boxscore->{events};
	my $gp     = $boxscore->{periods};

	my $sorted_events = [];
	my @so_events = part {
		($_->{period} == 5 && $boxscore->{stage} == $REGULAR) ? 1 : 0;
	} @{$events};
	$so_events[0] ||= [];
	my $so_cache = {};
	my $so_count = 0;
	for my $so_event (@{$so_events[1]}) {
		if ($so_event->{player1} && $so_event->{type} ne 'PENL') {
			$so_count++;
			if ($so_cache->{$so_event->{player1}} && ! $SAME_SO_TWICE{$boxscore->{_id}} && $so_count <= 36) {
				dumper $so_event;
				die "$so_count Same player shoots twice!";
			}
			$so_cache->{$so_event->{player1}} = 1;
		}
	}
	my @events_by_period = (( part {
		my $x = $_->{period}
	} sort {
		$a->{period} <=> $b->{period}
		|| $a->{ts}  <=> $b->{ts}
		|| $EVENT_PRECEDENCE{$a->{type}} <=> $EVENT_PRECEDENCE{$b->{type}}
		|| $a->{type} cmp $b->{type}
		|| $b->{t}   <=> $a->{t}
	} @{$so_events[0]}), @{$so_events[1]} ? [@{$so_events[1]}] : ());
	splice(@events_by_period, 4, 0, []) if @{$so_events[1]} && @events_by_period == 5;
	my $ot_end =
		$boxscore->{result}[0] != $boxscore->{result}[1]
		&& ! $boxscore->{so};
	$events_by_period[-1] =
		[ grep { $_->{type} ne 'GEND' } @{$events_by_period[-1]} ]
		if @events_by_period;
	my $periods = $#events_by_period > 3 ? $#events_by_period : 3;
	$periods = scalar @{$gp} if $periods < scalar @{$gp};
#		dumper $gp, scalar(@events_by_period), $periods;
	#dumper \@events_by_period;
#	exit;
	for my $p (1..$periods) {
		my $period = $events_by_period[$p] || [];
		insert_pstr($period, $p, $events_by_period[$p]->[0] || $boxscore)
			unless $period->[0] && $period->[0]{type}  eq 'PSTR';
		insert_pend($period, $p, $events_by_period[$p]->[-1] || $boxscore, $p == $periods && $ot_end)
			unless $period->[0] && $period->[-1]{type} eq 'PEND';
		my $e = -1;
		$period = [
			grep {
				$e++;
				$_->{type} eq 'PSTR' && $e > 0
					|| $_->{type} eq 'PEND' && $e < $#{$period}
					? () : $_
			} @{$period}
		];
		push(@{$sorted_events}, @{$period});
	}
	push(
		@{$sorted_events},
		dclone $sorted_events->[-1]
	);
	$sorted_events->[-1]{type} = 'GEND';
##	dumper $sorted_events;
#	exit;
	$boxscore->{events} = $sorted_events;
}

sub assign_event_ids ($) {

	my $events = shift;

	for my $e (1..@{$events}) {
		my $event = $events->[$e-1];
		$event->{event_id} = $e;
		$event->{_id}      = $event->{game_id} * 10000 + $e;
	}
}

sub add_playoff_info ($) {

	my $boxscore = shift;

	return unless $boxscore->{stage} eq $PLAYOFF;
	my $game = $boxscore->{_id};
	$boxscore->{round}   = substr($game, 6, 1);
	$boxscore->{pairing} = substr($game, 7, 1);
	$boxscore->{number}  = substr($game, 8, 1);
}

sub normalize_boxscore ($;$) {

	my $boxscore = shift;
	my $no_summarize = shift || 0;
	$PLAYER_IDS = {};
	unless ($no_summarize) {
		my $event_summary = summarize($boxscore);
		test_consistency($boxscore, $event_summary);
	}
	normalize_header($boxscore);
	normalize_teams($boxscore);
	normalize_events($boxscore);
	sort_events($boxscore);
	assign_event_ids($boxscore->{events});
	add_playoff_info($boxscore) if $boxscore->{stage} == $PLAYOFF;
	$boxscore->{length} = $boxscore->{events}[-1]{ts};
	undef $EVENT;
	return $PLAYER_IDS;
}

=head1 AUTHOR

More Hockey Stats, C<< <contact at morehockeystats.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<contact at morehockeystats.com>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Sport::Analytics::NHL::Normalizer>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Sport::Analytics::NHL::Normalizer

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Sport::Analytics::NHL::Normalizer>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Sport::Analytics::NHL::Normalizer>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Sport::Analytics::NHL::Normalizer>

=item * Search CPAN

L<https://metacpan.org/release/Sport::Analytics::NHL::Normalizer>

=back
