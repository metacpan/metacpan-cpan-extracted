package Sport::Analytics::NHL::Report::ES;

use v5.10.1;
use strict;
use warnings FATAL => 'all';
use experimental qw(smartmatch);

use parent 'Sport::Analytics::NHL::Report';

use Sport::Analytics::NHL::Config qw(:basic :ids);
use Sport::Analytics::NHL::Errors;
use Sport::Analytics::NHL::Util qw(:utils);

use Storable qw(dclone);
use Data::Dumper;

=head1 NAME

Sport::Analytics::NHL::Report::ES - Class for the NHL HTML ES report.

=head1 SYNOPSYS

Class for the NHL HTML ES report. Should not be constructed directly, but via Sport::Analytics::NHL::Report (q.v.)
As with any other HTML report, there are two types: old (pre-2007) and new (2007 and on). Parsers of them may have something in common but may turn out to be completely different more often than not.

=head1 METHODS

=over 2

=item C<get_new_headers>

Get the headers of the player tables in the new HTML.

 Arguments: HTML element with the team table
 Returns: the array of headers.

=item C<get_old_headers>

Get the headers of the player tables in the old HTML.

 Arguments: HTML element with the team table
 Returns: the array of headers.

=item C<normalize>

Cleaning up and standardizing the parsed data.

 Arguments: none
 Returns: void. Everything is in the $self.

=item C<parse>

Parse the ES html tree into a boxscore object

 Arguments: none
 Returns: void. Everything is in the $self.

=item C<parse_new_team_summary>

Parse a team's table in the new HTML.

 Arguments: HTML element with the team table
 Returns: the team hashref.

=item C<parse_old_team_summary>

Parse a team's table in the old HTML.

 Arguments: HTML element with the team table
 Returns: the team hashref.

=item C<parse_goaltender_summary>

Parse the seldom-happening goaltending summary in the ES report.

 Arguments: the HTML element with the summary
 Returns: void, the object is updated.

=back

=cut

my %NORMAL_FIELDS = (
	S => {
		G => 'goals', 'A' => 'assists', P => 'points', FW => 'faceOffWins',
		PN => 'penalties', FL => 'faceOffLosses', 'F%' => 'faceOffPct',
		TOI => 'timeOnIce', AVG => 'averageTimeShift', S => 'shots', MS => 'misses',
		'+/-' => 'plusMinus', 'A/B' => 'attemptsBlocked', HT => 'hits',
		GV => 'giveaways', TK => 'takeaways', BS => 'blocked', SHF => 'shifts',
		TOIPP => 'powerPlayTimeOnIce', TOISH => 'shortHandedTimeOnIce', TOITOT => 'timeOnIce',
		PP => 'powerPlayTimeOnIce', SH => 'shortHandedTimeOnIce', EV => 'evenTimeOnIce',
		TOIEV => 'evenTimeOnIce', POS => 'position', 'No.' => 'number', TOI => 'timeOnIce',
		PIM => 'penaltyMinutes', TOISHF => 'shifts', TOIAVG => 'averageIceTime', SHOTT => 'shots',
	},
);
my %LIVE_FIELDS = (
	S => [qw(shortHandedGoals shortHandedAssists powerPlayGoals powerPlayAssists evenStrengthGoals evenStrengthAssists)],
	G => [qw(pim goals assists)]
);
my %FRENCH = (
	'TOIDN/SH' => 'TOISH',
	'TOI' => '14:19',
	'TOIFÃ/EV' => 'TOIEV',
	'TOIMOY' => 'TOIAVG',
	'LB' => 'BS',
	'MG' => 'FW',
	'TOIAN/PP' => 'TOIPP',
	'LANC.' => 'S',
	'PP' => 'TK',
	'B' => 'G',
	'LR' => 'MS',
	'M%' => 'F%',
	'PUN' => 'PN',
	'MP' => 'FL',
	'MO' => 'FL',
	'TOIPR' => 'TOISHF',
	'R' => 'GV',
	'MIN' => 'PIM',
	'TENT/BL' => 'A/B',
	'MÃ' => 'HT'
);

sub get_old_headers ($$;$) {

	my $self         = shift;
	my $team_summary = shift;

	my $header_row = $self->get_sub_tree(0, [ 0 ], $team_summary);
	my $headers_num = scalar @{$header_row->{_content}};
	my @headers;

	for my $h (0..$headers_num-1) {
		for ($h) {
			when (0) {
				$headers[$h] = 'No.';
			}
			when (1) {
				$headers[$h] = 'POS';
			}
			when (2) {
				$headers[$h] = 'name';
			}
			default {
				$headers[$h] =
					$self->get_sub_tree(0, [$h,0,1], $header_row)   ||
					$self->get_sub_tree(0, [$h,0,0,1], $header_row) ||
					'';
				if (ref $headers[$h]) {
					$headers[$h] =
						$self->get_sub_tree(0, [$h,0,2], $header_row) ||
						$self->get_sub_tree(0, [$h,0,0,2], $header_row);
				}
			}
		}
	}
	my $shots_row = $self->get_sub_tree(0, [1], $team_summary);
	my $h = 0;
	my $shot_offset;
	for my $header (@headers) {
		unless ($header) {
			$shot_offset = $h;
			last;
		}
		$h++;
	}
	for my $h (2..$#{$shots_row->{_content}}) {
		my $subshot = $self->get_sub_tree(0, [$h,0,0,0], $shots_row);
		last unless $subshot;
		splice(@headers, $shot_offset-1+$h, 0, "SHOT" . $subshot);
	}
	splice(@headers, $shot_offset, 1);
	@headers = grep { /\S/ } @headers;
	@headers;
}

sub get_new_headers ($$) {

	my $self         = shift;
	my $team_summary = shift;

	my $header_row = $self->get_sub_tree(0, [ 0,0,0 ], $team_summary);
	my $headers_num = scalar @{$header_row->{_content}};
	my @headers;

	for my $h (0..$headers_num-1) {
		for ($h) {
			when (0) {
				$headers[$h] = 'name';
			}
			default {
				$headers[$h] =
					$self->get_sub_tree(0, [$h,0,], $header_row)   ||
					'';
			}
		}
	}
	unshift(@headers, qw(No. POS));
	my $shots_row = $self->get_sub_tree(0, [0,0,1], $team_summary);

	for my $h (0..$#{$shots_row->{_content}}) {
		my $subcol = $self->get_sub_tree(0, [$h,0], $shots_row);
		splice(@headers, 10+$h, 0, "TOI$subcol") if $subcol;
	}
	splice(@headers, 9, 1);
	@headers = grep { /\S/ } @headers;
	for my $header (@headers) {
		$header = $FRENCH{$header} if $FRENCH{$header};
		$header = 'TOIEV' if $header =~ /TOIF.*EV/;
		$header = 'HT' if $header =~ /^M./ && $header ne 'MS' && $header ne 'M%' && $header ne 'MO' && $header ne 'MG';
	}
	@headers;
}

sub parse_old_team_summary ($$) {

	my $self         = shift;
	my $team_summary = shift;

	my $roster = [];

	my @headers = $self->get_old_headers($team_summary);
	my $g = 2;
	while (my $player_row = $self->get_sub_tree(0, [$g], $team_summary)) {
		my $player = {};
		for my $h (0..$#headers) {
			$player->{$headers[$h]} = $self->get_sub_tree(0, [$h,0,0], $player_row);
		}
		push(@{$roster}, $player) if
			$player->{name} && $player->{name} !~ /TOTALS/ && $player->{name} !~ /team penalty/i;
		$g++;
	}
	$roster;
}

sub parse_new_team_summary ($$) {

	my $self         = shift;
	my $team_summary = shift;

	my @headers = $self->get_new_headers($team_summary);
	my @rosters;
	my $g = 2;
	my $roster = [];
	while (my $player_row = $self->get_sub_tree(0, [0,0,$g], $team_summary)) {
		my $player = {};
		for my $h (0..$#headers) {
			$player->{$headers[$h]} = $self->get_sub_tree(0, [$h,0], $player_row);
		}
		push(@{$roster}, $player) if
			$player->{'No.'} && $player->{'No.'} =~ /\S/ && $player->{'No.'} !~ /\D/;
		if ($player->{'No.'} && $player->{'No.'} =~ /TOTALS/) {
			push(@rosters, $roster);
			$roster = [];
		}
		$g++;
	}
	@rosters;
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

sub parse ($$) {

	my $self = shift;

	my $body_size = scalar @{$self->{html}{_content}};
	if ($self->{old}) {
		my $away_summary = $self->get_sub_tree(0, [3,(0)x$#{$self->{head}}]);
		$self->{teams}[0]{roster} = $self->parse_old_team_summary($away_summary);
		my $home_summary = $self->get_sub_tree(0, [5,(0)x$#{$self->{head}}]);
		$self->{teams}[1]{roster} = $self->parse_old_team_summary($home_summary);
	}
	else {
		my $gs_probe = $self->get_sub_tree(0, [$body_size/2,3,0,0]);
		if ($gs_probe eq 'GOALTENDER SUMMARY') {
			my $goaltender_summary = $self->get_sub_tree(0, [$body_size/2,4,0,0]);
			$self->parse_goaltender_summary($goaltender_summary);
		}
		my $summary = $self->get_sub_tree(0, [$body_size/2,7]);
		my @rosters = $self->parse_new_team_summary($summary);
		$self->{teams}[0]{roster} = dclone $rosters[0];
		$self->{teams}[1]{roster} = dclone $rosters[1];
	}
}

sub normalize ($$) {

	my $self       = shift;

	for my $team (@{$self->{teams}}) {
		for my $player (@{$team->{roster}}) {
			$player->{'No.'} =~ s/\D//g;
			if ($player->{POS} eq 'G') {
				delete @{$player}{qw(BS +/- SHF FW FL F% A/B)};
			}
			for my $field (keys %{$player}) {
				$player->{$field} ||= $field eq 'TOIAVG' ? '0:00' : 0;
				$player->{$field} =~ s/^\s+//;
				$player->{$field} =~ s/\s+$//;
				$player->{$field} =~ s/\;/:/g;
				if ($player->{$field} =~ /:/) {
					$player->{$field} =~ s/^(\d+):(\d+)$/$1*60+$2/e;
				}
				elsif ($field ne 'name' && $field ne 'POS') {
					$player->{$field} = 0 if $player->{$field} !~ /\d/;
					$player->{$field} += 0;
				}
				$player->{$field} += 0 if $player->{$field} =~ /^\-?\d+$/;
			}
			$player->{name} = "$2 $1" if $player->{name} =~ /^(\S.*\S)\,\s+(\S.*)$/;
			$player->{start} = 2;
			$player->{shots} ||= 0;
			$player->{status} = 'X';
			for my $field (qw(G A PIM)) {
				$player->{$field} ||= 0E0;
			}
			for my $field (keys %{$NORMAL_FIELDS{S}}) {
				$player->{$NORMAL_FIELDS{S}->{$field}} = delete $player->{$field}
					if exists $player->{$field};
			}
			my $pos = $player->{position} eq 'G' ? 'G' : 'S';
			for my $field (@{$LIVE_FIELDS{$pos}}) {
				$player->{$field} ||= 0E0;
			}
			if ($player->{position} ne 'G') {
				$player->{faceoffTaken} = $player->{faceOffWins} + $player->{faceOffLosses};
				$player->{timeOnIce} = $player->{evenTimeOnIce} + $player->{powerPlayTimeOnIce} + $player->{shortHandedTimeOnIce} if defined $player->{evenTimeOnIce};
			}
		}
	}
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
}

1;

=head1 AUTHOR

More Hockey Stats, C<< <contact at morehockeystats.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<contact at morehockeystats.com>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Sport::Analytics::NHL::Report::ES>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Sport::Analytics::NHL::Report::ES

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Sport::Analytics::NHL::Report::ES>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Sport::Analytics::NHL::Report::ES>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Sport::Analytics::NHL::Report::ES>

=item * Search CPAN

L<https://metacpan.org/release/Sport::Analytics::NHL::Report::ES>

=back
