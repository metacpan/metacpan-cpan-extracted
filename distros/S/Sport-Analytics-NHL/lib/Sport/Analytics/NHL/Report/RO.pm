package Sport::Analytics::NHL::Report::RO;

use v5.10.1;
use strict;
use warnings FATAL => 'all';
use experimental qw(smartmatch);

use Sport::Analytics::NHL::Tools qw(:db);
use Sport::Analytics::NHL::Util qw(:utils);

use parent 'Sport::Analytics::NHL::Report';

=head1 NAME

Sport::Analytics::NHL::Report::RO - Class for the NHL HTML RO report.

=head1 SYNOPSYS

Class for the NHL HTML RO report. Should not be constructed directly, but via Sport::Analytics::NHL::Report (q.v.)
As with any other HTML report, there are two types: old (pre-2007) and new (2007 and on). Parsers of them may have something in common but may turn out to be completely different more often than not.

=head1 METHODS

=over 2

=item C<get_coach>

Gets the coach from the roster table of the new RO report.

 Arguments: the roster table section containing the team's coach
 Returns: the coach name

=item C<get_coach_old>

Gets the coach from the roster table of the old RO report.

 Arguments: the roster table section containing the team's coach
 Returns: the coach name

=item C<get_officials>

Gets the officials from the roster table of the new RO report.

 Arguments: the roster table section containing the game officials
 Returns: the officials and possibly their jersey numbers

=item C<get_officials_old>

Gets the officials from the roster table of the old RO report.

 Arguments: the roster table section containing the game officials
 Returns: the officials and possibly their jersey numbers

=item C<get_roster>

Gets the actual roster and scratches from the roster table of the new RO report.

 Arguments:
 * the roster table section containing the players
 * the flag if the game roster or scratches are parsed
 Returns: the list of players and their data:
 * state (captain, a.c.)
 * starting lineup
 * position, number, name...

=item C<get_roster_old>

Gets the actual roster and scratches from the roster table of the old RO report.

 Arguments:
 * the roster table section containing the players
 * the flag if the game roster or scratches are parsed
 Returns: the list of players and their data:
 * state (captain, a.c.)
 * starting lineup
 * position, number, name...

=item C<get_scratch_roster>

A wrapper to call get_roster or get_roster_old (q.v.) with 'scratch' flag on.

=item C<is_ready>

Checks if the roster is ready and reflects the ultimate starting lineup of the teams. Used in pre-game polling for prediction generation. As long as the report exceeds 20 players on the starting lineup it's not ready.

 Arguments: the RO report, parsed
 Returns: 0 or 1.

=item C<parse>

Parse the report: call either old or new read_roster (q.v.)

=item C<read_roster>

Reads the new Roster report into a boxscore structure

 Arguments: none
 Returns: void. Everything is in $self.

=item C<read_roster_old>

Reads the old Roster report into a boxscore structure

 Arguments: none
 Returns: void. Everything is in $self.

=back

=cut

sub get_roster_old ($$$;$) {

	my $self = shift;
	my $row  = shift;
	my $is_scratch = shift || 0;

	my $r = 2;
	my @fields = qw(number position name status);
	pop @fields if $is_scratch;
	my $sf = scalar @fields;
	my $roster = $is_scratch ? 'scratches' : 'roster';
	while (my $tr = $self->get_sub_tree(0, [$r], $row)) {
		last unless ref $tr;
		for my $lr (0, $sf) {
			my $player = { start => 0, status => ' ' };
			my $f = 0;
			for my $field (@fields) {
				my $td = $self->get_sub_tree(0, [$f+$lr,0,0], $tr);
				unless (ref $td) {
					$player->{$field} = $td;
				}
				else {
					if ($field ne 'status') {
						$player->{$field} = $self->get_sub_tree(0, [0,0], $td);
						$player->{start} = 1;
					}
				}
				$f++;
			}
			next unless $player->{name};
			$player->{number} =~ s/\D//g;
			push(
				@{$self->{teams}[$lr/$sf]{$roster}},
				$player,
			);
		}
		$r++;
	}
}

sub get_roster ($$$;$) {

	my $self  = shift;
	my $table = shift;
	my $is_scratch = shift;

	my $r = 1;
	my $roster;
	while (my $tr = $self->get_sub_tree(0, [$r], $table)) {
		last unless $tr && ref $tr;
		$r++;
		my $player = {
			number   => $self->get_sub_tree(0, [0,0], $tr),
			position => $self->get_sub_tree(0, [1,0], $tr),
			name     => $self->get_sub_tree(0, [2,0], $tr),
		};
		unless ($is_scratch) {
			my $class = $tr->{_content}->[2]->attr('class') || '';
			$player->{start} = $class =~ /bold/ ? 1 : 0;
			if ($player->{name} =~ /\((\w)\)/) {
				$player->{status} = $1;
				$player->{name} =~ s/(.*\S).+\(.*/$1/e;
			}
			else {
				$player->{status} = ' ';
			}
		}
		$player->{number} =~ s/\D//g;
		push(@{$roster}, $player);
	}
	$roster;
}

sub get_scratch_roster ($$$$) {

	my $self = shift;
	$self->get_roster(shift, shift, shift, 1);
}

sub get_coach_old ($$$) {

	my $self = shift;
	my $row  = shift;

	for my $t (0,1) {
		my $coach = $self->get_sub_tree(0, [1,$t,0,0], $row);
		$self->{teams}[$t]{coach} = $coach;
	}
}

sub get_coach ($$$) {

	my $self = shift;
	my $table = shift;

	my $coach = $self->get_sub_tree(0, [0,0,0], $table);
	$coach;
}

sub get_officials_old ($$$) {

	my $self = shift;
	my $table = shift;

	my $r = 0;
	while (my $tr = $self->get_sub_tree(0, [$r], $table)) {
		last unless ref $tr;
		my $type = $self->get_sub_tree(0, [0,0,0], $tr);
		if ($type =~ /referee/i) {
			$type = 'referees';
		}
		else {
			$type = 'linesmen';
		}
		my $official = $self->get_sub_tree(0, [1,0,0], $tr);
		push(@{$self->{officials}{$type}}, { number => 0, name => $official });
		$r++;
	}
	for my $type (qw(referees linesmen)) {
		if (@{$self->{officials}{$type}} == 1) {
			push(@{$self->{officials}{$type}}, { number => 0, name => 'Y' });
		}
	}
}

sub get_officials ($$$) {

	my $self = shift;
	my $table = shift;

	my $officials = {referees => [], linesmen => []};

	my $r = 0;
	ROW:
	while (my $tr = $self->get_sub_tree(0, [$r], $table)) {
		last unless $tr && ref $tr;
		$r++;
		my $d; my $d_inc; my $d_ref;
		if (@{$tr->{_content}} == 4) {
			$d = 1; $d_inc = 2;	$d_ref = 1;
		}
		else {
			$d = 0;	$d_inc = 1; $d_ref = 0;
		}
		TD_TABLE:
		while (my $td_table = $self->get_sub_tree(0, [$d,0], $tr)) {
			next ROW unless $td_table && ref $td_table;
			my $type = $d == $d_ref ? 'referees' : 'linesmen';
			$d += $d_inc;
			my $e = 0;
			while (my $official = $self->get_sub_tree(0, [$e,0,0,], $td_table)) {
				next TD_TABLE unless $official;
				$e++;
				$official =~ /\#(\d+).*?(\w.*)/;
				push(
					@{$officials->{$type}}, {
						number => $1,
						name   => $2,
					},
				) unless @{$officials->{$type}} == 2;
			}
		}
	}
	$officials;
}

sub read_roster_old ($$) {

	my $self = shift;

	$self->{teams}[0]{roster} = [];
	$self->{teams}[1]{roster} = [];
	$self->{teams}[0]{scratches} = [];
	$self->{teams}[1]{scratches} = [];
	$self->{officials} = {referees => [], linesmen => []};
	my @r = @{$self->{head}} == 2 ? (3, 0) : (3);
	while ($r[0] <= 9) {
		my $row = $self->get_sub_tree(0, [@r]);
		if ($row->tag eq 'table' || $row->tag eq 'tbody') {
			if ($r[0] == 3) {
				$self->get_roster_old($row, 0);
			}
			elsif ($r[0] == 5) {
				$self->get_roster_old($row, 1);
			}
			elsif ($r[0] == 7) {
				$self->get_coach_old($row);
			}
			else {
				$self->get_officials_old($row);
			}
		}
		$r[0] += 2;
	}
}

sub read_roster ($$) {

	my $self = shift;

	my $roster_table = $self->get_sub_tree(0, [3,0,0], $self->{content_table});
	my $r = 0;
	while (my $row = $self->get_sub_tree(0, [$r], $roster_table)) {
		my $method;
		my $header;
		if ($r) {
		    $header = $self->get_sub_tree(0, [$r-1,0,0], $roster_table);
			if ($header =~ /Head Coaches/) {
				$header = 'coach';
				$method = 'get_coach';
			}
			elsif ($header =~ /Scratches/) {
				$header = 'scratches';
				$method = 'get_scratch_roster';
			}
			elsif ($header =~ /Officials/) {
				last;
			}
		}
		else {
			$header = 'roster';
			$method = 'get_roster';
		}
		my $rowx = $self->get_sub_tree(0, [$r], $roster_table);
		for my $t (0,1) {
			my $table = $self->get_sub_tree(0, [$t,0], $rowx);
			next unless $table;
			my $roster = $self->$method($table);
			$self->{teams}[$t]{$header} = $roster;
		}
		$r += 3;
	}
	my $officials_row   = $self->get_sub_tree(0, [$r], $roster_table);
	my $officials_table = $self->get_sub_tree(0, [0,0], $officials_row);
	$self->{officials}  = $self->get_officials($officials_table);
}

sub parse ($$) {

	my $self = shift;

	$self->{old} ?
		$self->read_roster_old() :
		$self->read_roster();
}

sub is_ready ($) {

	my $self = shift;

	for my $t (0,1) {
		my $rs = @{$self->{teams}[$t]{roster}};
		if ($rs > 20) {
			return 0;
		}
		$self->{teams}[$t]{name} = resolve_team($self->{teams}[$t]{name});
	}
	1;
}

1;

=head1 AUTHOR

More Hockey Stats, C<< <contact at morehockeystats.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<contact at morehockeystats.com>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Sport::Analytics::NHL::Report::RO>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Sport::Analytics::NHL::Report::RO

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Sport::Analytics::NHL::Report::RO>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Sport::Analytics::NHL::Report::RO>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Sport::Analytics::NHL::Report::RO>

=item * Search CPAN

L<https://metacpan.org/release/Sport::Analytics::NHL::Report::RO>

=back
