package Sport::Analytics::NHL::Report::BS;

use v5.10.1;
use strict;
use warnings FATAL => 'all';
use utf8;

use experimental qw(smartmatch);

use Encode;
use Storable qw(dclone);

use JSON;
use Try::Tiny;
use Text::Unidecode;

use parent 'Sport::Analytics::NHL::Report';

use Sport::Analytics::NHL::Config qw(:ids);
use Sport::Analytics::NHL::Errors;
use Sport::Analytics::NHL::Tools qw(:basic :db :parser);
use Sport::Analytics::NHL::Util qw(:debug :utils :times);

use Data::Dumper;

=head1 NAME

Sport::Analytics::NHL::Report::BS - Class for the Boxscore JSON report

=head1 SYNOPSYS

Class for the Boxscore JSON report.

    use Sport::Analytics::NHL::Report::BS;
    my $report = Sport::Analytics::NHL::Report::BS->new($json)
    $report->process();

=head1 METHODS

=over 2

=item C<new>

Create the Boxscore object with the JSON.

=item C<process>

Process the Boxscore into the object compatible with further processing, etc.

=item C<assign_specific_event_data>

Assign specific event data

 Arguments:
 * the event hashref we're building
 * the original event from the JSON
 Returns: void.

=item C<assign_specific_goal_data>

Assign specific goal event data

 Arguments:
 * the goal event hashref we're building
 * the original goal event from the JSON
 Returns: void.

=item C<assign_specific_penalty_data>

Assign specific penalty event data

 Arguments:
 * the penalty event hashref we're building
 * the original penalty event from the JSON
 Returns: void.

=item C<check_broken>

Checks if the event is marked as 'BROKEN' and assigns default values to it.

 Arguments:
 * the event hashref we're building
 * the original event from the JSON
 Returns: void.

Note: should probably be replaced with fill_broken from the Tools package.

=item C<fix_old_goalie>

Fixes the goalie scored upon in the goal events of old boxscores (pre-1987).

 Arguments: the goal event
 Returns: void.

=item C<fix_servedby>

Fixes the served by data in a penalty event, when a bench or coach penalty is assigned in error to a player.

 Arguments: the event
 Returns: void.

=item C<place_players>

Assigns the player1, player2 and servedby players in a variety of events

 Arguments:
 * the event hashref we're building
 * the original event from the JSON
 Returns: void.

=item C<set_broken_player>

Marks a player entry in the boxscore as a broken one beyond repair

 Arguments: the player hashref
 Returns: void.

=item C<set_events>

Converts the events as specified in the boxscore JSON into the $boxscore->{events} arrayref with adjusted fields.

 Arguments: the JSON events
 Returns: void.

=item C<set_extra_header_data>

Sets some extra header data not handled by any explicit methods: status, location, shootout data etc.
 Arguments: the boxscore JSON hashref
 Returns: void.

=item C<set_id_data>

Sets the game id data: the season, the stage, the season ID, and the overall 9-digit id.

 Arguments: the ID field of the boxscore JSON
 Returns: void.

=item C<set_officials>

Sets the officials for the game.

 Arguments: the officials' section in the boxscore JSON hashref
 Returns: void.

=item C<set_periods>

Set the game periods data from the boxscore JSON hashref

 Arguments: the boxscore JSON hashref
 Returns: void.

=item C<set_player>

Sets the player in a team roster from the boxscore JSON hashref in accordance with our data model.

 Arguments: the player live data entry from the boxscore JSON hashref
 Returns: void.

=item C<set_stars>

Parses the game stars. Not in use.

=item C<set_teams>

Sets the team data and the team rosters from the boxscore JSON hashref in accordance with our data model.

 Arguments: the boxscore JSON hashref
 Returns: void.

=item C<set_timestamps>

Sets the start, end and last updated timestamps for the game from the date strings in the JSON

 Argument: the boxscore JSON hashref
 Returns: void.

=item C<build_resolve_cache>

Builds a resolution cache for the roster, with keys as numbers of players pointing at their whole player record in the game. The players who are not numbered are stored as reference to their record in a special list [names].

 Arguments: none
 Returns: void. Sets $self->{resolve_cache}

Note: the caches are per team, and valid for one game only.

=back

=cut

our @JS_IGNORED_EVENT_TYPES = qw(
	PERIOD_READY GAME_SCHEDULED PERIOD_OFFICIAL GAME_OFFICIAL
	SHOOTOUT_COMPLETE EARLY_INT_END EARLY_INT_START EMERGENCY_GOALTENDER
);

our %PLAYER_ID_MAP = (
	Winner   => 'player1',
	Loser    => 'player2',
	Hitter   => 'player1',
	Hittee   => 'player2',
	Shooter  => 'player1',
	Blocker  => 'player2',
	PlayerID => 'player1',
	PenaltyOn => 'player1',
	DrewBy    => 'player2',
	ServedBy  => 'servedby',
	Scorer    => 'player1',
	Assist    => 'void',
	Goalie    => 'player2',
);

sub new ($$;$) {

	my $class        = shift;
	my $json         = shift;
	my $ignore_state = shift || 0;

	my $code = JSON->new();
	$code->utf8(1);
	my $self;
	return undef unless $json;
	try { $self = {json => $code->decode(decode "UTF-8", $json)} }
		catch { $self = {json => $code->decode($json)} };
	return undef unless	$ignore_state ||
		$self->{json}{gameData}{status}{abstractGameState}
		&& $self->{json}{gameData}{status}{abstractGameState} eq 'Final';
	bless $self, $class;

	$self;
}

sub set_id_data ($;$) {

	my $self    = shift;
	my $id_data = shift || $self->{json}{gamePk};

	my $season_info    = parse_nhl_game_id($id_data);
	$self->{season}    = $season_info->{season};
	$self->{stage}     = $season_info->{stage};
	$self->{season_id} = $season_info->{season_id};
	$self->{_id}       = $self->{season} * 100000 + $self->{stage} * 10000 + $self->{season_id};
}

sub set_timestamps ($$) {

	my $self = shift;
	my $json = shift;

	my $ts = $json->{metaData}{timeStamp}; $ts =~ s/_/ /;
	$self->{last_updated} = str3time($ts);
	$self->{start_ts}     = str3time($json->{gameData}{datetime}{dateTime});
	$self->{stop_ts}      = $json->{gameData}{datetime}{endDateTime}
		? str3time($json->{gameData}{datetime}{endDateTime})
		: $self->{start_ts} + 9000;

}

sub set_extra_header_data ($$) {

	my $self = shift;
	my $json = shift;

	$self->{status}       = 'FINAL';
	$self->{location}     = $json->{gameData}{venue}{name};
	if ($json->{liveData}{linescore}{hasShootout}) {
		$self->{so} = 1;
		$self->{shootout} = dclone $json->{liveData}{linescore}{shootoutInfo};
		delete $self->{shootout}{startTime};
	}

}

sub set_officials ($$) {

	my $self      = shift;
	my $officials = shift;

	$self->{officials} = {
		referees => [],
		linesmen => [],
	};
	for my $official (@{$officials}) {
		my $o = {
			name        => unidecode(uc $official->{official}{fullName}),
			official_id => $official->{official}{id} || 0,
		};
		push(
			@{$self->{officials}{
				$official->{officialType} eq 'Referee' ? 'referees' : 'linesmen'
			}}, $o
		);
	}
}

sub set_broken_player ($$) {

	my $self   = shift;
	my $player = shift;

	if (
		$BROKEN_PLAYERS{BS}->{$self->{_id}}
		&& $BROKEN_PLAYERS{BS}->{$self->{_id}}->{$player}
		&& $BROKEN_PLAYERS{BS}->{$self->{_id}}->{$player} == -1
	) {
		return {
			broken => 1,
			_id    => $player,
			number => $self->{broken_number}++,
		};
	}
}

sub set_player ($$) {

	my $self      = shift;
	my $ld_player = shift;

	unless ($ld_player->{stats}{skaterStats} || $ld_player->{stats}{goalieStats}) {
		$ld_player->{stats}{
			$ld_player->{position}{code} eq 'G' ? 'goalieStats' : 'skaterStats'
		} = { broken => 1 },
	}
	my $player = {
		_id      => $ld_player->{person}{id},
		name     => uc unidecode($ld_player->{person}{fullName}),
		number   => $ld_player->{jerseyNumber},
		position => uc $ld_player->{position}{code},
		$ld_player->{stats}{skaterStats}           ?
			%{dclone $ld_player->{stats}{skaterStats}} :
			%{dclone ($ld_player->{stats}{goalieStats} || {})},
	};
	if ($BROKEN_PLAYERS{BS}->{$self->{_id}}
		&& $BROKEN_PLAYERS{BS}->{$self->{_id}}->{$ld_player->{person}{id}}
		&& ref $BROKEN_PLAYERS{BS}->{$self->{_id}}->{$ld_player->{person}{id}}) {
		for my $stat (keys %{$BROKEN_PLAYERS{BS}->{$self->{_id}}->{$ld_player->{person}{id}}}) {
			$player->{$stat} = $BROKEN_PLAYERS{BS}->{$self->{_id}}->{$ld_player->{person}{id}}{$stat};
		}
	}
	$player->{pim} ||= ($player->{penaltyMinutes} || 0) if $player->{position} eq 'G';
	$player;
}

sub set_teams ($$) {

	my $self = shift;
	my $json = shift;

	$self->{teams}        = [];
	$self->{_score} = [
		$json->{liveData}{linescore}{teams}{away}{goals},
		$json->{liveData}{linescore}{teams}{home}{goals},
	];
	my $t = 0;
	for my $team_key (qw(away home)) {
		$self->{_t} = $t;
		my $ldb_team = $json->{liveData}{boxscore}{teams}{$team_key};
		my $ldl_team = $json->{liveData}{linescore}{teams}{$team_key};
		my $team = {
			orig      => $ldb_team->{team}{triCode} || $json->{gameData}{teams}{$team_key}{abbreviation},
			stats     => $ldb_team->{teamStats}{teamSkaterStats},
			roster    => [],
			scratches => $ldb_team->{scratches},
			coach     => $ldb_team->{coaches}[0]{person}{fullName}
				? uc $ldb_team->{coaches}[0]{person}{fullName}
				: 'UNKNOWN COACH',
			score     => $ldl_team->{goals},
			shots     => $ldl_team->{shotsOnGoal},
			pull      => $ldl_team->{goaliePulled},
			teamid    => $ldl_team->{team}{id},
		};
		$team->{name} = resolve_team($team->{orig});
		$team->{coach} = $BROKEN_COACHES{$team->{coach}} if $BROKEN_COACHES{$team->{coach}};
		$self->{broken_number} = 101;
		for my $ld_player (values %{$ldb_team->{players}}) {
			my $player =
				$self->set_broken_player($ld_player->{person}{id}) ||
				$self->set_player($ld_player);
			push(@{$team->{roster}}, $player);
			$team->{_decision} = $player->{decision} if ($player->{decision});
		}
		push(
			@{$team->{roster}},
			@{$MISSING_PLAYERS{$self->{_id}}->[$t]}
		) if ($MISSING_PLAYERS{$self->{_id}}
			  && @{$MISSING_PLAYERS{$self->{_id}}->[$t]});
		$self->force_decision($team) unless $team->{_decision};
		push(@{$self->{teams}}, $team);
		$t++;
	}
}

sub set_stars ($$) {

	my $self = shift;
	my $json = shift;

	$self->{stars} = [];
	for my $star (qw(firstStar secondStar thirdStar)) {
		push(@{$self->{stars}}, $json->{liveData}{decisions}{$star}{id})
			if $json->{liveData}{decisions}{$star};
	}
}

sub set_periods ($$) {

	my $self = shift;
	my $json = shift;

	$self->{periods} = [];
	my $p = 1;
	for my $ld_period (@{$json->{liveData}{linescore}{periods}}) {
		my $period = {
			id       => $p,
			start_ts => $ld_period->{startTime}
				? str3time($ld_period->{startTime})
				: $self->{start_ts} + 2250*($p-1),
			stop_ts  => $ld_period->{endTime}
				? str3time($ld_period->{endTime})
				: $self->{start_ts} + 2250*$p-1,
							score    => [
				$ld_period->{away}{goals}, $ld_period->{away}{shotsOnGoal},
				$ld_period->{home}{shotsOnGoal}, $ld_period->{home}{goals},
			],
			type     => $ld_period->{periodType},
		};
		push(@{$self->{periods}}, $period);
		$self->{ot} ||= $ld_period->{periodType} eq 'OVERTIME' ? 1 : 0;
		$p++;
	}
}

sub place_players ($$) {

	my $event    = shift;
	my $ld_event = shift;

	for my $player (@{$ld_event->{players}}) {
		$event->{$PLAYER_ID_MAP{$player->{playerType}}} = $player->{player}{id};
	}
}

sub assign_specific_penalty_data ($$) {

	my $event    = shift;
	my $ld_event = shift;

	place_players($event, $ld_event);
	$event->{penalty}  = $ld_event->{result}{secondaryType};
	$event->{severity} = uc($ld_event->{result}{penaltySeverity} || '');
	$event->{length}   = $ld_event->{result}{penaltyMinutes};
	if ($event->{penalty} =~ /bench/i && $event->{penalty} !~ /leaving/i) {
		$event->{servedby} = $event->{player1} if $event->{player1};
		$event->{player1}  = $BENCH_PLAYER_ID;
	}
	if ($event->{penalty} =~ /too many/i || $event->{description} =~ /late on ice/i || $event->{description} =~ /^\s+against/i) {
		$event->{servedby} ||= $event->{player1} if $event->{player1};
		$event->{player1}  = $BENCH_PLAYER_ID;
		$event->{pim_correction} += 2;
	}
	elsif ($event->{penalty} =~ /(.*\w)\W*\bcoach$/i) {
		$event->{servedby} = $event->{player1} if $event->{player1};
		$event->{player1}  = $COACH_PLAYER_ID;
		$event->{penalty} = $1;
	}
	$event->{penalty} = normalize_penalty($event->{penalty});
}

sub assign_specific_goal_data ($$) {

	my $event    = shift;
	my $ld_event = shift;

	place_players($event, $ld_event);
	$event->{assists} = [ map {
		$_->{playerType} eq 'Assist' ? $_->{player}{id} : (),
	} @{$ld_event->{players}} ];
	$event->{shot_type} = vocabulary_lookup('shot_type', $ld_event->{result}{secondaryType} || '');
	$event->{en}        = $ld_event->{result}{emptyNet};
	$event->{gwg}       = $ld_event->{result}{gameWinningGoal};
}

sub assign_specific_event_data ($$) {

	my $event    = shift;
	my $ld_event = shift;

	for ($event->{type}) {
		when ('FAC') {
			for my $player (@{$ld_event->{players}}) {
				$event->{$PLAYER_ID_MAP{$player->{playerType}}} = $player->{player}{id};
			}
			$event->{winning_team} = $ld_event->{team}{triCode},
		}
		when ('GIVE') { $event->{player1} = $ld_event->{players}[0]{player}{id}; }
		when ('TAKE') { $event->{player1} = $ld_event->{players}[0]{player}{id}; }
		when ('MISS') {
			$event->{player1} = $ld_event->{players}[0]{player}{id};
			$event->{description} =~ /\- (.*)/;
			$event->{miss}    = vocabulary_lookup('miss', $1 || '');
		}
		when ('STOP')  { $event->{stopreason} = [ vocabulary_lookup('stopreason', $event->{description})] }
		when ('HIT')   { place_players($event, $ld_event); }
		when ('BLOCK') {
			place_players($event, $ld_event);
			my $x = $event->{player2};
			$event->{player2} = $event->{player1};
			$event->{player1} = $x;
		}
		when ('SHOT') {
			place_players($event, $ld_event);
			$event->{shot_type} = vocabulary_lookup('shot_type', $ld_event->{result}{secondaryType} || '');
		}
		when ('PENL') { assign_specific_penalty_data($event, $ld_event); }
		when ('GOAL') {	assign_specific_goal_data($event, $ld_event);    }
	}
	delete $event->{void};
}

sub check_broken ($$) {

	my $event    = shift;
	my $ld_event = shift;

	if (
		$BROKEN_EVENTS{BS}->{$event->{game_id}} &&
			(my $evx = $BROKEN_EVENTS{BS}->{$event->{game_id}}->{$ld_event->{about}{eventIdx}})
	) {
		for my $key (keys %{$evx}) {
			$event->{$key} = $evx->{$key};
		}
	}
}

sub fix_servedby ($) {

	my $event = shift;

	if ($event->{type} eq 'PENL'
		&& $event->{description} =~ /served by/i
		&& ! $event->{servedby}) {
		$event->{_servedby} = 1;
		my @pl = (
			3,2,
			($event->{description} =~ /\b(illegal|official|proceed|dress|refusal|objects|misconduct|ineligible|conduct|bench|coach|delay|abus|leaving)/i && $event->{description} !~ /leaves.*bench/i)
			|| $event->{severity} =~ /BENCH/
			|| $event->{description} =~ /minor served by/i
			? 1 : ()
		);
		for my $p (@pl) {
			my $field = "player$p";
			if (defined $event->{$field}) {
				delete $event->{_servedby};
				$event->{servedby} = delete $event->{$field};
				if ($field eq 'player1') {
					$event->{$field} = $event->{description} =~ /coach/i ?
						$COACH_PLAYER_ID : $BENCH_PLAYER_ID;
				}
				return;
			}
		}
	}
}

sub fix_old_goalie ($$) {

	my $self = shift;
	my $event = shift;

	if ($event->{type} eq 'GOAL'
		&& ! $event->{en}
		&& ! $event->{player2}
	) {
		my $team = $self->{teams}[
			$event->{team1} eq $self->{teams}[0]{name} ? 1 : 0,
		];
		my @goalies = sort {
			get_seconds($a->{timeOnIce}) <=> get_seconds($b->{timeOnIce})
		} grep {
			$_->{position} eq 'G'
		} @{$team->{roster}};
		my $goalie = $goalies[0];
		$event->{player2} = $goalie->{_id};
		$event->{team2}   = $team->{name};
	}
}

sub set_events ($$) {

	my $self   = shift;
	my $events = shift;

	$self->{events} = [];

	for my $ld_event (@{$events}) {
		next if $BROKEN_EVENTS{BS}->{$self->{_id}}->{$ld_event->{about}{eventIdx}} &&
			$BROKEN_EVENTS{BS}->{$self->{_id}}->{$ld_event->{about}{eventIdx}} eq '-1';
		next if grep { $_ eq $ld_event->{result}{eventTypeId} } @JS_IGNORED_EVENT_TYPES;
		my $event = {
			season      => $self->{season},
			stage       => $self->{stage},
			game_id     => $self->{_id},
			period      => $ld_event->{about}{period},
			time        => $ld_event->{about}{periodTime},
			coordinates => $ld_event->{coordinates},
			type        => vocabulary_lookup('events', $ld_event->{result}{eventTypeId}),
			description => uc $ld_event->{result}{description},
			strength    => vocabulary_lookup('strength', $ld_event->{result}{strength}{code} || ''),
			event_idx   => $ld_event->{about}{eventIdx},
			bsjs_id     => $ld_event->{about}{eventId},
			event_code  => uc ($ld_event->{about}{eventCode} || ''),
			so          => $ld_event->{about}{periodType} eq 'SHOOTOUT' ? 1 : 0,
			$BROKEN_EVENTS{BS}->{$self->{_id}}->{$ld_event->{about}{eventIdx}} ?
				%{$BROKEN_EVENTS{BS}->{$self->{_id}}->{$ld_event->{about}{eventIdx}}} : (),
			$ld_event->{team} ? (
				team1       => resolve_team($ld_event->{team}{triCode} || $ld_event->{team}{name}),
				teamid      => $ld_event->{team}{id},
			) : (),
		};
		$event->{time} = substr($event->{time}, 1) if $event->{time} =~ /^0/;
		$event->{special} = 1
			if $SPECIAL_EVENTS{$self->{_id}} && $SPECIAL_EVENTS{$self->{_id}}->{$ld_event->{about}{eventIdx}};
		assign_specific_event_data($event, $ld_event);
		$self->fix_old_goalie($event);
		check_broken($event, $ld_event);
		fix_servedby($event);
		push(@{$self->{events}}, $event);
	}
}

sub build_resolve_cache ($) {

	my $self  = shift;

	$self->{resolve_cache} = {};
	for my $t (0,1) {
		my $unknown_number = 100;
		$self->{teams}[$t]{roster} = [ my_uniq { $_->{_id} } @{$self->{teams}[$t]{roster}} ];
		for my $player (@{$self->{teams}[$t]{roster}}) {
			if (! $player->{broken}) {
				$player->{penaltyMinutes} = delete $player->{pim} if defined $player->{pim};
				$player->{number} ||= $unknown_number++;
				while ($self->{resolve_cache}{$self->{teams}[$t]{name}}->{$player->{number}}) {
					$player->{number} += 100;
				}
				$self->{resolve_cache}{$self->{teams}[$t]{name}}->{$player->{number}} = \$player;
			}
			else {
				$self->{resolve_cache}{$self->{teams}[$t]{name}}->{names}
					||= [];
				push(@{$self->{resolve_cache}{$self->{teams}[$t]{name}}->{names}}, \$player);
			}
		}
	}
}

sub process ($) {

	my $self = shift;

	$self->set_id_data($self->{json}{gamePk});
	$self->set_timestamps($self->{json});
	$self->set_extra_header_data($self->{json});
	$self->set_periods($self->{json});
	$self->set_officials($self->{json}{liveData}{boxscore}{officials});
	$self->set_teams($self->{json});
	if (@{$self->{json}{liveData}{plays}{allPlays}}) {
		$self->set_events($self->{json}{liveData}{plays}{allPlays});
	}
	else {
		$BROKEN_FILES{$self->{_id}}->{BS} = $NO_EVENTS;
		$self->{events} = [];
	}
	$self->{type} = 'BS';
	delete $self->{json};
	1;
}

1;

=head1 AUTHOR

More Hockey Stats, C<< <contact at morehockeystats.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<contact at morehockeystats.com>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Sport::Analytics::NHL::Report::BS>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Sport::Analytics::NHL::Report::BS

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Sport::Analytics::NHL::Report::BS>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Sport::Analytics::NHL::Report::BS>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Sport::Analytics::NHL::Report::BS>

=item * Search CPAN

L<https://metacpan.org/release/Sport::Analytics::NHL::Report::BS>

=back
