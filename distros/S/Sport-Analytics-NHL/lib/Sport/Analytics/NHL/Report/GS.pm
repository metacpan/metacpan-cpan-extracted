package Sport::Analytics::NHL::Report::GS;

use v5.10.1;
use strict;
use warnings FATAL => 'all';
use experimental qw(smartmatch);

use parent 'Sport::Analytics::NHL::Report';

use utf8;

use Sport::Analytics::NHL::Config qw(:basic :ids);
use Sport::Analytics::NHL::Errors;
use Sport::Analytics::NHL::Util qw(:utils :times :debug);
use Sport::Analytics::NHL::Tools qw(:parser);

use Data::Dumper;

=head1 NAME

Sport::Analytics::NHL::Report::GS - Class for the NHL HTML GS report.

=head1 SYNOPSYS

Class for the NHL HTML GS report. Should not be constructed directly, but via Sport::Analytics::NHL::Report (q.v.)
As with any other HTML report, there are two types: old (pre-2007) and new (2007 and on). Parsers of them may have something in common but may turn out to be completely different more often than not.

=head1 METHODS

=over 2

=item C<normalize>

Cleaning up and standardizing the parsed data.

 Arguments: none
 Returns: void. Everything is in the $self.

=item C<normalize_new>

Cleaning up and standardizing the parsed data from the new report.

 Arguments: none
 Returns: void. Everything is in the $self.

=item C<normalize_old>

Cleaning up and standardizing the parsed data from the old report.

 Arguments: none
 Returns: void. Everything is in the $self.

=item C<normalize_scoring_event>

Apply specific normalization to a scoring event.

 Arguments: the scoring event hashref
 Returns: void. Everything is fixed within the hashref.

=item C<parse>

Parse the GS html tree into a boxscore object

 Arguments: none
 Returns: void. Everything is in the $self.

=item C<parse_goaltender_summary>

Parse the goaltending summary in the new GS report

 Arguments: the goaltender summary HTML element
 Returns: void. It's in the $self

=item C<parse_misc_summary>

Parse the misc information summary in the old GS report

 Arguments: the misc summary HTML element
 Returns: void.

=item C<parse_new_misc_summary>

Parse the misc information summary in the new GS report

 Arguments: the misc summary HTML element
 Returns: void.

=item C<parse_new_penalty_event>

Parse the entry of a penalty event in the new GS report

 Arguments: the HTML element of the penalty
 Returns: the parsed event

=item C<parse_new_pp_summary>

=item C<parse_penalty_event>

Parse the entry of a penalty event in the old GS report

 Arguments: the HTML element of the penalty
 Returns: the parsed event

=item C<parse_penalty_summary>

Parse penalty summary in the both old and new GS reports

 Arguments:
 * the HTML element with the summary
 * the flag of format (old/new)

=item C<parse_pp_summary>

Parse powerplay success summary in the new GS report

 Arguments: the HTML element with the PP summary
 Returns: void

=item C<parse_scoring_event>

Parse the entry of a scoring event in the both new and old GS reports.

 Arguments: the HTML element of the goal
 Returns: the parsed event

=item C<parse_scoring_summary>

Parse scoring summary in the both old and new GS reports

 Arguments:
 * the HTML element with the summary
 * the flag of format (old/new)
 Returns: void.

=back

=cut

my %NORMAL_FIELDS = (
	pp => 'powerPlayTimeOnIce', sh => 'shortHandedTimeOnIce', ev => 'evenTimeOnIce',
	toitot => 'timeOnIce', wl => 'decision',
);

our $is_special = 0;

sub parse_scoring_event ($$;$) {

	my $self   = shift;
	my $row    = shift;
	my $is_new = shift;

	my $event = {on_ice => []};

	my $is_goal = $self->get_sub_tree(0, [$is_new ? (0,0) : (0,0,0)], $row);
	$event->{type}      = $is_goal =~ /\d/ ? 'GOAL' : 'MISS';
	my $offset = $event->{type} eq 'MISS' ? 1 : 0;
	$event->{period}    = $self->get_sub_tree(0, [$is_new ? (1,0) : (1,0,0)], $row);
	return undef if !$is_special && $event->{period} !~ /\w/;
	$event->{time}      = $self->get_sub_tree(0, [$is_new ? (2,0) : (2,0,0)], $row);
	$event->{team1}     = $self->get_sub_tree(0, [$is_new ? (4,0) : (3,0,0)], $row);
	$event->{player1}   = $self->get_sub_tree(0, [$is_new ? (5,0) : (4,0,0)], $row);
	if ($event->{type} eq 'GOAL') {
		$event->{assist1}   = $self->get_sub_tree(0, [$is_new ? (6,0) : (5,0,0)], $row);
		$event->{assist2}   = $self->get_sub_tree(0, [$is_new ? (7,0) : (6,0,0)], $row);
	}
	if ($is_special) {
		$event->{special} = 1;
		$is_special = 0;
		return $event;
	}
	$event->{strength} = $self->get_sub_tree(0, [$is_new ? (3,0) : (9,0,0)], $row);
	if ($event->{period} eq 'OT') {
		$event->{period} = 4;
	}
	elsif ($event->{period} eq 'SO' || $event->{period} eq 'F') {
		$event->{period}  = 5;
		$event->{strength}     = 'PS';
		$event->{time}    = '0:00';
		$event->{assist1} = 'unassisted';
		$event->{penaltyshot} = 1;
	}
	if ($event->{assist1} && $event->{assist1} =~ /unsuccessful/i) {
		$event->{type} = 'MISS';
		$offset = 1;
	}
	if (ref $event->{assist2}) {
		$event->{assist2} = undef;
		$offset = 1;
	}
	if ($event->{type} eq 'MISS') {
		$event->{description} = 'Missed Penalty Shot';
		$event->{assist1} = $event->{assist2} = undef;
	}

	if ($event->{strength} =~ /(.*)-EN/) {
		$event->{strength} = $1;
		$event->{en} = 1;
	}
	elsif ($event->{strength} =~ /(.*)-\s*PS/ || $event->{type} eq 'MISS') {
		$event->{strength} = $1 if $1;
		$event->{penaltyshot} = 1;
		$event->{shot_type} = 'Unknown';
		$event->{assist1} = undef;
		$event->{location} = 'Off';
		$event->{distance} = 999;
		$event->{miss} = 'Unknown';
		$event->{team1} =~ s/\s//g;
	}
	$event->{en} ||= 0;
	if ($is_new) {
		for my $i (8,9) {
			my $on_ice = $self->get_sub_tree(0, [$i-$offset], $row);
			my $n = 0;
			while (my $on_ice_num = $self->get_sub_tree(0, [$n,0], $on_ice)) {
				$event->{on_ice}[$i-8] ||= [];
				push(@{$event->{on_ice}[$i-8]}, $on_ice_num);
				$n += 2;
			}
		}
	}
	else {
		$event->{on_ice}[0] = [ $self->get_sub_tree(0, [7,0,0], $row) || $self->get_sub_tree(0, [8,0], $row) ];
		$event->{on_ice}[1] = [ $self->get_sub_tree(0, [8,0,0], $row) || $self->get_sub_tree(0, [9,0], $row) ];
	}
	if ($event->{penaltyshot} && (ref $event->{on_ice}[0][0] || ref $event->{on_ice}[1][0])) {
		$event->{on_ice}[0] = [];
		$event->{on_ice}[1] = [];
	}
	return undef if ref $event->{on_ice}[0][0];
#	print Dumper $event->{team1};
	$event->{shot_type} = 'Unknown';
	$event->{location} = 'Unk';
	$event->{distance} = 999;
	$event;
}

sub normalize_scoring_event ($$) {

	my $self  = shift;
	my $event = shift;

	my @keys = keys %{$event};
	for my $key (@keys) {
		if ($key eq 'on_ice') {
			for my $on_ice (@{$event->{$key}}) {
				$on_ice =~ s/^\s//;
				$on_ice =~ s/\s$//;
				$on_ice = [split(/\s+/, $on_ice)];
			}
		}
		else {
			$event->{$key} =~ s/^\s//;
			$event->{$key} =~ s/\s$//;
			if ($key =~ /^assist/ && ! $event->{$key}) {
				delete $event->{$key};
				next;
			}
			$event->{$key} =~ s/^(.*)\s+\(\d+\)/$1/ge;
		}
	}
}

sub parse_scoring_summary ($$;$) {

	my $self            = shift;
	my $scoring_summary = shift;
	my $is_new          = shift || 0;

	my $events = [];
	my $r = $is_new ? 1 : 2;
	while (my $row = $self->get_sub_tree(0, [$r], $scoring_summary)) {
		last unless $row && ref $row;
		$r++;
		my $event = $self->parse_scoring_event($row, $is_new);
		push(@{$events}, $event) if $event;
	}
	$events;
}

sub parse_new_penalty_event ($$) {

	my $self = shift;
	my $row  = shift;

	my $event = {};

	$event->{type}       = 'PENL';
	$event->{period}     = $self->get_sub_tree(0, [1,0], $row);
	$event->{period}     = 4 if $event->{period} eq 'OT';
	$event->{period}     = 5 if $event->{period} eq 'SO';
	$event->{time}       = $self->get_sub_tree(0, [2,0], $row);
	return undef if $event->{time} !~ /:/;
	$event->{player1}    = $self->get_sub_tree(0, [3,0,0,0,0], $row);
	$event->{name}       = $self->get_sub_tree(0, [3,0,0,3,0], $row);
	$event->{length}     = $self->get_sub_tree(0, [4,0], $row);
	$event->{penalty}    = $self->get_sub_tree(0, [5,0], $row);
	$event->{misconduct} = 1 if $event->{penalty} =~ /conduct/;
	$event->{player1}    = $BENCH_PLAYER_ID if $event->{penalty} =~ /\-\s+bench/;
	$event->{player1}    = $COACH_PLAYER_ID if $event->{penalty} =~ /\bcoach\b/i;
	$event->{player1}    = $BENCH_PLAYER_ID if $event->{name} && $event->{name} =~ /\bteam\b/i;
	delete $event->{name};
	$event;
}

sub parse_penalty_event ($$$) {

	my $self = shift;
	my $row  = shift;
	my $t    = shift;

	my $event = {};

	$event->{type}       = 'PENL';
	$event->{period}     = $self->get_sub_tree(0, [1+7*$t,0,0], $row);
	return undef unless $event->{period};
	return undef unless $event->{period} =~ /\w/;
	$event->{period} = 4 if $event->{period} eq 'OT';
	$event->{time}       = $self->get_sub_tree(0, [2+7*$t,0,0], $row);
	$event->{team1}      = $t;
	$event->{number}     = $self->get_sub_tree(0, [3+7*$t,0,0], $row);
	$event->{player1}    = $self->get_sub_tree(0, [4+7*$t,0,0], $row);
	$event->{length}     = $self->get_sub_tree(0, [5+7*$t,0,0], $row);
	$event->{penalty}    = $self->get_sub_tree(0, [6+7*$t,0,0], $row);
	$event->{misconduct} = 1 if $event->{penalty} =~ /conduct/i;
	$event->{player1}    = $BENCH_PLAYER_ID if $event->{penalty} =~ /\-\s+bench/i;
	$event->{player1}    = $COACH_PLAYER_ID if $event->{penalty} =~ /\-\s+coach/i;
	$event;
}

sub parse_penalty_summary ($$;$) {

	my $self            = shift;
	my $penalty_summary = shift;
	my $is_new          = shift || 0;

	my $events = [];
	my @penalty_tables = $is_new ? (
		$self->get_sub_tree(0, [ (1,0,0,0,0,0,0,0,0) ], $penalty_summary),
		$self->get_sub_tree(0, [ (1,0,0,0,0,0,0,3,0) ], $penalty_summary),
	) : ( $penalty_summary );
	if ($is_new) {
		if (! ref $penalty_tables[0]) {
			$penalty_tables[0] = $self->get_sub_tree(0, [ (1,0,0,0,0,0) ], $penalty_summary);
			$penalty_tables[1] = $self->get_sub_tree(0, [ (1,0,0,0,0,3) ], $penalty_summary);
		}
	}
	my $p = 0;
	for my $penalty_table (@penalty_tables) {
		next unless defined $penalty_table;
		my $r = 2 - $is_new;
		while (my $row = $self->get_sub_tree(0, [$r], $penalty_table)) {
			last unless $row && ref $row;
			$r++;
			if ($is_new) {
				my $event = $self->parse_new_penalty_event($row);
				$event->{team1} = $p;
				push(@{$events}, $event) if $event && $event->{type};
			}
			else {
				for my $t (0,1) {
					my $event = $self->parse_penalty_event($row, $t);
					push(@{$events}, $event) if $event->{type};
				}
			}
		}
		$p++;
	}
	$events;
}

sub parse_new_pp_summary ($$$) {

	my $self       = shift;
	my $pp_summary = shift;

	for my $t (0,1) {
		my $pp_team_summary = $self->get_sub_tree(0, [ (1,0,0,0,$t) ], $pp_summary);
		$self->{teams}[$t]{pptype} = {};
		my $pp = 0;
		for my $pptype (qw(5v4 5v3 4v3)) {
			$self->{teams}[$t]{pptype}{$pptype} =
				$self->get_sub_tree(0, [0,1,$pp,0], $pp_team_summary) ||
				$self->get_sub_tree(0, [0,0,0,0,0,0,0,1,$pp,0], $pp_team_summary);
			$pp++;
		}
	}
}

sub parse_pp_summary ($$$) {

	my $self       = shift;
	my $pp_summary = shift;

	$self->{teams}[0]{pp} = [];
	$self->{teams}[1]{pp} = [];
	my $r = 2;
	while (my $row = $self->get_sub_tree(0, [$r], $pp_summary)) {
		$r++;
		next unless ref $row;
		my $period = $self->get_sub_tree(0, [9,0,0], $row);
		if ($period =~ /(\d+)/) {
			$self->{last_period} = $1;
		}
		elsif ($period eq 'OT') {
			$self->{last_period} = 4;
		}
		if ($period =~ /(\d+)/ && $period > 0) {
			$period = $1 - 1;
			my $pp0 = $self->get_sub_tree(0, [10,0,0], $row);
			my $pp1 = $self->get_sub_tree(0, [11,0,0], $row);
			$self->{teams}[0]{pp}[$period] = $pp0;
			$self->{teams}[1]{pp}[$period] = $pp1;
		}
		elsif ($period =~ /time/i) {
			my $pp0 = $self->get_sub_tree(0, [10,0,0], $row);
			my $pp1 = $self->get_sub_tree(0, [11,0,0], $row);
			push(@{$self->{teams}[0]{pp}}, $pp0);
			push(@{$self->{teams}[1]{pp}}, $pp1);
		}
	}
}

sub parse_new_misc_summary ($$$) {

	my $self         = shift;
	my $misc_summary = shift;

	my $officials_table = $self->get_sub_tree(0, [1,0,0], $misc_summary);
	$self->{officials} = {
		referees => [
			$self->get_sub_tree(0, [1,0,0,0,0,0], $officials_table),
			$self->get_sub_tree(0, [1,0,0,1,0,0], $officials_table) || (),
		],
		linesmen => [
			$self->get_sub_tree(0, [1,1,0,0,0,0], $officials_table),
			$self->get_sub_tree(0, [1,1,0,1,0,0], $officials_table) || (),
		],
	};
	unless ($self->{officials}{referees}[0]) {
		$self->{officials} = {
			referees => [
				$self->get_sub_tree(0, [0,1,0,0,0,0], $officials_table),
				$self->get_sub_tree(0, [0,1,0,1,0,0], $officials_table) || (),
			],
			linesmen => [
				$self->get_sub_tree(0, [0,3,0,0,0,0], $officials_table),
				$self->get_sub_tree(0, [0,3,0,1,0,0], $officials_table) || (),
			],
		};
	}
	my $stars_table = $self->get_sub_tree(0, [1,1,0], $misc_summary);
	$self->{stars} = [];
	my $star1 = $self->get_sub_tree(0, [0,0,0,0,1,0], $stars_table);
	my $star_offset = $star1 && $star1 eq 'Team' ? 1 : 0;
	my $t = 0;
	for my $s (0..2) {
		my $team = $self->get_sub_tree(0, [0,0,0,$s+$star_offset,1,0], $stars_table);
		unless ($team && $team =~ /[A-Z]\s*$/) {
			$t--;
			next;
		}
		$self->{stars}[$s]{team}     = $self->get_sub_tree(0, [0,0,0,$s+$star_offset+$t,1,0], $stars_table);
		$self->{stars}[$s]{position} = $self->get_sub_tree(0, [0,0,0,$s+$star_offset+$t,2,0], $stars_table);
		$self->{stars}[$s]{name}     = $self->get_sub_tree(0, [0,0,0,$s+$star_offset+$t,3,0], $stars_table);
	}
}

sub parse_misc_summary ($$$) {

	my $self         = shift;
	my $misc_summary = shift;

	my $goalies_header = $self->get_sub_tree(0, [0,0], $misc_summary);
	my $g_span = $goalies_header->attr('colspan') || $goalies_header->attr('colSpan');
#	dumper $g_span;
#	print $goalies_header->dump; 
	my $g = 2;
	$self->{goalies} = [];
	while (my $goalies_row = $self->get_sub_tree(0, [$g], $misc_summary)) {
		my $goalie = {
			team_decision => $self->get_sub_tree(0, [0,0,0], $goalies_row),
			name          => $self->get_sub_tree(0, [1,0,0], $goalies_row),
			p1            => $self->get_sub_tree(0, [2,0,0], $goalies_row),
			p2            => $self->get_sub_tree(0, [3,0,0], $goalies_row),
			p3            => $self->get_sub_tree(0, [4,0,0], $goalies_row),
			pot           => $self->get_sub_tree(0, [5,0,0], $goalies_row),
			pt            => $self->get_sub_tree(0, [6,0,0], $goalies_row),
			toi           => $self->get_sub_tree(0, [7,0,0], $goalies_row),
			$g_span == 8 ?
				() : (so_stats      => $self->get_sub_tree(0, [$g_span-1,0,0], $goalies_row)),
		};
		delete $goalie->{so_stats}
			unless $goalie->{so_stats} && $goalie->{so_stats} =~ /\d/;
		unless ($goalie->{name} && $goalie->{name} =~ /[a-z]/i) {
			$g++;
			next;
		}
		$goalie->{pt} = delete $goalie->{pot} if $goalie->{pt} !~ /\d/;
		if ($goalie->{pt} =~ /:/) {
			$goalie->{toi} = $goalie->{pt};
			$goalie->{pt} = delete $goalie->{pot};
		}
		push(@{$self->{goalies}}, $goalie);
		$g++;
	}
	$self->{stars} = [];
	my $t = 0;
	for my $s (0..2) {
		my $name = $self->get_sub_tree(0, [$s+1, $g_span+2,0,0], $misc_summary);
		unless ($name && $name =~ /[A-Z]\s*$/i) {
			$t++;
			next;
		}
		$self->{stars}[$s-$t]{team}   = $self->get_sub_tree(0, [$s+1, $g_span  ,0,0], $misc_summary);
		$self->{stars}[$s-$t]{team}   =~ s/.*\d+\s+(\S.*)$/$1/e;
		$self->{stars}[$s-$t]{number} = $self->get_sub_tree(0, [$s+1, $g_span+1,0,0], $misc_summary);
		$self->{stars}[$s-$t]{number} =~ s/\s//g;
		$self->{stars}[$s-$t]{name}   = $name;
	}
	for my $r (0..3) {
		my $type = $self->get_sub_tree(0, [$r+1,$g_span+3,0,0], $misc_summary);
		next unless $type;
		next unless $type =~ /\w/;
		$type = $type =~ /R|A/ ? 'referees' : 'linesmen';
		$self->{officials}{$type} ||= [];
		my $name = $self->get_sub_tree(0, [$r+1,$g_span+4,0,0], $misc_summary);
		push(@{$self->{officials}{$type}}, { name => $name, number => 0}) if $name =~ /\w/;
	}
}

sub parse_goaltender_summary ($$$) {

	my $self               = shift;
	my $goaltender_summary = shift;

	$self->{goalies} = [];
	my $g = 2;
	my $t = 0;
	while (my $goalies_row = $self->get_sub_tree(0, [$g], $goaltender_summary)) {
		last unless $goalies_row && ref $goalies_row;
		my $number = $self->get_sub_tree(0, [0,0], $goalies_row);
		if ($number =~ /^\d+$/) {
			$t = 1 if $t;
			my $goalie = {
				number        => $number,
				team          => $t,
				position      => 'G',
				name_decision => $self->get_sub_tree(0, [2,0], $goalies_row),
				ev            => $self->get_sub_tree(0, [3,0], $goalies_row),
				pp            => $self->get_sub_tree(0, [4,0], $goalies_row),
				sh            => $self->get_sub_tree(0, [5,0], $goalies_row),
				toitot        => $self->get_sub_tree(0, [6,0], $goalies_row),
			};
			my $s = 1;
			while (my $shots_period = $self->get_sub_tree(0, [$s+6,0], $goalies_row)) {
				$goalie->{"SHOT$s"} = $shots_period;
				$self->{last_period} = $s;
				$s++;
			};
			$self->{last_period}--;
			$s--;
			$goalie->{"SHOT"} = delete $goalie->{"SHOT$s"};
			push(@{$self->{goalies}}, $goalie);
		}
		else {
			$t++;
		}
		$g++;
	}
}

sub parse ($) {

	my $self = shift;

	my $events = [];
	$is_special = (grep {$_ == $self->{_id} && $BROKEN_EVENTS{BS}->{$_}->{1}} keys %{$BROKEN_EVENTS{BS}})
		? 1 : 0;
	my $main_table_idx;
	unless ($self->{old}) {
		my $main_table = $self->get_sub_tree(0, [1]);
		$main_table_idx = $main_table->tag eq 'table' ? 1 : 2;
	}
	my $scoring_summary = $self->get_sub_tree(0, [$self->{old} ? (3) : ($main_table_idx,3,0,0)]);
	my $penalty_summary = $self->get_sub_tree(0, [$self->{old} ? (5) : ($main_table_idx,6,0,0)]);
	my $pp_summary      = $self->get_sub_tree(0, [$self->{old} ? (7) : ($main_table_idx,10,0,0)]);
	my $misc_summary    = $self->get_sub_tree(0, [$self->{old} ? (9) : ($main_table_idx,16,0,0)]);
	$misc_summary = $self->get_sub_tree(0, [$main_table_idx,17,0,0]) unless ref $misc_summary;
	$self->{events} = [
		@{$self->parse_scoring_summary($scoring_summary, 1-$self->{old})},
		@{$self->parse_penalty_summary($penalty_summary, 1-$self->{old})},
	];
	$self->{old} ?
		$self->parse_pp_summary($pp_summary) :
		$self->parse_new_pp_summary($pp_summary);
	$self->{old} ?
		$self->parse_misc_summary($misc_summary) :
		$self->parse_new_misc_summary($misc_summary);
	unless ($self->{old}) {
		my $goaltender_summary = $self->get_sub_tree(0, [2,15,0,0]);
		#		exit;
		$goaltender_summary = $self->get_sub_tree(0, [2,14,0,0])
			unless ref $goaltender_summary;
		$goaltender_summary = $self->get_sub_tree(0, [1,15,0,0])
			unless ref $goaltender_summary;
#		print $goaltender_summary->dump;
		if (ref $goaltender_summary) {
			$self->parse_goaltender_summary($goaltender_summary);
		}
		if (! $self->{goalies} || ! @{$self->{goalies}}) {
			$self->{_gs_no_g} = 1;
		}
	}
	for my $event (@{$self->{events}}) {
		$event->{file}    = $self->{file};
		$event->{game_id} = $self->{_id};
		$event->{stage}   = $self->{stage};
		$event->{season}  = $self->{season};
	}
	for my $t (0,1) {
		$self->{teams}[$t]{roster} = [];
	}
}

sub normalize_new ($$) {

	my $self = shift;

	for my $goalie (@{$self->{goalies}}) {
		for my $field (keys %{$goalie}) {
			if ($field eq 'name_decision') {
				if ($goalie->{$field} =~ /^(\S+.*)\,\s+(\S+.*\S+)\s+\((W|L|OT)\)/) {
					$goalie->{name} = "$2 $1";
					$goalie->{wl} = $3;
				}
				else {
					$goalie->{$field} =~ /^(\S+.*)\,\s+(\S+.*\S+)/;
					$goalie->{name} = "$2 $1";
					$goalie->{wl} = '';
				}
			}
			elsif ($field eq 'team') {
				$goalie->{$field} = $self->{teams}[$goalie->{$field}]{name};
			}
			elsif ($goalie->{$field} =~ /(\d+)\:(\d+)/) {
				$goalie->{uc $field} = $goalie->{$field};
				$goalie->{$field} = $1*60 + $2;
			}
			elsif ($goalie->{$field} =~ /(\d+)\-(\d+)/) {
				$goalie->{$field} = [$1, $2];
			}
			if ($goalie->{$field} eq ' ' || ord($goalie->{$field}) == 160) {
				$goalie->{$field} = $field =~ /SHOT/ ? [0,0] : 0;
			}
		}
		delete $goalie->{name_decision};
	}
	my $t = 0;
	if (@{$self->{events}}) {
		my $last_time = $self->{events}[-1]{time};
		$last_time =~ s/(\d+):(\d+)/$1*60+$2/eg;
		for my $team (@{$self->{teams}}) {
			$team->{strength}{ev}{time} ||= $last_time;
			$self->{teams}[$t-1]{strength}{ev}{time} ||= $last_time;
			for my $pptype (qw(5v4 5v3 4v3)) {
				if ($team->{pptype}{$pptype} =~ /(\d+)\-(\d+)\/(\d+)\:(\d+)/) {
					$team->{strength}{$pptype} = $self->{teams}[$t-1]{strength}{reverse $pptype} = {
						goals => $1,
						tries => $2,
						time  => $3*60+$4,
					};
					$team->{strength}{ev}{time} -= $team->{strength}{$pptype}{time};
					$self->{teams}[$t-1]{strength}{ev}{time} -= $team->{strength}{$pptype}{time};
				}
				else {
					$team->{strength}{$pptype} = $self->{teams}[$t-1]{strength}{reverse $pptype} = {
						goals => 0,
						tries => 0,
						time  => 0,
					};
				}
			}
			delete $team->{pptype};
			$t++;
		}
	}
	for my $type (keys %{$self->{officials}}) {
		for my $official (@{$self->{officials}{$type}}) {
			next unless $official;
			$official =~ /\#(\d+)\s+(\S.*\S)/;
			$official = { name => $2, number => $1 };
		}
	}
	for my $star (@{$self->{stars}}) {
		next unless defined $star && ref $star && defined $star->{name};
		$star->{name} =~ /(\d+)\s+\S+.*\.(\S+.*\S+)/;
		$star->{number} = $1;
		$star->{name}   = $2;
	}
	my $e = 1;
	for my $event (@{$self->{events}}) {
		for my $field (keys %{$event}) {
			if ($event->{$field} && $event->{$field} =~ /^(\d+)\s+\D/) {
				$event->{$field} = $1;
			}
		}
		$event->{strength} ||= 'XX';
		$event->{location} ||= 'Unk';
		$event->{file} = $self->{file};
		$event->{id} = $e++;
		if (defined $event->{team1} && $event->{team1} =~ /^\d+$/) {
			$event->{team1} = $self->{teams}[$event->{team1}]{name};
		}
		$event->{assist1} = undef if $event->{assist1} && (lc($event->{assist1}) eq 'unassisted' || $event->{assist1} =~ /unsuccessful/i || $event->{assist1} =~ /penalty shot/i);
		$event->{assist2} = undef unless defined $event->{assist2} && $event->{assist2} =~ /\w/;
		$event->{player1} ||= 0;
		$event->{player1} =~ s/^\s+//g;
		$event->{player1} =~ s/\s+$//g;
		$event->{player1}   = $NAME_TYPOS{$event->{player1}} if $NAME_TYPOS{$event->{player1}};
		$event->{assist1}   = $NAME_TYPOS{$event->{assist1}} if $event->{assist1} && $NAME_TYPOS{$event->{assist1}};
		$event->{assist2}   = $NAME_TYPOS{$event->{assist2}} if $event->{assist2} && $NAME_TYPOS{$event->{assist2}};
	}
	for my $goalie (@{$self->{goalies}}) {
		$goalie->{goals} = $goalie->{SHOT}[0];
		$goalie->{shots} = $goalie->{SHOT}[1];
		$goalie->{saves} = $goalie->{SHOT}[1] - $goalie->{SHOT}[0];
		for my $field (keys %NORMAL_FIELDS) {
			$goalie->{$NORMAL_FIELDS{$field}} = delete $goalie->{$field};
		}
		my $t = $goalie->{team} eq $self->{teams}[0]{name} ? 0 : 1;
		$self->{teams}[$t]{_decision} = $goalie->{decision} if ($goalie->{decision});
		push(@{$self->{teams}[$t]{roster}}, $goalie);
	}
	$self->{_score} = [
		$self->{teams}[0]{score},
		$self->{teams}[1]{score},
	];

	$self->{_t} = 0;
	for my $team (@{$self->{teams}}) {
		$self->force_decision($team) unless $team->{_decision};
		$self->{_t}++;
	}

}

sub normalize_old ($$) {

	my $self     = shift;

	for my $event (@{$self->{events}}) {
		$event->{old} = 1;
		$event->{file} = $self->{file};
		if ($event->{type} eq 'GOAL' || $event->{type} eq 'MISS') {
			$event->{player1} =~ s/^\s*(\S.*\S)\s*\(.*/$1/e;
			if ($event->{assist1} && $event->{assist1} =~ /\w/) {
				$event->{assist1} =~ s/^\s*(\S.*\S)\s*\(.*/$1/e;
				if ($event->{assist2} && $event->{assist2} =~ /\w/) {
					$event->{assist2} =~ s/^\s*(\S.*\S)\s*\(.*/$1/e;
				}
				else {
					delete $event->{assist2};
				}
			}
			else {
				delete $event->{assist1};
			}
			if ($SPECIAL_EVENTS{$self->{_id}} && (!$event->{on_ice}[0][0] ||
					$event->{on_ice}[0][0] =~ /Data/)) {
				$event->{on_ice} = [[($UNKNOWN_PLAYER_ID)x6],[($UNKNOWN_PLAYER_ID)x6]];
			}
			else {
				for my $on_ice (@{$event->{on_ice}}) {
					for my $on_ice_n (@{$on_ice}) {
						$on_ice_n =~ s/^\s+//;
						$on_ice_n =~ s/\s+$//;
						$on_ice = [split(/\s+/, $on_ice_n)];
					}
				}
			}
		}
		elsif ($event->{type} eq 'PENL') {
			$event->{penalty}  =~ s/(\- obstruction)//i;
			$event->{length}   =~ s/^(\d+)\:.*/$1/e;
			$event->{strength} = 'XX';
			$event->{location} = 'UNK';
			if ($event->{player1} && $event->{player1} =~ /\D/) {
				$event->{name}     = $event->{player1};
				$event->{player1}  = $event->{number};
			}
		}
		if (defined $event->{team1} && $event->{team1} =~ /^\d+$/) {
			$event->{team1} = $self->{teams}[$event->{team1}]{name};
		}
		$event->{player1} =~ s/^\s+//g;
		$event->{player1} =~ s/\s+$//g;
		$event->{player1}   = $NAME_TYPOS{$event->{player1}} if $NAME_TYPOS{$event->{player1}};
		$event->{assist1}   = $NAME_TYPOS{$event->{assist1}} if $event->{assist1} && $NAME_TYPOS{$event->{assist1}};
		$event->{assist2}   = $NAME_TYPOS{$event->{assist2}} if $event->{assist2} && $NAME_TYPOS{$event->{assist2}};
		delete $event->{assist1} if $event->{assist1} && ($event->{assist1} =~ /unassisted/i || $event->{assist1} !~ /[a-z]/i);
		delete $event->{assist2} if $event->{assist2} && ($event->{assist2} =~ /unassisted/i || $event->{assist2} !~ /[a-z]/i);
	}
	for my $e (1..@{$self->{events}}) {
		$self->{events}[$e-1]{id} = $e;
		$self->{events}[$e-1]{location} ||= 'Unk';
	}
	my $t0 = '';
	my $t = 0;
	for my $goalie (@{$self->{goalies}}) {
		$goalie->{pt} =~ /(\d+)\-(\d+)/;
		$goalie->{goals} = $1;
		$goalie->{shots} = $2;
		$goalie->{saves} = $2 - $1;
		$goalie->{timeOnIce} = get_seconds(delete $goalie->{toi});
		$goalie->{old}   = 1;
		$goalie->{position} = 'G';
		if ($goalie->{team_decision} =~ /^(\S{3})\(([A-Z])\)/) {
			if (! $t0) {
				$t = 0;
				$t0 = $1;
			}
			elsif ($t0 ne $1) {
				$t = 1;
				$t0 = $1;
			}
			$goalie->{decision} = $2;
			delete $goalie->{team_decision};
		}
		else {
			$goalie->{team_decision} =~ /^(\S{3})/;
			delete $goalie->{team_decision};
			if (! $t0) {
				$t = 0;
				$t0 = $1;
			}
			elsif ($t0 ne $1) {
				$t = 1;
				$t0 = $1;
			}
		}
		$self->{teams}[$t]{_decision} = $goalie->{decision} if ($goalie->{decision});
		if ($goalie->{name} eq 'EMPTY NET') {
			$goalie->{_id} = $EMPTY_NET_ID;
			$goalie->{number} = 0;
		}
		push(@{$self->{teams}[$t]{roster}}, $goalie);
	}
	$self->{_score} = [
		$self->{teams}[0]{score},
		$self->{teams}[1]{score},
	];

	$self->{_t} = 0;
	for my $team (@{$self->{teams}}) {
		$self->force_decision($team) unless $team->{_decision};
		$self->{_t}++;
	}
}

sub normalize ($) {

	my $self = shift;

	my $game_id = $self->{_id};
	$self->{old} ?
		$self->normalize_old($self) :
		$self->normalize_new($self);
	@{$self->{events}} = grep { $_->{type} ne 'PENL' } @{$self->{events}}
		unless $ENV{GS_KEEP_PENL} ||
		$BROKEN_FILES{$game_id}->{BS} && $BROKEN_FILES{$game_id}->{BS} == $NO_EVENTS;
	for my $event (@{$self->{events}}) {
		if (my $evx = $BROKEN_EVENTS{GS}->{$self->{_id}}->{$event->{id}}) {
			for my $key (keys %{$evx}) {
				$event->{$key} = $evx->{$key};
			}
			next;
		}
		if ($event->{type} eq 'PENL') {
			$event->{penalty} =~ s/(\- double minor)//i;
			$event->{penalty} =~ s/(\- obstruction)//i;
			$event->{penalty} =~ s/(PS \- )//i;
		}
		for my $v (qw(strength shot_type penalty miss)) {
			$event->{$v} = vocabulary_lookup($v, $event->{$v}) if exists $event->{$v};
		}
	}
}

1;

=head1 AUTHOR

More Hockey Stats, C<< <contact at morehockeystats.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<contact at morehockeystats.com>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Sport::Analytics::NHL::Report::GS>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Sport::Analytics::NHL::Report::GS

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Sport::Analytics::NHL::Report::GS>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Sport::Analytics::NHL::Report::GS>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Sport::Analytics::NHL::Report::GS>

=item * Search CPAN

L<https://metacpan.org/release/Sport::Analytics::NHL::Report::GS>

=back
