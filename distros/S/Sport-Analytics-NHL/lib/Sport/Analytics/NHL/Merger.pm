package Sport::Analytics::NHL::Merger;

use v5.10.1;
use strict;
use warnings FATAL => 'all';
use experimental qw(smartmatch);

use Carp;
use Storable qw(dclone);

use List::MoreUtils qw(firstval uniq);

use Sport::Analytics::NHL::Config qw(:basic :ids);
use Sport::Analytics::NHL::Errors;
use Sport::Analytics::NHL::Tools qw(:db);
use Sport::Analytics::NHL::Util qw(:debug);

=head1 NAME

Sport::Analytics::NHL::Merger - Merge the extra (HTML) reports into the master one (JSON).

=head1 SYNOPSYS

Merge the extra (HTML) reports into the master one (JSON).

These are methods that match the data in the extra reports to the master one and merge it, or complement it, where necessary.

    use Sport::Analytics::NHL::Merger;
    merge_report($boxscore, $html_report);

=head1 GLOBAL VARIABLES

 The behaviour of the tests is controlled by several global variables:
 * $CURRENT - the type of the report currently being merged.
 * $BOXSCORE - the boxscore currently being merged.
 * $PLAYER_RESOLVE_CACHE - the player roster resolution cache as described in Sport::Analytics::NHL::Report::BS (q.v.)

=head1 FUNCTIONS

=over 2

=item C<check_player_names>

When trying to resolve a player in the HTML report to his NHL id, look up by player's name in the names section of the resolve cache.

 Arguments: * event description
            * resolve cache
            * player's number
 Returns: the reference to the player in the boxscore roster

=item C<copy_events>

Copy the events from a report when the original section of reports in the live boxscore is missing.

 Arguments: * the boxscore report
            * the extra report being merged
 Returns: void, sets $boxscore->{events}

=item C<expected_miss>

Checks if the event in the merged report was expected to be missed (i.e. not matched) within the boxscore

 Arguments: * the type of the merged report
            * the event in question
            * the master boxscore
 Returns: 0|1

=item C<find_event>

Finds the matching event from the extra report in the master boxscore.

 Arguments: * the event
            * the master boxscore event list
            * the type of the extra report
 Returns: the matched event or -1

=item C<find_player>

Finds the matching player from the extra report in the master boxscore.

 Arguments: * the player data
            * the roster in the matching boxscore to look in
            * [optional] list of players on ice to look in
 Returns: the matched player or undef

=item C<find_player_by_id>

Used by find_player to find the player by the NHL id.

 Arguments: * the player data
            * the roster in the matching boxscore to look in
 Returns: the matched player or undef

=item C<find_player_by_name>

Used by find_player to find the player by the name.

 Arguments: * the player data
            * the roster in the matching boxscore to look in
            * [optional] list of players on ice to look in
 Returns: the matched player or undef

=item C<merge_events>

Merges the matched events' data. Usually the data in the boxscore is considered correct, so only additional data is added.

 Arguments: * the boxscore report
            * the extra report being merged
 Returns: void, sets $boxscore->{events}

=item C<merge_me>

Actually performs the merging of the item. Usually the data in the boxscore is considered correct, so only additional data is added.

 Arguments: * the boxscore item
            * the extra report item
            * [optional] list of fields to be merged
 Returns: void, sets the event's fields.

=item C<merge_report>

The function to call to merge two reports.

 Arguments: * the boxscore report
            * the extra report being merged
 Returns: void, sets $boxscore and adds $boxscore->{sources}

=item C<merge_roster>

Merges two rosters of a team, from the master boxscore and from the extra report.

 Arguments: * the boxscore roster
            * the report roster
 Returns: void, sets the roster.

=item C<merge_shifts>

Merges the shift information of the game from the TV/TH reports.

 Arguments: the boxscore report
            the shifts report (TV or TH)

 Returns: void, sets the shifts.

=item C<merge_teams>

Merges the teams of the game, from the master boxscore and from the extra report.

 Arguments: * the boxscore report
            * the extra report being merged
 Returns: void, sets $boxscore

=item C<push_event>

Pushes the event that is found in the extra report but not in the master boxscore into the master boxscore's event list.

 Arguments: * the event
            * the master boxscore
            * the type of the extra report
 Returns: void, sets $boxscore->{events}

=item C<refine_candidates>

In case find_event (q.v.) is matched with more than one event, refines the candidate list to ultimately find the event.

 Arguments: * the event
            * the list of candidates
 Returns: the refined list of candidates

=item C<resolve_report>

Resolves the extra report players in the roster, in the events and on ice to their NHL ids.

 Arguments: * the boxscore report
            * the extra report being merged
 Returns: void. The extra report is modified.

=item C<resolve_report_event_fields>

Resolves event fields such as player1, player2, assist1, assist2 and servedby to the NHL ids.

 Arguments: * the event
            * the master boxscore
 Returns: void. The event is modified.

=item C<resolve_report_event_teams>

Resolves the extra report event teams to their NHL ids.

 Arguments: * the event
            * the master boxscore
 Returns: void. The event is modified.

=item C<resolve_report_on_ice>

Resolves the players on the ice during the event to their NHL ids.

 Arguments: * the event
            * the master boxscore
 Returns: void. The event is modified.

=item C<resolve_report_roster>

Resolves the players on the rosters of the extra report to their NHL ids.

 Arguments: * the roster
            * the master boxscore
            * the roster index (0 - away, 1 - home)
 Returns: void. The roster is modified.

=back

=cut

use parent 'Exporter';

our @EXPORT = qw(merge_report);

use Data::Dumper;
$Data::Dumper::Trailingcomma = 1;
$Data::Dumper::Deepcopy      = 1;
$Data::Dumper::Sortkeys      = 1;
$Data::Dumper::Deparse       = 1;

our $CURRENT = '';
our $BOXSCORE = {};
our @MERGE_HEADER = qw(tz month date location attendance);

our $PLAYER_RESOLVE_CACHE = {};

sub find_player_by_id ($$) {

	my $player = shift;
	my $team   = shift;

	my $bs_player;
	$bs_player = firstval { $_->{_id} == $player->{_id} } @{$team->{roster}};
	if (!$bs_player) {
		$PLAYER_RESOLVE_CACHE->{$team->{name}}{$player->{number}} = \$player;
		push(@{$team->{roster}}, $player);
		return $player;
	}
	elsif (!$bs_player->{number} || $bs_player->{number} != $player->{number}) {
		$bs_player->{number} = $player->{number};
		$PLAYER_RESOLVE_CACHE->{$team->{name}}{$player->{number}} = \$bs_player;
	}
	if ($bs_player->{broken}) {
		for my $field (keys %{$player}) {
			$bs_player->{$field} = $player->{$field};
			delete $bs_player->{broken};
		}
	}
	$bs_player;
}

sub find_player_by_name ($$$) {

	my $player = shift;
	my $team   = shift;
	my $on_ice = shift;

	$player->{name} = uc $player->{name};
	my ($name, $fname) = ($player->{name}, '');
	if ($player->{name} =~ /\.\s*(\S+.*)$/ && $name !~ /^st\./i) {
		$name = $1;
		$fname = substr($player->{name}, 0, 1);
		$fname =~ s/\)//g;
	}
	my @found_players = grep {
		$_->{name} =~ /^$fname.*$name$/i
		|| $NAME_VARIATIONS{$_->{name}}
			&& $NAME_VARIATIONS{$_->{name}} eq $player->{name}
		} @{$team->{roster}};
	return undef unless @found_players;
	@found_players = grep {
		! $_->{broken}
	} @found_players if (@found_players > 1);
	if (@found_players > 1) {
		@found_players = $CURRENT eq 'GS'
			? ($found_players[0])
			: grep { $_->{position} eq $player->{position} } @found_players;
	}
	return $found_players[0] if (@found_players == 1);
	if (@found_players > 1) {
		for my $o_i (@{$on_ice}) {
			my $found = firstval {
				$_->{number} == $o_i || $_->{_id} == $o_i
			} @found_players;
			return $found if $found;
		}
	}
	undef;
}

sub find_player ($$;$) {

	my $player = shift;
	my $team   = shift;
	my $on_ice = shift || [];

	if (! ref $player) {
		$player = $player =~ /^\d/ ?
			{ number => $player } : { name => $player };
	}
	my $bs_player;
	if ($player->{_id} && $player->{_id} =~ /^8\d{6}/) {
		$bs_player = find_player_by_id($player, $team)
			if ($player->{_id} && $player->{_id} =~ /^8\d{6}/);
	}
	elsif ($player->{number}) {
		$bs_player = ${
			$PLAYER_RESOLVE_CACHE->{$team->{name}}{$player->{number}}
		} if $PLAYER_RESOLVE_CACHE->{$team->{name}}{$player->{number}};
		return undef unless $bs_player || $player->{name};
	}
	$bs_player ||= find_player_by_name($player, $team, $on_ice);
	return undef unless $bs_player;
	$player->{number} = $bs_player->{number} if defined $bs_player->{number} && ! $bs_player->{broken};
	$player->{_id}    = $bs_player->{_id};
	$player;
}

sub refine_candidates ($@) {

	my $event      = shift;
	my @candidates = @_;

	grep {
		if ($event->{type}    eq 'PENL') {
			($event->{length} == $_->{length} || $event->{length} == 10 && $_->{length} == 2)
			&& $event->{penalty} eq $_->{penalty}
			&& (($event->{player1} || 0) == ($_->{player1} || 0)
				|| $event->{player1} == ($_->{servedby} || 0)
				|| ($event->{servedby} || 0) == $_->{player1})
		}
		elsif ($event->{type} eq 'STOP') {
			my $s = 0;
			for my $stopreason (@{$_->{stopreason}}) {
				if (
					$event->{stopreason} =~ /$stopreason/i
						|| $event->{stopreason} =~ /CHLG/i && $stopreason =~ /challenge/i
				) {
					$s = 1;
					last;
				}
			}
			$s;
		}
		else {
			($event->{player1} || 0) == ($_->{player1} || 0)
			|| ($event->{player2} || 0) == ($_->{player1} || 0)
				&& ($event->{player1} || 0) == ($_->{player2} || 0)
		}
	} @candidates;
}

sub find_event ($$$) {

	my $event     = shift;
	my $bs_events = shift;
	my $type      = shift;

	return -1 if $event->{special};
	return -1 if ! $event->{player1} && $type ne 'PL';
	my @candidates = grep {
		$_->{t} == $event->{t}
		&& $_->{period} == $event->{period}
		&& $_->{type}   eq $event->{type}
		&&  ($BROKEN_TIMES{$_->{game_id}}
			&& ($event->{player1} || 0) == ($_->{player1} || 0)
			||  ($event->{ts}           ==  $_->{ts}))
	} @{$bs_events};
	if (! @candidates && ($event->{type} eq 'MISS' || $event->{type} eq 'SHOT') && $event->{so}) {
		@candidates = grep {
			$_->{t} == $event->{t}
			&& $_->{player1} == $event->{player1}
		} @{$bs_events};
	}
	return $candidates[0] if @candidates == 1;
	return -1 unless @candidates;
	@candidates = refine_candidates($event, @candidates);
	return $candidates[0] if @candidates;
	return -1 unless @candidates;
}

sub resolve_report_on_ice ($$) {

	my $event = shift;
	my $bs    = shift;

	return if $event->{sources}{GS} && $event->{period} == 5 && $event->{stage} == $REGULAR;
	my $en = 1;
	my $ne = 1;
	for my $t (0,1) {
		for my $on_ice (@{$event->{on_ice}[$t]}) {
			next unless $on_ice =~ /^\d{1,2}$/;
#			dumper $on_ice, $event;
			my $new_on_ice =
				$PLAYER_RESOLVE_CACHE->{$bs->{teams}[$t]{name}}{$on_ice} ||
				check_player_names(
					$event->{description},
					$PLAYER_RESOLVE_CACHE->{$bs->{teams}[$t]{name}},
					$on_ice,
				);
			if (! ref $new_on_ice) {
				if ($CURRENT eq 'GS') {
					$on_ice += 8400000;
					next;
				}
				else {
					$on_ice = $UNKNOWN_PLAYER_ID;
				}
			}
			else {
				$on_ice = ${$new_on_ice}->{_id};
				#				dumper $new_on_ice;
				unless ($event->{penaltyshot}) {
					$en = 0 if $t == 1-$event->{t} && ${$new_on_ice}->{position} eq 'G';
					$ne = 0 if $t ==  $event->{t}  && ${$new_on_ice}->{position} eq 'G';
				}
			}
		}
	}
	$event->{en} = 1 if $en;
	$event->{ne} = 1 if $ne;
}

sub resolve_report_roster ($$$) {

	my $roster = shift;
	my $bs     = shift;
	my $t      = shift;

	for my $player (@{$roster}) {
		next if $player->{error};
		if (($player->{timeOnIce} || defined $player->{start} && $player->{start} != 2) && !($player->{_id} && $player->{_id} eq $EMPTY_NET_ID)) {
			my $bs_player = find_player($player, $bs->{teams}[$t]);
			if (! $bs_player && $CURRENT eq 'GS') {
				$player->{error} = 1;
				next;
			}
			die ("Can't resolve player ($CURRENT): " . Dumper $player)
				unless $bs_player || ($player->{position} eq 'G' && $player->{start} != 1 || ! $player->{timeOnIce});
		}
	}
}

sub resolve_report_event_teams ($$) {

	my $event  = shift;
	my $report = shift;

	if ($event->{team1}) {
		if ($event->{team1} eq 'OTH') {
			$event->{team1} =
				$report->{teams}[$event->{team2} eq $report->{teams}[0]{name} ? 1 : 0]{name};
		}
		$event->{team1} = resolve_team($event->{team1});
	}
	if ($event->{team2}) {
		if ($event->{team2} eq 'OTH') {
			$event->{team2} =
				$report->{teams}[$event->{team1} eq $report->{teams}[0]{name} ? 1 : 0]{name};
		}
		$event->{team2} = resolve_team($event->{team2});
	}
}

sub check_player_names ($$$) {

	my $description = shift || '';
	my $cache       = shift;
	my $number      = shift;

	for my $player_ref (@{$cache->{names}}) {
		my $player = ${$player_ref};
		my ($last_name) = ($player->{name} =~ /\b(\S+)$/);
		$last_name = $REVERSE_NAME_TYPOS{$last_name} if $REVERSE_NAME_TYPOS{$last_name};
#		print "DESC $description LN $last_name NM $number\n";
#		if ($number == 4) {
#			dumper $cache;
#			exit;
#		}
		if ($description =~ /\b$last_name\b/i) {
			debug "Matched $description with $last_name";
			$cache->{$number} = $player_ref;
			return $player_ref;
		}
	}
}

sub resolve_report_event_fields ($$) {

	my $event = shift;
	my $bs    = shift;

	for my $field (qw(player1 player2 assist1 assist2 servedby)) {
		next if ! $event->{$field} || $event->{$field} =~ /^8\d{6}/;
		my $team  = $field eq 'player2' ? 'team2' : 'team1';
		my $team2 = $field eq 'player2' ? 'team1' : 'team2';
		if ($event->{$field} && $event->{$field} =~ /\D/) {
			my $player = find_player($event->{$field}, $bs->{teams}[$event->{t}], $event->{on_ice}[$event->{t}]);
			if ($player) {
				$event->{$field} = $player->{_id};
			}
			elsif (!($CURRENT eq 'GS' && $event->{type} eq 'GOAL')) {
				die "Can't resolve player for event: " . Dumper $player, $event, $field;
			}
			if ($event->{player1} && $event->{servedby} && $event->{player1} == $event->{servedby}) {
				delete $event->{servedby};
			}
		}
		else {
#			dumper $team, $field, $event->{$field}, $event->{$team},
			#				$PLAYER_RESOLVE_CACHE->{$event->{$team}};
			my $matched_player =
				$PLAYER_RESOLVE_CACHE->{$event->{$team}}{$event->{$field}}
				|| check_player_names(
					$event->{description},
					$PLAYER_RESOLVE_CACHE->{$event->{$team}},
					$event->{$field},
				) || $PLAYER_RESOLVE_CACHE->{$event->{$team2}}{$event->{$field}};
			my $ef = $event->{$field};
#			dumper $matched_player;
			$event->{$field} = ${$matched_player}->{_id};
			if ($event->{type} eq 'BLOCK' && ! $event->{player2}) {
				dumper $event, $event->{$team}, $field, $team, $matched_player, $ef;
				dumper $PLAYER_RESOLVE_CACHE->{$event->{$team}};
				die;
			}
		}
	}
}

sub resolve_report ($$) {

	my $bs    = shift;
	my $rp    = shift;

	for my $t (0,1) {
		$rp->{teams}[$t]{name} = resolve_team($rp->{teams}[$t]{name});
		resolve_report_roster($rp->{teams}[$t]{roster}, $bs, $t);
	}
	if ($rp->{events}) {
		$rp->set_event_extra_data();
		for my $event (@{$rp->{events}}) {
			resolve_report_event_teams($event, $rp);
			resolve_report_event_fields($event, $bs);
			resolve_report_on_ice($event, $bs) if ($event->{on_ice});
		}
	}
}

sub merge_me ($$;$$) {

	my $bs_event = shift;
	my $rp_event = shift;

	my $fields   = shift || [ grep {
		$_    ne 'name'
		&& $_ ne 'decision'
		&& defined $rp_event->{$_}
		&& (! defined $bs_event->{$_} || $bs_event->{$_} eq 'XX' || $bs_event->{$_} eq 'N/A' || $bs_event->{$_} =~ /^unk$/i)
		&& $rp_event->{$_} ne 'XX' && $rp_event->{$_} !~ /^Unk/i
	} keys %{$rp_event}];
	push(@{$fields}, 'stopreasons') if $rp_event->{stopreasons};
#	dumper $rp_event->{number} if defined $rp_event->{number};
#	dumper $fields if $rp_event->{number} && $rp_event->{number} == 35;
	for (@{$fields}) {
		when ('stopreasons') {
			$bs_event->{$_} = [
				uniq (@{$bs_event->{stopreasons}}, @{$rp_event->{stopreasons}})
			];
		}
		when ('servedby') {
			$bs_event->{$_} ||= $rp_event->{$_};
		}
		when ('position') {
#			dumper $bs_event->{$_}, $rp_event->{$_}, $bs_event->{name}, $rp_event->{name}, [caller];
			$bs_event->{toi_converted} = 1;
			if ((!$bs_event->{$_} || $bs_event->{$_} eq 'N/A')) {
				$bs_event->{_from_na} = 1;
				$bs_event->{$_} = $rp_event->{$_};
				$bs_event->{number} = $rp_event->{number}
					if defined $rp_event->{number};
				$bs_event->{name} = $rp_event->{name}
					if defined $rp_event->{number};
			}
#			dumper $bs_event;
		}
		when ('on_ice') {
			$bs_event->{$_} = $rp_event->{$_}
				if (! $bs_event->{on_ice} || !$bs_event->{on_ice}[0] || ! @{$bs_event->{on_ice}[0]})
		}
		when ('strength') {
			$bs_event->{$_} = $rp_event->{$_}
				if ($bs_event->{$_} !~ /\S/ || $bs_event->{$_} eq 'XX');
		}
		
		default {
			$bs_event->{$_} = $rp_event->{$_};
		}
	}
#	dumper $bs_event if $rp_event->{number} && $rp_event->{number} == 54;
	if (defined $bs_event->{position}) {
		for my $field (keys %{$rp_event}) {
			if (! defined $bs_event->{$field}
				&& defined $rp_event->{$field}
				&& ($rp_event->{$field} eq '' || $rp_event->{$field} eq 0)) {
				$bs_event->{$field} = 0;
			}
		}
	}
#	if ($bs_event->{number} && $bs_event->{number} == 35) {
#		dumper $bs_event;
#		exit;
#	}
	
}

sub merge_roster ($$;$) {

	my $bs_team = shift;
	my $rp_team = shift;

	for my $rp_player (@{$rp_team->{roster}}) {
		next if $rp_player->{error};
		next unless $rp_player->{timeOnIce} || defined $rp_player->{start};
		next if $rp_player->{_id} && $rp_player->{_id} == $EMPTY_NET_ID;
		if ($rp_player->{number}) {
			if (
				! $PLAYER_RESOLVE_CACHE->{$bs_team->{name}}{$rp_player->{number}}
			) {
				my $found = 0;
				for my $bs_player (@{$bs_team->{roster}}) {
#					print "$bs_player->{number} == $rp_player->{number} $rp_player->{name}\n";
					next unless $bs_player->{number};
					if ($bs_player->{number} == $rp_player->{number}) {
						delete $bs_player->{broken};
						$PLAYER_RESOLVE_CACHE->{$bs_team->{name}}{$rp_player->{number}} = \$bs_player;
						$bs_team->{scratches} = [ grep {
							$_ != $bs_player->{_id};
						} @{$bs_team->{scratches}} ];
						$found = 1;
						last;
					}
				}
				my $bs_player = check_player_names(
					$rp_player->{name},
					$PLAYER_RESOLVE_CACHE->{$bs_team->{name}},
					$rp_player->{number}
				) unless $found;
				
#				dumper $PLAYER_RESOLVE_CACHE->{$bs_team->{name}};
#				$PLAYER_RESOLVE_CACHE->{$bs_team->{name}}{$rp_player->{number}} = \$bs_team->{roster}[-1];
			}
			#			dumper $rp_player->{number}, $rp_player->{name}, $rp_player->{position};
#			${$PLAYER_RESOLVE_CACHE->{$bs_team->{name}}{$rp_player->{number}}} ||= {};
			merge_me(
				${$PLAYER_RESOLVE_CACHE->{$bs_team->{name}}{$rp_player->{number}}},
				$rp_player, 0
			);
			
#			if ($rp_player->{number} == 35) {
#				dumper $rp_player;
				#				dumper $PLAYER_RESOLVE_CACHE->{$bs_team->{name}};
#				dumper $bs_team->{roster};
#				exit;
#			}
		}
	}
#	$bs_team->{roster} = [ grep { $_->{position} ne 'N/A' } @{$bs_team->{roster}}];
#	exit;
}


sub merge_teams ($$) {

	my $boxscore = shift;
	my $report   = shift;

	for my $t (0,1) {
		my $bs_team = $boxscore->{teams}[$t];
		my $rp_team = $report->{teams}[$t];
		unless ($bs_team->{name} eq $rp_team->{name}) {
			die "$bs_team->{name} vs $rp_team->{name} how did I get here?";
		}
		$bs_team->{coach} ||= $rp_team->{coach};
		merge_roster($bs_team, $rp_team, $report->{type} eq 'BH');
	}
}

sub copy_events ($$) {

	my $boxscore = shift;
	my $report   = shift;

	$boxscore->{events} = dclone $report->{events};
	for my $event (@{$boxscore->{events}}) {
		$event->{sources}{$report->{type}} = 1;
		$event->{sources}{BS} = 0;
		if ($event->{assist1}) {
			$event->{assists} = [
				$event->{assist1} || (),
				$event->{assist2} || (),
			]
		}
	}
}

sub expected_miss ($$$) {

	my $type    = shift;
	my $event   = shift;
	my $boxscore = shift;
	my $game_id = $boxscore->{_id};

	$boxscore->{no_events}
	|| (
		$type eq 'PL' && $event->{season} < 2010
			&& $event->{type} ne 'PENL'	&& $event->{type} ne 'GOAL'
	)
	|| (
		ref($FORCED_PUSH{$type}{$game_id})
		&& $FORCED_PUSH{$type}{$game_id}->{$event->{id}}
	)
	|| $event->{type} eq 'PENL' && $event->{length} == 0
	|| $event->{type} eq 'PEND'
	|| $event->{type} eq 'GEND'
	|| $event->{type} eq 'STOP' && $event->{description} =~ /CHL/i
	|| $event->{type} eq 'MISS' && ($type eq 'GS')
}

sub push_event ($$$) {

	my $event    = shift;
	my $boxscore = shift;
	my $type     = shift;

	$event->{game_id} = $boxscore->{_id};
	$event->{sources}{$type} = 1;
	$event->{description} ||= 'Missed Penalty Shot' if $event->{type} eq 'MISS';
	push(@{$boxscore->{events}}, $event);

}

sub merge_events ($$) {

	my $boxscore = shift;
	my $report   = shift;

	my $type = $report->{type};
	while (my $rp_event = shift @{$report->{events}}) {
		next if $type eq 'GS' && $boxscore->{sources}{PL} && $boxscore->{season} >= 2007;
		my $e = find_event($rp_event, $boxscore->{events}, $type);
		if (! ref $e) {
			if (expected_miss($type, $rp_event, $boxscore)) {
				push_event($rp_event, $boxscore, $type);
				next;
			}
		}
		elsif ($type eq 'GS' && $rp_event->{type} eq 'MISS') {
			$rp_event->{type} = 'SHOT';
			$e = find_event($rp_event, $boxscore->{events}, $type);
			if (! ref $e) {
				push_event($rp_event, $boxscore, $type);
				next;
			}
		}
		die "UNDEF e  " . Dumper($rp_event) unless defined $e;
		next if $e == -1;
		$e->{sources}{$type} = 1;
		merge_me($e, $rp_event);
	}
}

sub merge_shifts ($$) {

	my $boxscore = shift;
	my $report   = shift;

	for my $shift (@{$report->{shifts}}) {
		if ($BROKEN_SHIFTS{$boxscore->{_id}}->{$shift->{team}}{$shift->{player}}) {
			$shift->{invalid} = 1;
			next;
		}
		$shift->{number} = $shift->{player};
		my $t = $boxscore->{teams}[0]{name} eq $shift->{team} ? 0 : 1;
		my $player = find_player($shift, $boxscore->{teams}[$t]);
		if (! $player) {
			$player = find_player($shift, $boxscore->{teams}[1-$t]);
			if (! $player) {
				die "Unresolved shift: " . Dumper $shift;
			}
			else {
				$shift->{team} = $boxscore->{teams}[1-$t]{name};
			}
		}
		$shift->{game_id}  = $boxscore->{_id};
		$shift->{season}   = $boxscore->{season};
		$shift->{stage}    = $boxscore->{stage};
		$shift->{player}   = delete $shift->{_id};
		$shift->{position} = $player->{position};
	}
	$boxscore->{shifts} ||= [];
	push(@{$boxscore->{shifts}}, grep { ! $_->{invalid} } @{$report->{shifts}});
}

sub merge_report ($$) {

	my $boxscore = shift;
	my $report   = shift;

	my $type = $report->{type};

	$CURRENT = $type;
	$BOXSCORE = $boxscore;
	$PLAYER_RESOLVE_CACHE = $boxscore->{resolve_cache};
	debug "Merging $type";
	resolve_report($boxscore, $report);

	for ($type) {
		when ([qw(RO ES GS PL)]) {
			merge_me($boxscore, $report, \@MERGE_HEADER);
			continue;
		}
		when ([qw(RO ES GS)]) {
			merge_teams($boxscore, $report);
			continue;
		}
		when ([qw(GS PL)])    {
			@{$boxscore->{events}} ?
				merge_events($boxscore, $report) : 	copy_events($boxscore, $report);
			continue;
		}
		when (/^T/) {
			merge_shifts($boxscore, $report);
			continue;
		}
	}
	$boxscore->{sources}{$type} = 1;
}

1;

=head1 AUTHOR

More Hockey Stats, C<< <contact at morehockeystats.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<contact at morehockeystats.com>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Sport::Analytics::NHL::Merger>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Sport::Analytics::NHL::Merger

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Sport::Analytics::NHL::Merger>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Sport::Analytics::NHL::Merger>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Sport::Analytics::NHL::Merger>

=item * Search CPAN

L<https://metacpan.org/release/Sport::Analytics::NHL::Merger>

=back
