package Sport::Analytics::NHL::PenaltyAnalyzer;

use v5.10.1;
use strict;
use warnings FATAL => 'all';
use experimental qw(smartmatch);

use Storable qw(dclone);
use List::MoreUtils qw(firstidx uniq);

use Sport::Analytics::NHL::Config qw(:ids :basic $FIRST_DETAILED_PENL_SEASON);
use Sport::Analytics::NHL::DB;
use Sport::Analytics::NHL::Errors;
use Sport::Analytics::NHL::Vars   qw($CACHES $DB);
use Sport::Analytics::NHL::Util   qw(:debug :utils :shortcuts);
use Sport::Analytics::NHL::Tools  qw(:db);

use parent 'Exporter';

our @EXPORT = qw(analyze_game_penalties set_strengths);

sub stack_penalties ($$;$);

our $ON_ICE = [6,6];
our $CACHE  = {};
our $_SEASON;
our $extra_base = 0;
our $_base      = 6;

our %FORCE_ICE = (
	1999211260040 => 55,
);

our %STRANGE_52 = (
	200220024 => 1,
	200220701 => 1,
);
our %IGNORE_PENALTIES = (
	2018203970210 => 1,
	2006201500050 => 1,
);
our %FORCE_SUBSTITUTE = (
	2010207850197 => 1,
	2010207850195 => 1,
	2002202620103 => 1,
	2002202620101 => 1,
	2002208060119 => 1,
	2002208060118 => 1,
#	2000202500004
);
our %UNKNOWN_SERVEDBY = (
	2001209150003 => 1,
	2001209150006 => 1,
);
our %FORCE_STACK = (
	2001210920026 => 1,
	2006203860123 => 1,
);
our %CAPTAIN_DECISIONS = (
	2003205460157 => 1,
	2003205460158 => 1,
	2003205760179 => 1,
	2003207440092 => 1,
	2003207440091 => 1,
	2003303120144 => 1,
	2005207800180 => 1,
	2005207800181 => 1,
	2008201820340 => 1,
	2008201820343 => 1,
	2008204140132 => 1,
	2009201510085 => 1,
	2009201510086 => 1,
	2009201510099 => 1,
	2009202730099 => 1,
	2009202730100 => 1,
	2009302340259 => 1,
	2009302340260 => 1,
	2010202360302 => 1,
	2010202360305 => 1,
	2010204070235 => 1,
	2010204070236 => 1,
	2010206510178 => 1,
	2010206510180 => 1,
	2011205980031 => 1,
	2011212290200 => 1,
	2011212290201 => 1,
	2013210980067 => 1,
	2013210980068 => 1,
	2013211610294 => 1,
	2013211610293 => 1,
	2015301410259 => 1,
	2015303140183 => 1,
	2015303140184 => 1,
	2017206400246 => 1,
	20172064002460 => 1,
	2018204040044 => 1,
);

=head1 NAME

Sport::Analytics::NHL::PenaltyAnalyzer - analyze the penalties, generate their actual start and finish time and allow determination of on-ice strength and of PB population at any time.

=head1 SYNOPSIS

Analyze the game penalties and derive as much as possible useful information from them. This is a very complicated module that implements the NHL penalty rulebook as well as its changes over the years.
It builds the timelines of all penalties during the game which indicates the on-ice strength and penalty box population at any point of time in the game.
Often, the analysis contradict the NHL's own records, and that's because NHL's own records are erroneous. When the analysis can be tested by the actual on-ice player record,
we do the verification, but prior to that, i.e. before 1999, we consider our implementation to be correct even when they contradict the record strength of a goal.

The generated strengths are then inserted into their own collection which is constructed like a timeline for each game.

 use Sport::Analytics::NHL::PenaltyAnalyzer
 my $opts = ...
 my $game_id = 201820001;
 analyze_game_penalties($game_id, $opts->{dry_run});
 set_strengths($game_id, $opts->{dry_run});

Two main functions listed in the snippet are exported. All the rest are auxiliary and the author has a limited
understand of why and how they work. But they do.

The teams are managed as indices: away is 0, home is 1.

=head1 FUNCTIONS

=over 2

=item C<decrease_onice>

The global variable two-member arrayref ON_ICE counts the number of players on ice for each team. This function decreases the on-ice count for the given team.
The count cannot go below 4. The penalty shot situations are not analyzed here.

 Arguments: index of the team (0|1)

 Returns: void

=item C<increase_onice>

This function increases the on-ice count for the given team. The count cannot go above 6.

 Arguments: index of the team (0|1)

 Returns: void

=item C<create_player_cache>

Creates a cache of game player ids mapped to their positions. The cache is stored in $CACHE (see Sport::Analytics::NHL::Vars) global variable.

 Arguments: the game

 Returns: void.

=item C<dump_penalty>

Debugging function that neatly formats a penalty by its attributes

 Arguments: the penalty

 Returns: void, prints output.

=item C<dump_pbox>

Debugging function that produces the output of all penalties of both teams

 Arguments: the current penalty box (a 2-vector arrayref)

 Returns: void, prints output.

=item C<is_major_penalty>

Checks if the penalty is a major one by the name, despite not carrying a 5-minute length.

 Arguments: the penalty
            the vocabulary of the penalty names
            (see Sport::Analytics::NHL::Config)

 Returns: 1 if it is, 0 if it isn't.

=item C<check_gross_misconduct>

Checks if a gross misconduct has occurred and assigns an extra 5-minute major to it.

 Arguments: the penalty
            the gross misconduct vocabulary entry
            the penalties array of the game

 Returns: void

=item C<stack_penalties>

Stacks two penalties that overlap but in fact must occur one after another - in a double minor or in a excessive penalty box population cases.

 Arguments: the penalty to be stacked
            the penalty it should be stacked with
            the flag to ignore the already existing stacking link

 Returns: void

=item C<split_double_minor>

Splits the double minor into two stacked minor penalties

 Arguments: the double penalty
            the penalties array of the game
            the index of the penalty in the array

 Returns: void

=item C<check_multiple_penalties_by_player>

Checks if the penalized player is already serving a penalty in the box

 Arguments: the current penalty
            the penalty box

 Returns: the matched penalties if any.

=item C<prepare_penalties>

Prepares a group of penalties by applying the functions described above to be processed later. Penalties that don't go on the clock are marked as such as well.

 Arguments: the penalties vocabulary (q.v.)
            the penalties to be prepared
            the penalty box

 Returns: void

=item C<expire_penalty>

Expires a penalty that ran out its clock.

 Arguments: the penalty
            the penalized team's index
            the timestamp of the moment
            the penalty box

 Returns: void

=item C<expire_penalties>

Loops through the penalty box to find the penalties to be expired at a given time.

 Arguments: the time point
            the penalty box

 Returns: void

=item C<get_coincidental_penalties>

Finds penalties awarded coincidentally at the same time point and groups them by length: 0, 2, 5, 10

 Arguments: the current penalty
            all penalties in the group

 Returns: the hash of the coincidental penalties.

=item C<assign_0_10>

Assigns 0-minute and 10-minute penalties to the penalty box

 Arguments: the penalty box
            the hash of the coincidental penalties

 Returns: void

=item C<apply_captain_decision>

Applies a deducted captain's decision on which penalties shall expire sooner.

 Arguments: the coincidentals hashref

 Returns: 1 if there was a captain's decision
          0 if the order is FIFO.

=item C<has_coincidental_bench>

Checks if coincidental penalties include a bench penalty

 Arguments: the coincidentals hashref

 Returns: 1 if there was a bench penalty
          0 otherwise

=item C<get_c52_count>

Gets the count of coincidental matching 5 vs 2 penalties

 Arguments: the coincidentals hashref
            the penalty box
            the length of the penalty (2 or 5)

 Returns: the count of the coincidentals 5 vs 2.

=item C<adjudicate_substitute>

Adjudicates whether the penalty is substituted

 Arguments: the length of the penalty
            the coincidentals hashref
            the count of 5 vs 2 (see above)
            the reference to a flag where 2-minute coincidentals
             force a substitution

 Returns: 1 if a subsistution was required
          0 otherwise

=item C<assign_coincidentals>

Properly assigns coincidental penalties, adjusts their begin and end marks and sets them as matching penalties where applicable.

 Arguments: the penalty box
            the coincidentals hashref
            the length of coincidentals to work with (5 or 2)
            the reference to a flag where 2-minute coincidentals
             force a substitution

 Returns: void

=item C<assign_different_coincidentals>

Assigns a special case of 5 vs 2 coincidentals in the last minutes or in the OT.

 Arguments: the penalty box
            the coincidentals hash

 Returns: void

=item C<has_same_player1_or_servedby>

Checks if two penalties has the same offending player or the same servedby

 Arguments: penalty1
            penalty2

 Returns: 1 or 0

=item C<find_same_player_penalty>

Finds penalties by the same player that was assigned another penalty

 Arguments: the penalty box
            that another penalty

 Returns: 1 or 0

=item C<find_stack_penalty>

Find the penalty that was stacked to the given penalty for the given team.

 Arguments: the penalty box
            the given penalty
            the team index

 Returns: the stacked penalty or undef.

=item C<assign_remaining>

After assigning the coincidental penalties, assign the remaining penalties to the penalty box.

 Arguments: the penalty box
            the remaining penalties
            the length of these penalties

 Returns: void

=item C<process_penalties>

Processes a list of penalties assigning them to the penalty box and marking their derived properties.

 Arguments: the arrayref of penalties
            the penalty box

 Returns: void

=item C<get_active_penalties>

Gets penalties that are currently on the clock at the time of an event.

 Arguments: the penalty box
            the event

 Returns: the penalties on the clock.

=item C<set_indicator>

Sets the on-ice event strength indicator (type from 44 to 66, away team first, strength such as PP2 or SH1 or EV5) based on the penalty tracker.

 Arguments: the indicator hashref
            the event
            the penalty box
            the active penalties

 Returns: void. Dies if invalid indicator is detected.

=item C<mark_scores>

Marks the penalties if a goal was scored on them.

 Arguments: the goal
            the penalties on the clock, sorted

 Returns: void

=item C<terminate_penalty>

Terminates a penalty that was scored upon and thus ended.

 Arguments: the goal
            the penalties on the clock

 Returns: void, penalties are modified.

=item C<restore_on_ice_player>

Restores a player who is out of the box to the ice when the on-ice tracker of the NHL fails to do that.

 Arguments: the goal
            the penalty box

 Returns: void, the event is updated.

=item C<get_real_on_ice>

Gets the on ice count as provided by the NHL, or as explicitly marked in our constants at the top of this file.

 Arguments: the event

 Returns: the "real" ice count

 Caveats: bad function name; debugging/testing only.

=item C<process_goal>

Processes the penalties when a goal has been scored.

 Arguments: the goal
            the penalty box

 Returns: void

=item C<clone_match_penalty>

Clone a match penalty based on description when it should've accompanied a major.

 Arguments: the major penalty
            the end timestamp of the game

 Returns: void

=item C<update_penalty>

Updates a penalty in the database with all the information gathered.

 Arguments: the penalty
            the vocabulary entry for misconduct
            the end timestamp of the game

 Returns: void

=item C<update_penalties>

Loops through the game penalties to update them

 Arguments: the penalty box
            the vocabulary of penalties
            the end timestamp of the game

 Returns: void

=item C<analyze_game_penalties>

The main exporting function to prepare, process and update the penalties.

 Arguments: the game
 [optional] the dry run flag

 Returns: void

=item C<init_strengths>

Initializes the 'str' collection of strengths in the database.

 Arguments: none

 Returns: the collection 'str'

=item C<get_strength_affecting_penalties>

Gets the list of on-ice strength affecting penalties from a game

 Arguments: the game

 Returns: the list of penalties

=item C<set_timeline>

Sets the timeline array of penalties, with 1 marking the penalty start and 0 marking the finish

 Arguments: the game
            the game penalties

 Returns: the timeline

=item C<update_on_ice_for_ot>

Updates the special case of on-ice count during the regular season overtime based on the OT rules of that season.

 Arguments: the on-ice count
            the game

 Returns: void

=item C<update_stack_on_ice_match>

Updates either the on-ice count, or the penalty box stack count or the matched penalties count.

 Arguments: the penalty entry from the timeline
            the on-ice count
            the stack count
            the matching penalty count reference

 Returns: void

=item C<push_strengths>

Pushes a new entry to the strengths arrayref to be inserted later into the database.

 Arguments: the strengths arrayref
            the current timestamp
            the next penalty timestamp
            the game
            the on_ice count

 Returns: void

=item C<set_strengths>

The main exporting function to prepare, process and insert the strengths.

 Arguments: the game
 [optional] the dry run flag

 Returns: void

=back

=cut

sub decrease_onice ($) {

	my $t = shift;
	$ON_ICE->[$t]-- unless $ON_ICE->[$t] == 4;
}

sub increase_onice ($) {

	my $t = shift;
	$ON_ICE->[$t]++ unless $ON_ICE->[$t] == 6;
}

sub create_player_cache ($) {

	my $game = shift;

	for my $t (0,1) {
		for my $player (@{$game->{teams}[$t]{roster}}) {
			$CACHE->{$player->{_id}} = $player->{position};
		}
	}
}

sub dump_penalty ($) {

	local $_ = shift;
	printf "%d %d %d %d %4s %4s %-2s %4s (%s,%s) %s %s %s\n",
		$_->{_id}, $_->{player1}, $_->{servedby} || 8888888,
		$_->{t}, $_->{ts}, $_->{begin}, $_->{length}, $_->{end},
		$_->{substituted} || 0, $_->{matched} || 0,
		$_->{linked}  ? $_->{linked}{_id} : '-',
		$_->{link}    ? $_->{link}{_id}   : '-',
		$_->{expired} ? 'X' : 'O';
}

sub dump_pbox ($) {

	my $pbox = shift;

	for my $t (0,1) {
		for (@{$pbox->[$t]}) {
			dump_penalty($_);
		}
		print "--- Done Team $t\n";
	}
}

sub is_major_penalty ($$) {

	my $penalty       = shift;
	my $penalty_names = shift;

	$penalty eq ($penalty_names->{'ATTEMPT TO/DELIBERATE INJURY - MATCH PENALTY'} ||'')
		|| $penalty eq ($penalty_names->{'MATCH - DELIBERATE INJURY'} ||'')
		|| $penalty eq ($penalty_names->{'KICKING'} ||'')
#	|| $penalty eq $penalty_names->{ 'AGGRESSOR');
#	|| $penalty eq $penalty_names->{ 'GROSS MISCONDUCT')
}

sub check_gross_misconduct ($$$) {

	my $penalty          = shift;
	my $gross_misconduct = shift;
	my $penalties        = shift;

	if ($penalty->{penalty} eq ($gross_misconduct ||'')
			&& ! $penalty->{cloned}
			&& $penalty->{length} == 10
			&& $penalty->{description} =~ /MATCH/) {
		my $major = dclone $penalty;
		$major->{length} = 5;
		$major->{_id} *= 10;
		push(@{$penalties}, $major);
		$penalty->{cloned} = 1;
	}
}

sub stack_penalties ($$;$) {

	my $penalty          = shift;
	my $previous_penalty = shift;
	my $ignore_link      = shift || 0;

	return if $penalty->{length} == 10 || $penalty->{length} == 0;
	return if $penalty->{link} && !$ignore_link || (
		defined $previous_penalty->{end} && defined $penalty->{begin}
		&& $previous_penalty->{end} < $penalty->{begin}
	);
	my $t = $penalty->{t}; my $_t = 1-$t;
	debug "$ON_ICE->[$t]$ON_ICE->[$_t] Stacking $previous_penalty->{_id} and $penalty->{_id} ($previous_penalty->{player1}/$penalty->{player1})";
	$previous_penalty->{end}  //=
		$previous_penalty->{begin} + $previous_penalty->{length} * 60;
	$penalty->{begin}              = $previous_penalty->{end};
	$penalty->{link}               = $previous_penalty;
	$previous_penalty->{linked}    = $penalty;
	$previous_penalty->{linked_id} = $penalty->{_id};
	$penalty->{end}                = $penalty->{begin} + $penalty->{length} * 60;
	if ($penalty->{player1} == $previous_penalty->{player1}
			&& $penalty->{length} == $previous_penalty->{length}
			&& $penalty->{length} == 2) {
		$previous_penalty->{double} = 1;
	}
	stack_penalties($penalty->{linked}, $penalty, 1) if $penalty->{linked};
}

sub split_double_minor ($$$) {

	my $penalty   = shift;
	my $penalties = shift;
	my $p         = shift;

	$penalty->{length}  = 2;
	my $penalty2        = dclone $penalty;
	$penalty2->{_id}    = $penalty->{_id} * 10;
	$penalty->{double}  = 1;
	stack_penalties($penalty2, $penalty);
	splice(@{$penalties}, $p, 0, $penalty2);
}

sub check_multiple_penalties_by_player ($$) {

	my $penalty = shift;
	my $pbox    = shift;;

	grep {
		$_->{player1} == $penalty->{player1}
		&& defined $_->{begin} && $_->{begin} <= $penalty->{ts}
		&& defined $_->{end}   && $_->{end} > $penalty->{ts}
	} @{$pbox}
}

sub prepare_penalties ($$$) {

	my $penalty_names = shift;
	my $penalties     = shift;
	my $pbox          = shift;

	my $p = 0;
	for my $penalty (@{$penalties}) {
		$p++;
		$penalty->{linked_id} ||= 0;
		$penalty->{double}    ||= 0;
		if ($penalty->{length} == 2
				&& $CACHE->{$penalty->{player1}}
				&& $CACHE->{$penalty->{player1}} eq 'G') {
			$penalty->{servedby} ||= $UNKNOWN_SERVEDBY++;
		}
		$penalty->{servedby} = $UNKNOWN_SERVEDBY
			if $UNKNOWN_SERVEDBY{$penalty->{_id}};
		next if $penalty->{link};
		$penalty->{begin}  = $penalty->{ts};
		$penalty->{length} = 5
			if is_major_penalty($penalty->{penalty}, $penalty_names);
		check_gross_misconduct(
			$penalty, $penalty_names->{'GROSS MISCONDUCT'}, $penalties
		);
		if ($penalty->{length} == 4) {
			split_double_minor($penalty, $penalties, $p);
		}
		else {
			$penalty->{expired} = 1
				if $penalty->{length} == 10 || $penalty->{length} == 0;
			if ($penalty->{length} == 10) {
				$penalty->{end} = (
					$penalty->{description} =~
						/\bAGGR|MISCONDUCT|\bABUS|\bLEAV|\bHEAD\b/
				) || $penalty->{penalty} eq $penalty_names->{'GROSS MISCONDUCT'}
				? $penalty->{ts}-1
				: die dumper $penalty;
			}
		}
		my @p1 = check_multiple_penalties_by_player(
			$penalty, $pbox->[$penalty->{t}]
		);
		stack_penalties($penalty, shift @p1) while @p1;
		$penalty->{end} //= $penalty->{ts} + $penalty->{length} * 60;
	}
}

sub expire_penalty ($$$$) {

	my $p    = shift;
	my $t    = shift;
	my $ts   = shift;
	my $pbox = shift;

	return if $p->{expired};
	dumper $p unless defined $ts;
	if ($p->{end} <= $ts) {
		my @remaining = grep {
			$_->{end} > $p->{end} && ! $_->{matched}
		} @{$pbox->[$t]};
		my @players = uniq map($_->{player1}, @remaining);
		$p->{expired} = 1;
		increase_onice($t)
			if @players < 2 && ! $p->{substituted}
			&& (! $p->{linked} || $ON_ICE->[$t] == 4);
		if ($ts > 3600 && $p->{end} > 3600 && $p->{stage} == $REGULAR) {
			if (@players && (@players > 1 || ! $p->{linked})) {
				$extra_base++ unless $extra_base == 2;
			}
		}
		else {
			$extra_base-- if $extra_base;
		}
		debug "$ON_ICE->[$t] EXPIRED";
	}
}

sub expire_penalties ($$) {

	my $ts    = shift;
	my $pbox  = shift;

	iterate_2($pbox, undef, \&expire_penalty, $ts, $pbox);
}

sub get_coincidental_penalties ($$) {

	my $penalty = shift;
	my $penalties = shift;

	my %coincidental = map {$_ => [ [], [] ] } (0,2,5,10);
	$coincidental{$penalty->{length}}->[$penalty->{t}][0] = $penalty;
	while ($penalties->[0] && $penalties->[0]{ts} == $penalty->{ts}) {
		my $_event = shift @{$penalties};
		push(@{$coincidental{$_event->{length}}->[$_event->{t}]}, $_event);
	}
	for my $l (2,5) {
		for my $t (0,1) {
			$coincidental{$l}->[$t] = [ sort {
				$a->{player1} <=> $b->{player1}
			} @{$coincidental{$l}->[$t]} ];
		}
	}
	%coincidental;
}

sub assign_0_10 ($%) {

	my $pbox         = shift;
	my %coincidental = @_;

	for my $length (0,10) {
		for my $t (0,1) {
			push(@{$pbox->[$t]}, @{$coincidental{$length}->[$t]});
		}
	}
}

sub apply_captain_decision ($) {

	my $coincidentals = shift;
	for my $t (0,1) {
		if ($CAPTAIN_DECISIONS{$coincidentals->[$t][0]{_id}}) {
			push(@{$coincidentals->[$t]}, shift @{$coincidentals->[$t]});
			return 1;
		}
	}
	0;
}

sub has_coincidental_bench ($) {

	my $coincidentals = shift;

	my @bench = grep {
		$_->{player1} =~ /^80/;
	} (@{$coincidentals->[0]}, @{$coincidentals->[1]}) ;
	(scalar @bench) && ($#{$coincidentals->[0]} || $#{$coincidentals->[1]}) ? 1 : 0;
}

sub get_c52_count ($$$) {

	my $coincidentals = shift;
	my $pbox          = shift;
	my $length        = shift;

	my $c5_2 = 1;
	if ($length == 2) {
		for my $t (0,1) {
			my $c = $coincidentals->[$t][0];
			my @count = grep {
				$c->{ts} == $_->{ts}
				&& ($c->{player1} == $_->{player1} || $_SEASON <= 2000)
				&& $_->{length} == 5
			} @{$pbox->[$t]};
			$c5_2 *= @count;
		}
	}
	$c5_2;
}

sub adjudicate_substitute ($$$$) {

	my $length           = shift;
	my $coincidentals    = shift;
	my $has_coincidental = shift;
	my $c5_2             = shift;

	return 1 if $FORCE_SUBSTITUTE{$coincidentals->[0][0]{_id}} ||
		$FORCE_SUBSTITUTE{$coincidentals->[1][0]{_id}};
	$length == 2 && (
		$ON_ICE->[0] == 6 && $ON_ICE->[1] == 6
			||
		$ON_ICE->[0] == 5 && $ON_ICE->[1] == 5
		&& $coincidentals->[0][0]{stage} == $REGULAR
		&& $coincidentals->[0][0]{period} > 3
		&& (
			$coincidentals->[0][0]{season} > 2003
			|| $coincidentals->[0][0]{season} < 2002
		)
	) && (
			@{$coincidentals->[0]} == 1 && @{$coincidentals->[1]} == 1
			|| has_coincidental_bench($coincidentals)
		)
		&& ! $c5_2
		&& ! $$has_coincidental
		&& ! (has_coincidental_bench($coincidentals) && $_SEASON != 2002)
		? 0 : 1;
}

sub assign_coincidentals ($$$$) {

	my $pbox             = shift;
	my $coincidentals    = shift;
	my $length           = shift;
	my $has_coincidental = shift;

	COINC:
	while ($coincidentals->[0][0] && $coincidentals->[1][0]) {
		debug "$ON_ICE->[0]$ON_ICE->[1] Assigning coincidentals $coincidentals->[0][0]{ts} ($coincidentals->[0][0]{_id}) $coincidentals->[1][0]{ts} ($coincidentals->[1][0]{_id})";
		next COINC if apply_captain_decision($coincidentals);
		my $c5_2 = get_c52_count($coincidentals, $pbox, $length);
		my $substitute = adjudicate_substitute(
			$length, $coincidentals, $has_coincidental, $c5_2,
		);
		debug "C52 - $c5_2 HC $$has_coincidental SUB $substitute";
		for my $t (0,1) {
			my $coincidental = shift @{$coincidentals->[$t]};
			if ($substitute) {
				$coincidental->{substituted} = 1;
			}
			else {
				decrease_onice($t);
			}
			$coincidental->{matched} = 1;
			push(@{$pbox->[$t]}, $coincidental);
			while ($coincidental->{linked}) {
				my $c         = $coincidental->{linked};
				$c->{begin}  -= $coincidental->{length}*60;
				$c->{end}    -= $coincidental->{length}*60;
				$coincidental = $coincidental->{linked};
			}
		}
		$$has_coincidental = 1 if $length == 2
			|| ($_SEASON > 2005 && $_SEASON < 2008)
			|| $_SEASON > 2009 || $_SEASON == 2003 || $_SEASON == 2001;
	}
}

sub assign_different_coincidentals ($%) {

	my $pbox          = shift;
	my %coincidentals = @_;

	my $t = $coincidentals{5}->[0][0] && $coincidentals{2}->[1][0]
		? 0 : $coincidentals{5}->[1][0] && $coincidentals{2}->[0][0]
		? 1 : return;
	return if (
		@{$pbox->[1-$t]} &&
		! $pbox->[1-$t][-1]{expired} && ! $pbox->[1-$t][-1]{matched}
	);
	my $c5 = [grep { ! $_->{matched} } @{$coincidentals{5}->[ $t ]} ];
	my $c2 = [grep { ! $_->{matched} } @{$coincidentals{2}->[1-$t]} ];
	return if ! @{$c5} || ! @{$c2} || $STRANGE_52{$c2->[0]{game_id}};
	debug "C5 $c5->[0]{_id} C2 $c2->[0]{_id}";
	if (@{$c2} == 1) {
		$c5->[0]{end} -= 120;
		$c2->[0]{end} -= 120;
		$c5->[0]{matched} = 1;
		$c2->[0]{matched} = 1;
	}
	elsif (@{$c2} == 2 && $c2->[0]{linked} || $c2->[0]{ts} == $c2->[1]{ts}) {
		$c5->[0]{end} -= 240;
		$c2->[0]{end} -= 120;
		$c2->[0]{linked}
			? $c2->[0]{linked}{end} -= 240
			: $c2->[1]{end}         -= 120;
		$c5->[0]{matched} = 0;
		$c2->[0]{matched} = 0;
		$c2->[0]{linked}
			? $c2->[0]{linked}{matched} = 0
			: $c2->[1]{matched}         = 0;
	}
}

sub has_same_player1_or_servedby ($$) {

	my $p1 = shift;
	my $p2 = shift;

	$p1->{player1} == $p2->{player1} && $p1->{player1} !~ /^800/
		|| $p2->{servedby} && $p1->{player1} == $p2->{servedby}
		|| $p1->{servedby} && $p2->{player1} == $p1->{servedby}
}

sub find_same_player_penalty ($$) {

	my $pbox    = shift;
	my $penalty = shift;

	my $same_player_penalty = (grep {
		! $_->{matched}
		&& ! $_->{linked}
		&& $_->{end} > $penalty->{ts}
		&& has_same_player1_or_servedby($_, $penalty)
	} @{$pbox})[0];

	$same_player_penalty && (
		($same_player_penalty->{servedby} || 0) == ($penalty->{servedby} || 0)
			||
		($same_player_penalty->{ts}) == ($penalty->{ts})
	) ? $same_player_penalty : 0;
}

sub find_stack_penalty ($$$) {

	my $pbox    = shift;
	my $penalty = shift;
	my $t       = shift;

	return $pbox->[$t][-1] if $FORCE_STACK{$penalty->{_id}};
	my $same_player_penalty = find_same_player_penalty($pbox->[$t], $penalty);
	return $same_player_penalty if $same_player_penalty;
	return undef if $ON_ICE->[$t] > 4;

	my @active = sort {
		$a->{end} <=> $b->{end}
	} grep {
		$_->{end} > $penalty->{ts} && ! $_->{substituted}
	} @{$pbox->[$t]};
	return if @active < 2;
	my @penalized = uniq map($_->{player1}, @active);
	return if @penalized < 2;
	my $offset = @active - 2;
	$offset = 0 if $offset < 0;
	debug "SOFF $offset";
	$offset-- while $active[$offset]
		&& $active[$offset]->{linked} && ! $active[$offset]->{matched};
	debug ($penalty->{_id} . ' ' . $active[$offset]->{_id})	if $active[$offset];
	$active[$offset];
}

sub assign_remaining ($$$) {

	my $pbox      = shift;
	my $penalties = shift;
	my $length    = shift;

	my $t = @{$penalties->[0]} ? 0 : 1;
#	dumper $penalties;
	my @sorted = sort {
		$b->{player1} <=> $a->{player1} || $a->{length} <=> $b->{length}
	} @{$penalties->[$t]};
	while (my $penalty = shift @sorted) {
		debug "$ON_ICE->[0]$ON_ICE->[1] REM: $penalty->{_id} $penalty->{player1}";
		my $stack_penalty = find_stack_penalty($pbox, $penalty, $t);
		if ($stack_penalty) {
			stack_penalties($penalty, $stack_penalty);
		}
		else {
			decrease_onice($t) unless $penalty->{linked};
		}
		push(@{$pbox->[$t]}, $penalty);
	}
}

sub process_penalties ($$) {

	my $penalties = shift;
	my $pbox      = shift;

	while (my $event = shift @{$penalties}) {
		debug "$ON_ICE->[0]$ON_ICE->[1] before At TS $event->{ts}";
		expire_penalties($event->{ts}, $pbox);
		if ($event->{period} == 4 and $event->{stage} == $REGULAR) {
			if ($event->{season} < 2015) {
				if ($ON_ICE->[0] == 6 && $ON_ICE->[1] == 6) {
					$ON_ICE->[0] = 5; $ON_ICE->[1] = 5;
				}
				elsif ($ON_ICE->[0] == 6 && $ON_ICE->[1] == 5) {
					$ON_ICE->[0] = 5; $ON_ICE->[1] = 4;
				}
				elsif ($ON_ICE->[0] == 5 && $ON_ICE->[1] == 6) {
					$ON_ICE->[0] = 4; $ON_ICE->[1] = 5;
				}
			}
			debug "$ON_ICE->[0]$ON_ICE->[1] after At TS $event->{ts}";
		}
		my %coincidental = get_coincidental_penalties($event, $penalties);
		my $t = $event->{t}; my $_t = 1-$t;
		assign_0_10($pbox, %coincidental);
		my $hc = 0;
		for (5,2) {
			assign_coincidentals($pbox, $coincidental{$_}, $_, \$hc);
			assign_different_coincidentals($pbox, %coincidental)
				if $event->{period} > 3 || $event->{ts} >= 3300 && $_ == 2;
			assign_remaining($pbox, $coincidental{$_}, $_);
		}
		debug "OI: $ON_ICE->[0]$ON_ICE->[1]";
	}
}

sub get_active_penalties ($$) {

	my $pbox  = shift;
	my $event = shift;

	my @results = map {
		[
			sort { $a->{begin} <=> $b->{begin} } grep {
				(
					$_->{begin} < $event->{ts}
					|| $_->{begin} == $event->{ts} && $_->{link}
				) &&
				(
					$_->{end} > $event->{ts}
					&& ! $_->{substituted}
				)
			} @{$pbox->[$_]}
		]
	} (0,1);
	@results;
}

sub set_indicator ($$$@) {

	my $indicator = shift;
	my $event     = shift;
	my $pbox      = shift;
	my @active    = @_;


	if ($FORCE_ICE{$event->{_id}}) {
		$indicator->{type} = $FORCE_ICE{$event->{_id}};
	}
	else {
		my $c1 = scalar @{$active[ $event->{t} ]};
		my $c2 = scalar @{$active[1-$event->{t}]};
		my $base = $event->{period} == 4 && $event->{stage} == $REGULAR ? 5 : 6;
		$base += $extra_base if $base < 6;
		debug "B $base c1 $c1 c2 $c2 EB $extra_base p $event->{period}";
		$indicator->{type} = ($base-$c1) . ($base-$c2);
		$indicator->{type} += 10*$c1 + $c2 if
			$c1 == 1 && $c2 == 1 &&
			$event->{period} == 4 && $event->{stage} == $REGULAR &&
			$active[0][0]->{matched} && ! $active[0][0]->{substituted} &&
			$active[0][0]->{period} == 3;
	}
	my $str;
	$indicator->{type} += 11
		if $indicator->{type} == 34 || $indicator->{type} == 43
		|| $indicator->{type} == 35 || $indicator->{type} == 53;
	$indicator->{type} -= 11
		if $indicator->{type} > 66 && $event->{period} > 3
		&& $event->{stage} == $REGULAR;
	for ($indicator->{type}) {
		when (66) { $str = 'EV5' };
		when (55) { $str = 'EV4' };
		when (44) { $str = 'EV3' };
		when (65) { $str = 'PP1' };
		when (64) { $str = 'PP2' };
		when (54) { $str = 'PP3' };
		when (56) { $str = 'SH1' };
		when (46) { $str = 'SH2' };
		when (45) { $str = 'SH3' };
		default {
			dump_pbox($pbox);
			die "$event->{_id} @ $event->{ts}: Strange type $indicator->{type} ($ON_ICE->[0]$ON_ICE->[1])\n";
		}
	}
	$indicator->{str} = $str;
}

sub mark_scores ($@) {

	my $event         = shift;
	my @sorted_active = @_;

	my @unmatched = grep {
		! $_->{substituted} && ! $_->{matched}
	} @sorted_active;
	for my $p (@unmatched) {
		$p->{scored} ||= [];
		push(@{$p->{scored}}, $event->{_id});
	}
}

sub terminate_penalty ($@) {

	my $event  = shift;
	my @active = @_;

	my @sorted_active = sort {
		$a->{length} <=> $b->{length} || $a->{end} <=> $b->{end}
			||
		$b->{linked_id} * (1-$b->{double}) <=> $a->{linked_id} * (1-$a->{double})
	} @{$active[1-$event->{t}]};
	my $_c = firstidx {
		! $_->{substituted} && ! $_->{matched} && $CAPTAIN_DECISIONS{$_->{_id}}
	} @sorted_active;
	if ($_c == -1) {
		$_c = firstidx {
			! $_->{substituted} && ! $_->{matched}
		} @sorted_active;
	}
	return if $_c == -1;
	debug "_C : $_c";
	mark_scores($event, @sorted_active);
	my $p = $sorted_active[$_c];
	if ($p->{length} != 5) {
		debug "Terminating $p->{_id} $p->{begin}-$p->{end}";
		$p->{end}        = $event->{ts};
		$p->{expired}    = 1;
		$p->{terminated} = 1;
		my $link_advance = 0;
		while ($p->{linked}) {
			my $pend = $p->{end};
			$p = $p->{linked};
			$p->{begin} = $pend;
			$p->{end}   = $p->{begin} + $p->{length}*60;
			$link_advance++;
		}
		$ON_ICE->[1-$event->{t}]++ unless
			(
				$event->{stage} == $REGULAR && $event->{period} > 3
				&& $ON_ICE->[1-$event->{t}] >= 5
			) || (
				$ON_ICE->[1-$event->{t}] == 6
			) || $link_advance;
	}
}

sub restore_on_ice_player ($$) {

	my $event = shift;
	my $pbox  = shift;

	my $t = 1 - $event->{t};
	my @ending = grep {
		$_->{end} == $event->{ts} && ! $_->{substituted}
		&& ! ($_->{scored} && $_->{length} != 5) && ! $_->{linked} && ! $_->{matched}
	} @{$pbox->[$t]};
	while (@ending && @{$event->{on_ice}[$t]} < 6) {
		my $e = shift @ending;
		my $p = $e->{servedby} || $e->{player1};
		debug "Reinstating $p\n";
		push(@{$event->{on_ice}[$t]}, $p)
			unless grep { $_ == $p } @{$event->{on_ice}[$t]};
	}
}

sub get_real_on_ice ($) {

	my $event = shift;

	my $boi = $BROKEN_ON_ICE_COUNT{$event->{_id}};
	my $GOAL_c = $DB->get_collection('GOAL');
	if ($boi) {
		$GOAL_c->update_one({
			_id => $event->{_id},
		}, {
			'$set' => {
				ice_count => $boi,
			},
		})
	}
	my $t   = $event->{t};
	my $on_ice = $boi
		? (substr($boi, 2*$t,     1) + substr($boi, 2*$t+1,     1))
		. (substr($boi, 2*(1-$t), 1) + substr($boi, 2*(1-$t)+1, 1))
		: scalar(@{$event->{on_ice}[$t]}) . scalar(@{$event->{on_ice}[1-$t]});
	$on_ice;
}

sub process_goal ($$) {

	my $goal = shift;
	my $pbox = shift;

	expire_penalties($goal->{ts}, $pbox);
	my $indicator = { type => 66, str => 'EV5', oi => join('', @{$ON_ICE}) };
	my $t = $goal->{t}; my $_t = 1-$goal->{t};
	my $moi = "$ON_ICE->[$t]$ON_ICE->[$_t]";
	if (@{$pbox}) {
		my @active = get_active_penalties($pbox, $goal);
		set_indicator($indicator, $goal, $pbox, @active);
		if ($indicator->{type} % 11 > 8) {
			terminate_penalty($goal, @active);
		}
	}
	return unless $goal->{on_ice};
	restore_on_ice_player($goal, $pbox);
	my $on_ice = get_real_on_ice($goal);
	debug "$goal->{_id} @ $goal->{ts} str: $indicator->{str} type: $indicator->{type} oi: $on_ice moi: $moi";
	if ($on_ice != $indicator->{type} && !(
		$goal->{stage} == $REGULAR && $goal->{period} == 4
		&& $indicator->{type} - $on_ice == 11
	)) {
		if ($on_ice <= 22 && $goal->{season} < 2000) {
			my $GOAL_c = $DB->get_collection('GOAL');
			$GOAL_c->update_one({
				_id => $goal->{_id},
			}, {
				'$set' => {
					penaltyshot => 1,
				}
			})
		}
		else {
			dump_pbox($pbox);
			die "$goal->{game_id} Mismatch!\n";
		}
	}
}

sub clone_match_penalty ($$) {

	my $penalty = shift;
	my $gend    = shift;

	my $match_penalty = dclone $penalty;
	$match_penalty->{_id} = $penalty->{_id} * 10;
	$match_penalty->{length} = 20;
	$match_penalty->{severity} = 'MATCH';
	$match_penalty->{finish} = $gend;
	$match_penalty->{cloned} = 1;
	delete $match_penalty->{link};
	delete $match_penalty->{linked};
	my $result = insert('PENL', $match_penalty);
	print "Inserted $result->{inserted_id}\n";

}

sub update_penalty ($$$) {

	my $penalty    = shift;
	my $misconduct = shift;
	my $gend       = shift;

	if ($penalty->{length} == 10) {
		if ($penalty->{penalty} eq $misconduct) {
			$penalty->{finish} = $penalty->{begin} + 600;
			$penalty->{severity} = 'MISCONDUCT';
		}
		else {
			$penalty->{finish} = $gend;
			$penalty->{severity} = 'GAME MISCONDUCT';
		}
	}
	elsif ($penalty->{length} == 5 && $penalty->{description} && (
		$penalty->{description} =~ /\bMATCH\b/
		|| $penalty->{description} =~ /INJUR/
	) && length($penalty->{_id} == 13)) {
		clone_match_penalty($penalty, $gend);
	}
	else {
		$penalty->{finish} = $penalty->{end};
		$penalty->{severity} ||=
			$penalty->{length}   == 2 ? 'MINOR'
			: $penalty->{length} == 4 ? 'DOUBLE-MINOR'
			: $penalty->{length} == 5 ? 'MAJOR'
			: $penalty->{length} == 0 ? 'PS'
			: die "UNKNOWN LENGTH " . Dumper $penalty->{_id};
	}
	$penalty->{finish} ||= $penalty->{end};
	delete $penalty->{link};
	delete $penalty->{linked};
	$penalty->{finish} = $gend if $penalty->{finish} > $gend;
	insert('PENL', $penalty);
	debug "Updated $penalty->{_id}";

}

sub update_penalties ($$$) {

	my $pbox          = shift;
	my $penalty_names = shift;
	my $gend          = shift;

	iterate_2($pbox, undef, \&update_penalty, $penalty_names->{MISCONDUCT}, $gend);
}

sub analyze_game_penalties ($;$) {

	my $game    = shift;
	my $dry_run = shift || 0;

	$DB ||= Sport::Analytics::NHL::DB->new();
	$game = $DB->get_collection('games')->find_one({_id => $game+0}) if ! ref $game;
	return if $game->{season} < $FIRST_DETAILED_PENL_SEASON;
	$_SEASON = $game->{season};
	$ON_ICE  = [6,6];
	gamedebug $game, 'Penalty analysis';
	my $PENL_c = $DB->get_collection('PENL');
	my @penalties = grep {
		! $IGNORE_PENALTIES{$_->{_id}} && length($_->{_id}) == 13
		&& ! $_->{finish}
	} sort { $a->{ts} <=> $b->{ts} } (
		$PENL_c->find({game_id => $game->{_id}})->all()
	);
	return unless @penalties;
	create_player_cache($game);
	my $GOAL_c = $DB->get_collection('GOAL');
	fill_broken($_, $BROKEN_PENALTIES{$_->{_id}}) for @penalties;
	my $penalty_names = get_catalog_map('penalties');
	my @goals = sort { $a->{ts} <=> $b->{ts} } (
		$GOAL_c->find({
			game_id => $game->{_id} + 0,
			penaltyshot => 0,
		})->all(),
	);
	push(@goals, {ts => 3600, type => 'PEND', stage => $game->{stage}})
		if !@goals || $goals[-1]{ts} < 3600;
	my $info = { offsets => [] };
	my $pbox = [[], []];
	my $last_ts = -1;
	for my $goal (@goals) {
		my @preceding_penalties = grep {
			$_->{ts} >= $last_ts && $_->{ts} < $goal->{ts}
		} @penalties;
		$last_ts = $goal->{ts};
		prepare_penalties($penalty_names, \@preceding_penalties, $pbox);
		process_penalties(\@preceding_penalties, $pbox);
		process_goal($goal, $pbox) if $goal->{type} eq 'GOAL';
	}
	if (! $game->{length}) {
		my $GEND_c = $DB->get_collection('GEND');
		my $gend = $GEND_c->find_one({game_id => $game->{_id}});
		update(
			0, 'games', {_id => $game->{_id}}, {'$set' => {length => $gend->{ts}}}
		);
		$game->{length} = $gend->{ts};
	}
	expire_penalties($game->{length}, $pbox,);
	update_penalties($pbox, $penalty_names, $game->{length}) unless $dry_run;
	$ON_ICE = [6,6];
}

sub init_strengths () {

	$DB ||= Sport::Analytics::NHL::DB->new();
	my $str_c = $DB->get_collection('str');

	my $count = $str_c->estimated_document_count();
	if (! $count) {
		ensure_index($str_c, [{
			keys => [ game_id => 1, from => 1 ], options => { unique => 1 }
		}]);
	}
	$str_c;
}


sub get_strength_affecting_penalties ($) {

	my $game = shift;

	my $PENL_c = $DB->get_collection('PENL');

	my $gend = $game->{length};
	my @penalties = grep { ! $IGNORE_PENALTIES{$_->{_id}} } sort {
		$a->{begin} <=> $b->{begin}
	} grep {
		$_->{begin} ||= $_->{ts};
		$_->{finish} ||= $_->{begin} + 60 * $_->{length};
		$_->{finish} = $gend if $_->{finish} > $gend;
		$_->{end} = $_->{length} == 0 || $_->{length} > 5 ?
			$_->{begin}-1 : $_->{finish};
		$_->{finish} = $_->{begin} + 300 if
			$_->{length} == 5 && $_->{description} && (
				$_->{description} =~ /\bMATCH\b/ || $_->{description} =~ /INJUR/
			);
		1;
	} ($PENL_c->find({game_id => $game->{_id} + 0})->all());

	@penalties;
}

sub set_timeline ($$) {

	my $game      = shift;
	my $penalties = shift;

	my @timeline = ();
	for my $penalty (@{$penalties}) {
		push(
			@timeline,
			[ $penalty, $penalty->{begin},  1 ],
			[ $penalty, $penalty->{finish}, 0 ],
		);
	}
	push(@timeline, [ {period => 3, stage => $game->{stage}}, 3600, -1])
		if $game->{stage} == $REGULAR;
	@timeline = sort {
		$a->[1] <=> $b->[1] || $a->[2] <=> $b->[2]
	} grep {
		$_->[1] != $game->{length} || $_->[2] == -1
	} @timeline;

	@timeline;
}

sub update_on_ice_for_ot ($$) {

	my $on_ice = shift;
	my $game   = shift;

	if ($game->{season} >= 1999) {
		if ($on_ice->[0] == $on_ice->[1]+1) {
			$on_ice->[0] = 4;
			$on_ice->[1] = 3;
		}
		elsif ($on_ice->[1] == $on_ice->[0]+1) {
			$on_ice->[0] = 3;
			$on_ice->[1] = 4;
		}
		elsif ($on_ice->[0] == $on_ice->[1] && $on_ice->[0] != 3) {
			$_base = $game->{season} >= 2015 ? 3 : 4;
			$on_ice->[0] = $_base;
			$on_ice->[1] = $_base;
		}
	}
}

sub update_stack_on_ice_match ($$$$) {

	my $p      = shift;
	my $on_ice = shift;
	my $stack  = shift;
	my $match_ = shift;

	$p->[0]{matched} ||= 0;
	if ($p->[2] == 1) {
		if ($p->[0]{matched}) {
			if ($on_ice->[0] == 5 && $on_ice->[1] == 5) {
				$on_ice->[0] = 4;
				$on_ice->[1] = 4;
			}
		}
		else {
			$on_ice->[$p->[0]{t}] > 3
				? $on_ice->[$p->[0]{t}]--
				: $stack->[$p->[0]{t}]++;
		}
	}
	else {
		if ($p->[0]{matched}) {
			if ($$match_) {
				$$match_--;
			}
			else {
				$$match_ = 1;
				if ($on_ice->[0] < $_base && $on_ice->[1] < $_base) {
					$stack->[0] ? $stack->[0]-- : $on_ice->[0]++;
					$stack->[1] ? $stack->[1]-- : $on_ice->[1]++;
				}
			}
		}
		elsif (! $p->[0]{linked}) {
			$stack->[$p->[0]{t}]
				? $stack->[$p->[0]{t}]--
				: $on_ice->[$p->[0]{t}]++;
		}
	}
}

sub push_strengths ($$$$$) {

	my $strengths = shift;
	my $current   = shift;
	my $p_time    = shift;
	my $game      = shift;
	my $on_ice    = shift;

	my $GOAL_c = $DB->get_collection('GOAL');
	my @goals = $GOAL_c->find({
		game_id => $game->{_id}+0,
		ts      => {
			'$gt'  => $current,
			'$lte' => $p_time+0,
		},
	})->all();
	my $_on_ice = dclone $on_ice;
	push(
		@{$strengths}, {
			game_id => $game->{_id},
			from    => $current,
			to      => $p_time,
			length  => $p_time - $current,
			away    => $game->{teams}[0]{name},
			home    => $game->{teams}[1]{name},
			on_ice  => $_on_ice,
			scored  => [ map($_->{_id}, @goals) ]
		}
	);
}

sub set_strengths ($;$) {

	my $game    = shift;
	my $dry_run = shift || 0;

	$game = $DB->get_collection('games')->find_one({_id => $game+0}) if ! ref $game;
	return if $game->{season} < $FIRST_DETAILED_PENL_SEASON;
	my $str_c = init_strengths();
	gamedebug $game, 'Set strengths';

	my @penalties = get_strength_affecting_penalties($game);
	return unless @penalties;
	my @timeline  = set_timeline($game, \@penalties);
	my $current = 0;
	$_base = 5;
	my $on_ice = [$_base,$_base];
	my $stack = [0,0];
	my @strengths;
	my $match = 0;
	for my $p (@timeline) {
		next if $p->[0]{period} > 4 && $p->[0]{stage} == $REGULAR;
#		print "$current $p->[0]{begin} $p->[0]{end} $p->[1] $p->[2]\n";
		push_strengths(\@strengths, $current, $p->[1], $game, $on_ice)
			if $current != $p->[1];
		$current = $p->[1];
		if ($p->[2] == -1 && $game->{stage} == $REGULAR) {
			update_on_ice_for_ot($on_ice, $game);
			next;
		}
		next if $p->[0]{substituted}
			|| $p->[0]{length} == 0 || $p->[0]{length} > 5
			|| $p->[0]{end} <= $p->[0]{begin};
		update_stack_on_ice_match($p, $on_ice, $stack, \$match);
		$p->[0]{matched} ||= 0;
		die "Gevalt! " . dumper $on_ice, $_base, $p->[0], \@strengths,
			if $on_ice->[0] > 5 || $on_ice->[1] > 5;
	}
	push_strengths(\@strengths, $current, $game->{length}, $game, $on_ice)
		if $current != $game->{length};
	insert('str', @strengths) unless $dry_run;
}

1;

=head1 AUTHOR

More Hockey Stats, C<< <contact at morehockeystats.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<contact at morehockeystats.com>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Sport::Analytics::NHL::PenaltyAnalyzer>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Sport::Analytics::NHL::PenaltyAnalyzer

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Sport::Analytics::NHL::PenaltyAnalyzer>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Sport::Analytics::NHL::PenaltyAnalyzer>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Sport::Analytics::NHL::PenaltyAnalyzer>

=item * Search CPAN

L<https://metacpan.org/release/Sport::Analytics::NHL::PenaltyAnalyzer>

=back

=cut
