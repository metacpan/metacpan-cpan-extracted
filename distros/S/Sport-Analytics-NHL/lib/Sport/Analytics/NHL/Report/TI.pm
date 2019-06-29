package Sport::Analytics::NHL::Report::TI;

use v5.10.1;
use strict;
use warnings FATAL => 'all';
use experimental qw(smartmatch);

use Sport::Analytics::NHL::Tools qw(resolve_team);
use Sport::Analytics::NHL::Util qw(:debug :times);

use parent 'Sport::Analytics::NHL::Report';

sub parse ($) {

	my $self = shift;
	my $shift_table = $self->get_sub_tree(0, [@{$self->{head}}, 3.0,0,0]);

	my $i = 0;
	$self->{shifts} = [];
	my $current_shift = {};
	my $current_player = {};
	my $team = resolve_team($self->{teams}[ref($self) =~ /TI/ ? 0 : 1]{name});
	while (my $row = $self->get_sub_tree(0, [$i], $shift_table)) {
		my $cell = $self->get_sub_tree(0, [0], $row);
		#		print Dumper $cell->attr('class');
		if ($cell && $cell->attr('class')) {
			if ($cell->attr('class') =~ /^playerHeading/) {
				my $player = $cell->{_content}[0];
				$player =~ /(\d+)\s+(\S.*)\,(.*\S)/;
				unless (defined $1) {
					$i++;
					next;
				}
				$current_player = {
					number => $1,
					last_name => $2,
					first_name => $1,
					name => "$1 $2",
				};
			}
			elsif ($cell->attr('class') =~ /^lborder/) {
				unless (defined $current_player->{number}) {
					$i++;
					next;
				}
				$current_shift->{player} = $current_player->{number};
				$current_shift->{team}   = $team;
				$cell = $self->get_sub_tree(0, [1], $row);
				$current_shift->{period} = $cell->{_content}[0];
				if ($current_shift->{period} eq 'OT') {
					$current_shift->{period} = 4;
				}
				if ($current_shift->{period} eq 'SO') {
					$current_shift->{period} = 5;
				}
				elsif ($current_shift->{period} =~ /OT(\d)/) {
					$current_shift->{period} = 3+$1;
				}
				$current_shift->{period} +=0;
				$cell = $self->get_sub_tree(0, [2], $row);
				my $start = $cell->{_content}[0];
				$start =~ /^(\d+:\d+)\D/;
				$current_shift->{start} =
					get_seconds($1) + ($current_shift->{period}-1)*1200;
				$cell = $self->get_sub_tree(0, [3], $row);
				my $finish = $cell->{_content}[0];
				$finish =~ /^(\d+:\d+)\D/;
				$current_shift->{finish} =
					get_seconds($1) + ($current_shift->{period}-1)*1200;
				$current_shift->{length} =
					$current_shift->{finish} - $current_shift->{start};
				push(@{$self->{shifts}}, $current_shift);
				$current_shift = {};
			}
		}
		$i++;
	}
	for my $t (0,1) {
		$self->{teams}[$t]{name} = resolve_team($self->{teams}[$t]{name});
	}
}

1;

=head1 NAME

Sport::Analytics::NHL::TI - Class for the NHL HTML Team shift report

=head1 SYNOPSIS

Class for the NHL HTML Team shift report. Should not be constructed directly, but via Sport::Analytics::NHL::Report (q.v.)

Contrary to other reports there is no "older version" of this one.

=head1 METHODS

=over 2

=item C<parse>

Only one method, parse is required and thus implemented. The shift tables are relatively simple.

 Arguments: none, the report is within the object.

 Returns: void, $self->{shifts} is populated.

=back

=head1 AUTHOR

More Hockey Stats, C<< <contact at morehockeystats.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<contact at morehockeystats.com>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Sport::Analytics::NHL::TI>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Sport::Analytics::NHL::TI

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Sport::Analytics::NHL::TI>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Sport::Analytics::NHL::TI>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Sport::Analytics::NHL::TI>

=item * Search CPAN

L<https://metacpan.org/release/Sport::Analytics::NHL::TI>

=back

=cut
