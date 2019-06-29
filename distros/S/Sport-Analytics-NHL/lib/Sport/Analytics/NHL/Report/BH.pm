package Sport::Analytics::NHL::Report::BH;

use v5.10.1;
use strict;
use warnings FATAL => 'all';
use experimental qw(smartmatch);

use parent 'Sport::Analytics::NHL::Report';

use Carp;

use Sport::Analytics::NHL::Config qw(:basic :ids);
use Sport::Analytics::NHL::Errors;
use Sport::Analytics::NHL::Util;

=head1 NAME

Sport::Analytics::NHL::Report::BH - Class for the old Boxscore HTML report.
NOT IN USE - NOT IN USE.

=head1 SYNOPSYS

Class for the old Boxscore HTML report. At the moment it's not used, thus it's not documented.
Hack at your own risk.

=head1 METHODS

=over 2

=item C<extract_id_from_href>

=item C<extract_name_from_href>

=item C<fill_broken_rosters>

=item C<fill_event_default_values>

=item C<fill_missing_and_broken>

=item C<normalize>

=item C<parse>

=item C<parse_coaches>

=item C<parse_ei_box>

=item C<parse_event_summaries>

=item C<parse_event_summary>

=item C<parse_lineup_row>

=item C<parse_lineup_summaries>

=item C<parse_lineup_summary>

=item C<parse_officials_box>

=item C<read_boxscore_penalty_event>

=item C<read_boxscore_scoring_event>

=item C<read_boxscore_shootout_event>

=item C<read_header>

=back

=cut

use Data::Dumper;

our $LAST_PERIOD = 979;

our $BOXSCORE_HEADER = 1;
our $BOXSCORE_GAME   = 2;

my %NORMAL_FIELDS = (
	S => {
		A => 'assists', BkS => 'blocked', 'PP TOI' => 'powerPlayTimeOnIce', MS => 'misses',
		'SH TOI' => 'shortHandedTimeOnIce',	'EV TOI' => 'evenTimeOnIce',
		Hits => 'hits', G => 'goals', GvA => 'giveaways', TkA => 'takeaways',
		PIM => 'penaltyMinutes', S => 'shots', 'FO%' => 'faceOffPercentage', P => 'points',
		'No.' => 'number', 'Pos' => 'position', Player => '_id',
		Pos => 'position', TOI => 'timeOnIce', '+/-' => 'plusMinus',
	},
	G => {
		PIM => 'pim', Player => '_id', G => 'goals', S => 'saves', TOI => 'timeOnIce',
		'No.' => 'number', 'wl' => 'decision',
	},
);

my %LIVE_FIELDS = (
	S => [qw(shortHandedGoals shortHandedAssists powerPlayGoals powerPlayAssists evenStrengthGoals evenStrengthAssists faceoffTaken faceOffWins)],
	G => [qw(pim goals assists)]
);

sub extract_id_from_href ($) {

	my $elem = shift;

	$elem->attr('href') =~ /id=(\d+)/;
	my $id = $1;
	$BROKEN_PLAYER_IDS{$id} || $id;
}

sub extract_name_from_href ($) {

	my $elem = shift;

	$elem->{_content}[0];
}

sub read_header ($$) {

	my $self     = shift;
	my $main_div = shift;

	$self->{periods}    = [ {}, {}, {} ];
	$self->{teams}      = [];
	$self->{status}     = 'FINAL';
	$self->{type}       = 'BH';
	$self->{source}     =~
		m|title\>([A-Z].*)\s+at\s+([A-Z].*) - (\d{2}/\d{2}/\d{4}).*title|;
	$self->{full_teams} = [ $1, $2 ];
	$self->{date}       = $3;
	$self->{time}       = '';
	$self->{source}     =~ m|gcGameId\D*(\d+)|;
	$self->{_id}        = $1;
	$self->{stage}      = int($self->{_id} / 10000) % 10;
	$self->{season}     = int($self->{_id} / 1000000);
	substr($self->{_id}, 4, 1) = '';
	$self->{season_id}  = sprintf("%04d", $self->{_id} % 10000);
	$self->convert_time_date(1);
	$self->{source}     =~ /game_string:.*\"(\S{3})\s*\@\s*(\S{3})\"/;
	$self->{teams}[0]{name} = $1;
	$self->{teams}[1]{name} = $2;
	my $a_score = $self->get_sub_tree(0, [2,0,2,0,0,0], $main_div);
	$self->{teams}[0]{score} = $a_score;
	my $h_score = $self->get_sub_tree(0, [2,0,2,0,2,0], $main_div);
	$self->{teams}[1]{score} = $h_score;
	$self->{old} = 1;
	$LAST_PERIOD = 3;
}

sub read_boxscore_scoring_event ($$$$) {

	my $self   = shift;
	my $row    = shift;
	my $cell   = shift;
	my $period = shift;

	my $event = {
		type     => 'GOAL',
		strength => 'EV',
		time     => $cell->{_content}[0],
		team1    => $self->get_sub_tree(0, [1,0], $row),
		period   => $period,
		en       => 0,
	};
	my $score = $self->get_sub_tree(0, [2,0], $row);
	return undef unless $score;
	my $offset = 0;
	$event->{empty_net} = 1 if ! ref $score && $score =~ /\bEN\b/;
	
	if (! ref $score) { 
		$event->{player1} = extract_id_from_href(
			$self->get_sub_tree(0, [2,1], $row)
		);
		$offset = 1;
		if ($score =~ /(\w\w)G/) {
			$event->{strength} = $1;
		}
		if ($score =~ /EN/) {
			$event->{en} = 1;
		}
		elsif ($score =~ /PS/) {
			$event->{str} = 'PS';
			$event->{penaltyshot} = 1;
			$event->{location}  = 'OFF';
			$event->{shot_type} = 'UNKNOWN';
			$event->{distance}  = 999;
			return $event;
		}
	}
	else {
		$event->{player1} = extract_id_from_href($score);
	}
	my $asst = $self->get_sub_tree(0, [2,1+$offset], $row);
	my $asst1; my $asst2;
	$event->{assists} = [];
	if ($asst =~ /ASST/) {
		$asst1 = $self->get_sub_tree(0, [2,2+$offset], $row);
		if ($asst1) {
			$event->{assist1} = extract_id_from_href($asst1);
			push(@{$event->{assists}}, $event->{assist1});
			$asst2 = $self->get_sub_tree(0, [2,4+$offset], $row);
			$event->{assist2} = extract_id_from_href($asst2) if $asst2;
			push(@{$event->{assists}}, $event->{assist2}) if $asst2;
		}
	}
	$event->{location}  = 'UNK';
	$event->{shot_type} = 'UNKNOWN';
	$event->{distance}  = 999;
	$event;
}

sub read_boxscore_penalty_event ($$$$) {

	my $self   = shift;
	my $row    = shift;
	my $cell   = shift;
	my $period = shift;

	my $event = {
		type   => 'PENL',
		str    => 'XX',
		time   => $cell->{_content}[0],
		team1  => $self->get_sub_tree(0, [1,0], $row),
		period => $period,
	};
	return () if $event->{time} eq 'NONE';
	my $offender = $self->get_sub_tree(0, [2,0], $row);
	if (ref $offender) {
		$event->{player1} = extract_id_from_href($offender);
		$event->{penalty} = $self->get_sub_tree(0, [2,1], $row);
	}
	else {
		$event->{penalty} = $offender;
		$event->{player1} = $BENCH_PLAYER_ID;
		$event->{length}  = 2;
	}
	my $against = $event->{penalty} =~ /\bagainst\b/ ? 1 : 0;
	if ($event->{penalty} =~ /(.*\S)\s*\(maj\)/) {
		$event->{length}  = 5;
		$event->{penalty} = $1;
	}
	elsif ($event->{penalty} =~ /(.*\S)\s*\(10.*min\)/) {
		$event->{length}  = 10;
		$event->{penalty} = $1;
	}
	elsif ($event->{penalty} =~ /double minor/i) {
		$event->{length} = 4;
	}
	else {
		$event->{length} = 2;
	}
	if ($against) {
		$event->{player2} = extract_id_from_href($self->get_sub_tree(0, [2,2], $row));
		$event->{team2}   = 'OTH';
	}
	$event->{misconduct} = 1  if $event->{penalty} =~ /conduct/i;
	$event->{length}     = 10 if
		$event->{penalty} =~ /misconduct/i ||
		$event->{penalty} =~ /Match/ ||
		$event->{penalty} =~ /abuse.*official/i && $self->{season} > 1997 ||
		$event->{penalty} =~ /leaving .* bench/i;
	$event->{length}     = 0  if $event->{penalty} =~ /penalty shot/i;
	if (
		$event->{penalty} =~ /too many/i ||
		$event->{penalty} =~ /\bbench\b/i && $event->{length} != 10
	) {
		if ($event->{player1} && $event->{player1} =~ /^8\d{6}/) {
			$event->{servedby} = $event->{player1};
		}
		$event->{player1} =  $event->{penalty} =~ /coach/ ? $COACH_PLAYER_ID : $BENCH_PLAYER_ID;
	}
	$event->{penalty} =~ s/\s+against\s+//i;
	if ($event->{penalty} =~ /\bbench\b/i && $event->{penalty} !~ /leaving/i) {
		if (! $event->{servedby} && $event->{player1} && $event->{player1} != $BENCH_PLAYER_ID) {
			$event->{servedby} = $event->{player1};
		}
		$event->{player1} = $BENCH_PLAYER_ID;
		$event->{penalty} =~ s/\s*\-\s+bench//i;
	}
	if ($event->{penalty} =~ /(.*\w)\W*\bcoach\b/i) {
		$event->{player1} = $COACH_PLAYER_ID;
		$event->{penalty} = $1;
	}
	if ($event->{penalty} =~ /aggressor/i) {
		$event->{length} = 10;
	}
	$event->{penalty} =~ s/\s*\-\s+obstruction//i;
	$event->{penalty} =~ s/(game)-(\S)/"$1 - $2"/ie;
	$event->{penalty} =~ s/\s*against\s*//i;
	$event->{location}   = 'UNK';
	$event;
}

sub read_boxscore_shootout_event ($$$$) {

	my $self   = shift;
	my $row    = shift;
	my $cell   = shift;
	my $period = shift;

	my $events;
	for my $t (1,3) {
		my $href = $self->get_sub_tree(0, [$t, 0], $row);
		next unless $href;
		my $event = {
			penaltyshot => 1,
			period      => 5,
			time        => '00:00',
			str         => 'EV',
			shot_type   => 'UNKNOWN',
			location    => 'OFF',
			distance    => 999,
			so          => 1,
		};
		if ($href->attr('class') =~ /shootoutgoal/i) {
			$event->{type} = 'GOAL';
		}
		else {
			$event->{type} = 'MISS';
			$event->{miss} = 'Unknown';
		}
		$event->{player1} = extract_id_from_href($href);
		$event->{team1}   = $self->{teams}[$self->{so_teams}[($t-1)/2]]{name};
		push(@{$events}, $event);
	}
	$events;
}

sub parse_event_summary ($$$$;$) {

	my $self    = shift;
	my $summary = shift;
	my $type    = shift;
	my $events  = shift;

	my $r = 0;
	my $period = 0;
	my $shootout_mode = 0;
	while (my $row = $self->get_sub_tree(0, [$r], $summary)) {
		unless (ref $row) {
			$r++;
			next;
		}
		my $cell = $row->{_content}[0];
		if ($cell->tag eq 'th') {
			unless ($shootout_mode) {
				$period  = $cell->{_content}[0];
				$period += 3 if $cell->{_content}[2] && $cell->{_content}[2] =~ /OT period/i;
				if ($period eq 'OT Period') {
					$period  = 4;
				}
				if ($period eq 'Shootout') {
					$period = 5;
					$shootout_mode = 1;
				}
				$LAST_PERIOD = $period if $period > $LAST_PERIOD;
			}
			else {
				$self->{so_teams} = [ map {
					$self->{full_teams}[0] eq $_ ? 0 : 1,
				} ( $row->{_content}[1]{_content}[0], $row->{_content}[2]{_content}[0]) ];
			}
			$r++;
			next;
		}
		elsif ($cell->tag eq 'td') {
			my $method = "read_boxscore_${type}_event";
			my $event = $self->$method($row, $cell, $period);
			push(@{$events}, ref $event eq 'ARRAY' ? @{$event} : $event) if $event;
		}
		else {
			print "strange cell ", $cell->tag, "\n";
			exit;
		}
		$r++;
	}
}

sub parse_lineup_row ($$$) {

	my $self    = shift;
	my $row     = shift;
	my $headers = shift;

	my $player = {};
	my $c = 0;
	while (my $cell = $self->get_sub_tree(0, [$c], $row)) {
		confess "no ref in lineup cell" unless ref $cell;
		if ($cell->tag eq 'th') {
			push(@{$headers}, $cell->{_content}[0]);
			$c++;
			next;
		}
		my $content;
		if (ref $cell->{_content}[0]) {
			my $c2 = $cell->{_content}[0];
			$content = extract_id_from_href(
				ref $c2->{_content}[0] ? $c2->{_content}[0] : $c2,
			);
			$player->{name} = extract_name_from_href(
				ref $c2->{_content}[0] ? $c2->{_content}[0] : $c2,
			);
			if (ref $c2) {
				$player->{wl} = $cell->{_content}[1];
			}
		}
		else {
			$content = $cell->{_content}[0];
		}
		$player->{$headers->[$c]} = $content;
		$c++;
	}
	$player;
}

sub parse_lineup_summary ($$$) {

	my $self    = shift;
	my $summary = shift;

	my $r = 0;
	my @headers = ();
	my @players = ();
	while (my $row = $self->get_sub_tree(0, [$r], $summary)) {
		my $player = $self->parse_lineup_row($row, \@headers);
		$r++;
		next unless keys %{$player};
		$player->{position} = $player->{Pos} || 'G';
		my $pos = $player->{position} eq 'G' ? 'G' : 'S';
		if ($pos eq 'G') {
			for my $stat (qw(EV SH PP), 'Saves - Shots') {
				$player->{$stat} =~ /^(\d+)\s+\-\s+(\d+)$/;
				if ($stat eq 'EV') {
					$player->{evenSaves} = $1;
					$player->{evenShotsAgainst} = $2;
				}
				elsif ($stat eq 'SH') {
					$player->{powerPlaySaves} = $1;
					$player->{powerPlayShotsAgainst} = $2;
				}
				elsif ($stat eq 'PP') {
					$player->{shortHandedSaves} = $1;
					$player->{shortHandedShotsAgainst} = $2;
				}
				else {
					$player->{saves} = $1;
					$player->{shots} = $2;
				}
			}
		}
		for my $key (keys %{$NORMAL_FIELDS{$pos}}) {
			$player->{$NORMAL_FIELDS{$pos}->{$key}} = delete $player->{$key}
				if exists $player->{$key};
		}
		for my $field (@{$LIVE_FIELDS{$pos}}) {
			$player->{$field} ||= -1;
		}
		$player->{decision} =~ s/\W//g if $player->{decision};
		$player->{evenTimeOnIce} ||= '00:00';
		$player->{status}   ||= 'X';
		$player->{start}      = 2 unless defined $player->{start};
		push(@players, $player);
	}
	@players;
}

sub parse_event_summaries ($$) {

	my $self      = shift;
	my $summaries = shift;

	my $e = $self->get_sub_tree(0, [0,1,0,2,0,0], $summaries) ? 0 : 2;
	my $events = [];

	for my $summary_type (qw(scoring penalty)) {
		my $summary = $self->get_sub_tree(0, [0,1,$e,2,0,0], $summaries);
		$self->parse_event_summary($summary, $summary_type, $events);
		if ($summary_type eq 'scoring') {
			my $shootout = $self->get_sub_tree(0, [0,1,$e,2,1,0], $summaries);
			if ($shootout) {
				$self->{so} = 1;
				$self->{periods}[4] ||= {};
				$self->parse_event_summary($shootout, 'shootout', $events);
			}
		}
		$e++;
	}
	$self->{events} = $events;
}

sub parse_lineup_summaries ($$) {

	my $self      = shift;
	my $summaries = shift;

	my $e = $self->get_sub_tree(0, [0,1,2,2,0,0], $summaries) ? 2 : 0;
	my $x = $self->get_sub_tree(0, [0,1,2,2,0,0], $summaries);
	if ($e == 2 && $x->tag eq 'tbody') {
		$e += 2;
	}
	my $s = 1; my $t = 1;
	for my $team (qw(away home)) {
		for my $roster (qw(skaters goalie)) {
			my $summary = $self->get_sub_tree(0, [0,1,$e,2,2*$s-$t,0], $summaries);
			my @players = $self->parse_lineup_summary($summary);
			$self->{teams}[1-$t]{roster} ||= [];
			push(@{$self->{teams}[1-$t]{roster}}, @players);
			$s++;
		}
		$t--;
	}
}

sub parse_officials_box ($$) {

	my $self   = shift;
	my $ei_box = shift;

	my $officials_box = $self->get_sub_tree(0, [2,0], $ei_box);

	my $referees = $self->get_sub_tree(0, [1,0], $officials_box);
	my $officials = {};
	if ($referees && !ref $referees) {
		if ($referees =~ /:\s+(\S+.*\S+)\s*\,\s+(\S+.*\S+)\s*$/) {
			$officials->{referees} = [
				{ name => $1, number => 0 }, { name => $2, number => 0 },
			];
		}
		else {
			$referees =~ /:\s+(\S+.*\S+)/;
			$officials->{referees} = [
				{ name => $1, number => 0 }
			];
		}
		my $linesmen = $self->get_sub_tree(0, [2,0], $officials_box);
		return {} unless $linesmen;
		if ($linesmen =~ /:\s+(\S+.*\S+)\s*\,\s+(\S+.*\S+)\s*$/) {
			$officials->{linesmen} = [
				{ name => $1, number => 0 }, { name => $2, number => 0 },
			];
		}
		else {
			$linesmen =~ /:\s+(\S+.*\S+)/;
			$officials->{linesmen} = [
				{ name => $1, number => 0 },
			];
		}
	}
	else {
		$officials = {};
	}
	$self->{officials} = $officials;
}

sub parse_coaches ($$) {

	my $self   = shift;
	my $ei_box = shift;

	my $coach_box = $self->get_sub_tree(0, [2,1], $ei_box);
	return unless $coach_box;

	for my $c (0,1) {
		my $coach = $self->get_sub_tree(0, [$c+1,0], $coach_box);
		$coach =~ s/^(.*)\:.*/$1/e;
		$self->{teams}[$c]{coach} = $coach;
	}
}

sub parse_ei_box ($$$) {

	my $self   = shift;
	my $ei_box = shift;

	my $box_id = $ei_box->attr('id') || '';
	for ($box_id) {
		when ('gameReports') {
			$self->parse_officials_box($ei_box);
			$self->parse_coaches($ei_box);
		}
		when ('threeStars') {
			$self->{stars} = [];
			for my $s (0..2) {
				my $star = $self->get_sub_tree(0, [2,$s,0,0], $ei_box);
				push(@{$self->{stars}}, extract_id_from_href($star)) if $star;
			}
		}
	}
}

sub fill_broken_rosters ($$) {

	my $self           = shift;
	my $broken_rosters = shift;

	my $r = 0;
	for my $broken_roster (@{$broken_rosters}) {
		for my $broken_player (@{$broken_roster}) {
			for my $player (@{$self->{teams}[$r]{roster}}) {
				if ($player->{number} == $broken_player->{'No.'}) {
					for my $field (keys %{$broken_player}) {
						next if $field eq 'No.';
						unless (exists $player->{$field}) {
							if ($field eq 'number' || $field eq 'error') {
								$player->{number} = $broken_player->{$field};
							}
							else {
								die "Invalid field $field specified";
							}
						}
						$player->{$field} = $broken_player->{$field};
					}
				}
			}
		}
		$r++;
	}
}

sub fill_missing_and_broken ($) {

	my $self = shift;

	if ($MISSING_EVENTS{$self->{_id}}) {
		for my $event (@{$MISSING_EVENTS{$self->{_id}}}) {
			push(@{$self->{events}}, $event)
				unless $event->{type} eq 'PEND' || $event->{type} eq 'GEND';
		}
	}
	if ($MISSING_COACHES{$self->{_id}}) {
		$self->{teams}[0]{coach} = $MISSING_COACHES{$self->{_id}}->[0];
		$self->{teams}[1]{coach} = $MISSING_COACHES{$self->{_id}}->[1];
	}
	$self->fill_broken_rosters($self, $BROKEN_ROSTERS{$self->{_id}})
		if $BROKEN_ROSTERS{$self->{_id}};
}

sub parse ($) {

	my $self = shift;

	my $flag = 1;

	for my $i (0..60) {
		my $main_div = $self->get_sub_tree(0, [$i]);
		next unless ref $main_div;
#		print "I $i\n";
		if ($main_div->attr('class') && $main_div->attr('class') eq 'chrome') {
			if ($flag == $BOXSCORE_HEADER) {
				$self->read_header($main_div);
				$flag++;
			}
			elsif ($flag == $BOXSCORE_GAME) {
				$self->parse_event_summaries($main_div);
				$self->parse_lineup_summaries($main_div);
				my $extra_info_box = $self->get_sub_tree(0, [0,2], $main_div);
				my $x = 0;
				while (my $ei_box = $self->get_sub_tree(0, [$x], $extra_info_box)) {
					$self->parse_ei_box($ei_box);
					$x++;
				}
				$flag++;
			}
			else {
				print "Got strange box\n";
				print $main_div->dump;
				exit;
			}
		}
	}
	$self->fill_missing_and_broken();
}

sub fill_event_default_values ($$) {
	
	my $self  = shift;
	my $event = shift;

	$event->{file}     = $self->{file};
	$event->{stage}    = $self->{stage};
	$event->{season}   = $self->{season};
	$event->{strength} = delete $event->{str} if (!$event->{strength} && $event->{str});
	$event->{strength} = 'EV' if $event->{strength} eq 'PS' && $event->{time} eq '0:00';
	if ($event->{type} eq 'PENL') {
		$event->{penalty} =~ s/^\s+//;
		$event->{penalty} =~ s/\s+$//;
		$event->{penalty} =~ s/\xC2\xA0//g;
		$event->{penalty} = uc($event->{penalty});
	}
	if ($BROKEN_EVENTS{BH}->{$self->{_id}}
		&& (my $evx = $BROKEN_EVENTS{BH}->{$self->{_id}}{$event->{id}})) {
		if ($evx->{broken}) {
			$event->{broken} = 1;
		}
		else {
			for my $error (keys %{$evx}) {
				defined $evx->{$error}
					? $event->{$error} = $evx->{$error}
					: delete $event->{$error};
			}
		}
	}
	$event->{time} = $1 if $event->{time} =~ /^0(\d.*)/;
	$event->{on_ice} = [[],[]];
}

sub normalize ($) {

	my $self = shift;

	$self->{location}   ||= 'Unknown Location';
	$self->{attendance} ||= 0;
	for my $p (3..$LAST_PERIOD-1) {
		$self->{periods}[$p] ||= {};
	}
	for my $e (1..@{$self->{events}}) {
		my $event = $self->{events}[$e-1];
		$event->{id}       = $e;
		$self->fill_event_default_values($event);
	}
}

1;
