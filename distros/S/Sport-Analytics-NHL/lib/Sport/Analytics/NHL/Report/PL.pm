package Sport::Analytics::NHL::Report::PL;

use v5.10.1;
use strict;
no strict 'refs';
use warnings FATAL => 'all';
use experimental qw(smartmatch);

use parent 'Sport::Analytics::NHL::Report';
use warnings FATAL => 'all';
use experimental qw(smartmatch);

use Storable qw(dclone);

use Sport::Analytics::NHL::Config qw(:basic :ids);
use Sport::Analytics::NHL::Errors;
use Sport::Analytics::NHL::Tools qw(:parser :db);
use Sport::Analytics::NHL::Util qw(:utils);

use Data::Dumper;

=head1 NAME

Sport::Analytics::NHL::Report::PL - Class for the Boxscore HTML PBP report

=head1 SYNOPSYS

Class for the Boxscore HTML PBP report.Should not be constructed directly, but via Sport::Analytics::NHL::Report (q.v.)
As with any other HTML report, there are two types: old (pre-2007) and new (2007 and on). Parsers of them may have something in common but may turn out to be completely different more often than not.

This module is the heaviest one of the reports due to vast amounts of data and poor structure of the document. Handle with care.

=head1 METHODS

=over 2

=item C<add_game_end>

Adds a missing GEND event to a game.

 Arguments: none
 Returns: void. The object is manipulated from within.

=item C<cleanup_old_event>

Removes extra white spaces from old event's properties

 Arguments: the event
 Returns: void. The event is altered.

=item C<configure_old_events>

Adds on-ice information to certain broken-format old goal events.

 Arguments: none
 Returns: void. The events arrayref in the
  object is manipulated from within.

=item C<fill_broken_events>

Finds the events in the boxscore that were explicitly marked as broken and corrects them with the manual data.

 Arguments: none
 Returns: void. The events arrayref in the
  object is manipulated from within.

=item C<fill_event_values>

Fills the event with derived values from the boxscore object (e.g. season, stage)

 Arguments: the event
 Returns: void. The event is altered.

=item C<fix_old_event_type>

Applies additional processing to the event from an old report.
 Arguments: the event
 Returns: void. The event is altered.


=item C<fix_old_line>

Makes the best attempt to fix the broken lines in the old reports, including known typos.

 Arguments: the line
 Returns: void. The event is altered.

=item C<normalize>

Cleans, standardizes and provides default values to events after the parsing.

 Arguments: none
 Returns: void. The events arrayref in the
  object is manipulated from within.

=item C<parse>

Wrapper dispatching the actual parsing either to read_playbyplay (q.v.) or read_playbyplay_old (q.v.) depending on the type of the report.

 Arguments: none
 Returns: void.

=item C<parse_description>

Parses the description of the event of the new report for specific information.

 Arguments: the event
 Returns: void. The event is altered.

=item C<parse_description_old>

Parses the description of the event of the old report for specific information.

 Arguments: the event
 Returns: void. The event is altered.

=item C<parse_on_ice>

Parses the on-ice information of the event of the new report.

 Arguments: the event
 Returns: void. The event is altered.

=item C<parse_penalty>

Parses the penalty event of the new report which requires its own function due to complexity of the matching regexp.

 Arguments: the event
 Returns: void. The event is altered.

=item C<parse_penalty_old>

Parses the penalty event of the old report which requires its own function due to complexity of the matching regexp.

 Arguments: the event
 Returns: void. The event is altered.

=item C<read_event>

Reads the event from the event table row of the new report.

 Arguments: the row HTML element
 Returns: the read event.

=item C<read_old_block>

Reads the consecutive block of event lines of the old report.

 Arguments:
 * the block of HTML elements containing the lines.
 * the number of the block
 * the adjustment flag (due to poor structure)
 Returns: the array of lines with the events

=item C<read_old_line>

Reads a line of the old report and parses it into the event.

 Argument: the line of text.
 Returns: the event.

=item C<read_old_on_ice>

Reads the on-ice information of the old report event (goals only)

 Arguments: the line with the information
 Returns: void. The event is updated within the object.

=item C<read_playbyplay>

Actually parses the new report

 Arguments: none
 Returns: void. It's all in $self.

=item C<read_playbyplay_old>

Actually parses the old report

 Arguments: none
 Returns: void. It's all in $self.

=item C<skip_event>

Flags if the event is out of place and should be skipped.

 Argument: the event
 Returns: 1 if the event should be skipped, 0 if not.

=back

=cut

use parent qw(Sport::Analytics::NHL::Report Exporter);

our @EXPORT = qw(
	@KNOWN_EVENT_TYPES @IGNORED_EVENT_TYPES
	$VALID_SHOTS $VALID_MISSES $VALID_ZONES
);
our @event_fields        = qw(id period strength time type description on_ice1 on_ice2);
our %OLD_EVENT_TYPES = (
        'GIVEAWAY'     => 'GIVE',
        'MISSED SHOT'  => 'MISS',
        'PENALTY'      => 'PENL',
        'STOPPAGE'     => 'STOP',
        'HIT'          => 'HIT',
        'FACE-OFF'     => 'FAC',
        'GOAL'         => 'GOAL',
        'BLOCKED SHOT' => 'BLOCK',
        'TAKEAWAY'     => 'TAKE',
        'SHOT'         => 'SHOT',
        'Penalty Shot' => 'SHOT',
        'GOALIE'       => 'GPUL',
);
our @KNOWN_EVENT_TYPES   = qw(GOAL SHOT MISS BLOCK HIT FAC GIVE TAKE PENL STOP PSTR GEND PEND CHL);
our @IGNORED_EVENT_TYPES = qw(PGSTR PGEND ANTHEM GOFF SOC EIEND EISTR EGT EGPID);

our $ID_INDEX          = 0;
our $PERIOD_INDEX      = 1;
our $STR_INDEX         = 2;
our $TIME_INDEX        = 3;
our $TYPE_INDEX        = 4;
our $DESCRIPTION_INDEX = 5;
our $ON_ICE1_INDEX     = 6;
our $ON_ICE2_INDEX     = 7;

our @EVENT_INDICES = (
	$ID_INDEX, $TYPE_INDEX, $PERIOD_INDEX, $STR_INDEX, $TIME_INDEX,
	$DESCRIPTION_INDEX, $ON_ICE1_INDEX, $ON_ICE2_INDEX,
);

our $VALID_MISSES = q(Wide|Over|Crossbar|Goalpost);
our $VALID_SHOTS  = q(Wrist|Slap|Snap|Tip-In|Wrap-around|Deflected|Backhand);
our $VALID_ZONES  = q(Off|Neu|Def);

sub parse_penalty_old ($$) {

	my $self  = shift;
	my $event = shift;

	$event->{location} = 'Unk';
	$event->{team1}    = $event->{team};
	$event->{novictim} = 1;
	if ($event->{description} =~ /^(\d+).*\,\s*(\S.*\S)\s*\,\s*(\d+)/) {
		$event->{player1} = $1;
		$event->{penalty} = $2;
		$event->{length}  = $3;
		$event->{player2} = $UNKNOWN_PLAYER_ID;
		$event->{team2}   = 'OTH';
		delete $event->{novictim};
	}
	elsif ($event->{description} =~ /^Team Penalty\,\s*(\S.*\S)\s*\,\s*(\d+) min\, Served By\s+(\d+)/) {
		$event->{player1}  = $event->{description} =~ /\bcoach\b/ ? $COACH_PLAYER_ID : $BENCH_PLAYER_ID;
		$event->{penalty}  = $1;
		$event->{length}   = $2;
		$event->{servedby} = $3;
	}
	elsif ($event->{description} =~ /^Abuse of officials - bench\,\s*(\d+) min\, Served By\s+(\d+)/) {
		$event->{player1}  = $BENCH_PLAYER_ID;
		$event->{penalty}  = 'Abuse of officials';
		$event->{length}   = $1;
		$event->{servedby} = $2;
	}
	elsif ($event->{description} =~ /^Team Penalty\,\s*(\S.*\S)\s*\,\s*(\d+) min/) {
		$event->{player1}  = $BENCH_PLAYER_ID;
		$event->{penalty}  = $1;
		$event->{length}   = $2;
		$event->{servedby} = $UNKNOWN_PLAYER_ID;
	}
	if (! $event->{servedby} && $event->{description} =~ /Served By\s+(\d+)/) {
		$event->{servedby} = $1;
	}
	$event->{misconduct} = 1 if $event->{description} =~ /(misconduct|unsportsmanlike)/i;
}

sub parse_penalty ($$) {

	my $self  = shift;
	my $event = shift;

	my $desc;
	my $use_servedby = 0;
	($event->{team1}, $desc) = ($event->{description} =~ /^\s*(\S\S\S)\s+(\S.*)/);
	if (! $event->{team1}) {
		die "Strange no team in penalty " . Dumper($event)
			unless $event->{description} =~ /team/i;
		$event->{team1} = 'UNK';
		$desc = $event->{description};
	}
	else {
		if ($desc =~ /^\#(\s+)/) {
			$desc =~ s/^\#(\s+)/\#00 UNKNOWN /;
			$use_servedby = 1;
		}
		$desc =~ s/^(\#\d+)(\D.*?)\s+(?:PS\-)?([A-Z][a-z])/"$1 $3"/e;
	}
	($event->{player1}, $desc) = ($desc =~ /^\#?(\d+|TEAM|\s)\s*(\S.*)/i);
	($event->{penalty}, $event->{length}, $desc) = ($desc =~ /^([A-Z][a-z].*\S)\((\d+) min\)(.*)/);
	die "Bad description $event->{id}/$event->{description}" unless defined $desc;
	if ($desc =~ /Drawn.By: (\S\S\S) #(\d+)/i) {
		$event->{team2} = $1; $event->{player2} = $2;
	}
	else {
		$event->{novictim} = 1;
	}
	$event->{servedby}   = $1  if $desc =~ /Served.By: #(\d+)/;
        $event->{player1}    = delete $event->{servedby} if $use_servedby;
	$event->{location}   = $1  if $desc =~ /(\w\w\w). Zone/;
	$event->{misconduct} = 1 if $event->{description} =~ /(misconduct|unsportsmanlike)/i;
	$event->{player1} ||= '';
	if (! $event->{player1} && $event->{servedby}) {
		$event->{player1} = delete $event->{servedby};
	}
	elsif ($event->{player1} =~ /team/i) {
		$event->{player1} = $BENCH_PLAYER_ID;
	}
	elsif ($event->{player1} eq ' ') {
		$event->{player1} = $event->{description} =~ /(Team Staff|\bcoach\b)/i ?
			$COACH_PLAYER_ID : $BENCH_PLAYER_ID;
	}
	$event->{location} ||= 'Unk';
	delete $event->{servedby} if $event->{servedby} && $event->{servedby} =~ /^80/;
	$event;
}

sub parse_description_old ($$) {

	my $self  = shift;
	my $event = shift;

	$event->{location} = ucfirst(substr($1, 0, 3)) if
		$event->{description} =~ /(offensive|neutral|defensive) zone/;
	$event->{distance} = $1 if $event->{description} =~ /(\d+)\s+ft/;
	if ($event->{description} =~ /^\-?(\d+)/) {
		$event->{team1}   = $event->{team};
		$event->{player1} = $1;
	}
	$event->{strength} = 'EV' if $event->{strength} eq 'SO';
	for ($event->{type}) {
		when ([qw(GIVE TAKE)]) {
			$event->{location} ||= 'Unk';
		}
		when ('FAC') {
			$event->{description} =~ /(\S\S\S) won/;
			$event->{winning_team} = $event->{team}= $1;
			$event->{description} =~ /(\S\S\S)\s+(\d+)\s+\S.*\S\s+vs\s+(\S\S\S)\s+(\d+)\s+\S+/;
			if ($event->{winning_team} eq $1) {
				$event->{team1} = $1;
				$event->{team2} = $3;
				$event->{player1} = $2;
				$event->{player2} = $4;
			}
			elsif ($event->{winning_team} eq $3) {
				$event->{team1} = $3;
				$event->{team2} = $1;
				$event->{player1} = $4;
				$event->{player2} = $2;
			}
			else {
				die "$event->{winning_team} / $event->{team1} / $event->{team2} FACEOFF MISMATCH";
			}
		}
		when ('BLOCK') {
			$event->{location}  = 'Def';
			$event->{player2}   = $event->{player1};
			$event->{player1}   = $UNKNOWN_PLAYER_ID;
			$event->{team2}     = $event->{team1};
			$event->{team1}     = 'OTH';
			$event->{shot_type} = 'Unknown';
		}
		when('HIT') {
			$event->{location}  = 'Unk';
			$event->{player2}   = $UNKNOWN_PLAYER_ID;
			$event->{team2}     = 'OTH';
		}
		when ('MISS') {
			if ($event->{description} =~ /($VALID_MISSES|Penalty)/) {
				if ($1 eq 'Penalty') {
					$event->{penaltyshot} = 1;
					$event->{miss} = 'Unknown';
				}
				else {
					$event->{miss} = $1;
				}
			}
			else {
				$event->{miss} = 'Unknown';
			}
			$event->{location}  = 'Off';
			$event->{shot_type} = 'Unknown';
			$event->{distance}  = 999;
		}
		when ('SHOT') {
			$event->{description} =~ s/Wrap\,/Wrap-around\,/;
			$event->{description} =~ /($VALID_SHOTS|Unsuccessful Penalty Shot)/;
			$event->{shot_type} = $1;
			if ($event->{shot_type} eq 'Unsuccessful Penalty Shot') {
				$event->{distance} ||= 999;
				$event->{shot_type} = 'Unknown';
			}
			$event->{location} = 'Off';
		}
		when ('GOAL') {
			$event->{description} =~ s/Wrap\,/Wrap-around\,/;
			$event->{description} =~ s/Tip-in/Tip-In/;
			$event->{description} =~ /($VALID_SHOTS)/;
			$event->{shot_type} = $1;
			$event->{location} =
				$event->{distance} > 120 ? 'Def' : $event->{distance} > 72 ? 'Neu' : 'Off';
			if ($event->{description} =~ /A\:\s+(\d+)\s+(\S+)\,\s+(\d+)\s+(\S+)/) {
				$event->{assist1} = $1;
				$event->{assist2} =	$3;
			}
			elsif ($event->{description} =~ /A\:\s+(\d+)\s+(\S+)/) {
				$event->{assist1} = $1;
			}
		}
		when ('STOP') {
			$event->{stopreason} = $event->{description};
		}
	}
}

sub parse_description ($$) {

	my $self = shift;
	my $event = shift;

	$event->{description} =~ tr/ / /;
	my $evx = $BROKEN_EVENTS{PL}->{$self->{_id}};
	if (defined $evx->{$event->{id}} && $evx->{$event->{id}}{description}) {
		$event->{old_description} = $event->{description};
		$event->{description} = $evx->{$event->{id}}{description};
	}

	return $self->parse_penalty($event) if $event->{type} eq 'PENL';

	my @items = split(/\,/, $event->{description});
	for my $item (@items) {
		$item =~ s/^\s+//;
		$item =~ s/\s+$//;
	}
	if ($event->{type} eq 'CHL') {
		$event->{description} =~ /^(\S+)\s*Challenge\W*(\S.*)\s.*\-\s.*Result: (.*)/;
		$event->{team1} = $1 || 'League';
		$event->{challenge} = $2;
		$event->{result} = $3;
	}
	if ($event->{type} ne 'FAC') {
		if ($items[-1] =~ /^(\d+) ft./) {
			$event->{distance} = $1;
			pop @items;
		}
		if ($items[-1] =~ /^($VALID_ZONES)\. Zone/) {
			$event->{location} = $1;
			pop @items;
		}
		if ($items[-1] =~ /$VALID_MISSES/) {
			$event->{miss} = $items[-1];
			pop @items;
		}
		if ($items[-1] =~ /^$VALID_SHOTS$/) {
			$event->{shot_type} = $items[-1];
			pop @items;
		}
		$items[0] =~ s/ (ONGOAL|TAKEAWAY|GIVEAWAY) \-//g;
		$items[0] =~ s/ (\d+) /" #$1 "/ge;
	}
	else {
		$event->{location} = $1 if $event->{description} =~ /($VALID_ZONES)\. Zone/;
	}
	my $t = 1;
	while ($items[0] =~ /(\S\S\S) \#(\d+)/gc) {
		$event->{"team$t"} = $1;
		$event->{"player$t"} = $2;
		$t++;
	}
	$event->{penaltyshot} = 1         if $event->{description} =~ /Penalty Shot/;
	$event->{shot_type} ||= 'Unknown' if $event->{type} =~ /^(GOAL|MISS|SHOT|BLOCK)$/;
	$event->{miss}      ||= 'Unknown' if $event->{type} eq 'MISS';
	$event->{location}    = $event->{type} =~ /(GOAL|SHOT|MISS|BLOCK)/ ? 'Off' : 'Def'
		if ! $event->{location};
	for ($event->{type}) {
		when ('GOAL') {
			if ($event->{description} =~ /Assists: #(\d+) .* #(\d+)/) {
				$event->{assist1} = $1;
				$event->{assist2} = $2;
			}
			elsif ($event->{description} =~ /Assist: #(\d+)/) {
				$event->{assist1} = $1;
			}
		}
		when ([qw(PEND GEND PSTR)]) {
			$event->{description} =~ /time: (\d+:\d+)/;
			$event->{timestamp} = $1;
		}
		when ('STOP') {
			$event->{description} =~ /^\s*(\S.*\S)\s*$/;
			$event->{stopreason} = $1;
		}
		when ('FAC') {
			$event->{description} =~ /(\S\S\S) won/;
			return undef unless $1;
			$event->{winning_team} = $1;
			if ($event->{winning_team} ne $event->{team1}) {
				my $x = $event->{player2};
				$event->{player2} = $event->{player1};
				$event->{player1} = $x;
				$x = $event->{team2};
				$event->{team2} = $event->{team1};
				$event->{team1} = $x;
			}
		}
		when ('BLOCK') {
			my $x = $event->{player2};
			$event->{player2} = $event->{player1};
			$event->{player1} = $x;
			$x = $event->{team2};
			$event->{team2} = $event->{team1};
			$event->{team1} = $x;
		}
	}
}

sub parse_on_ice ($$) {

	my $self = shift;
	my $event = shift;

	for my $team (1,2) {
		my $on_ice = delete $event->{"on_ice$team"};
		if (ref $on_ice eq 'ARRAY') {
			$event->{on_ice} ||= [];
			$event->{on_ice}[$team-1] = $on_ice;
		}
		else {
			my $on_ice_table = $self->get_sub_tree(0, [0], $on_ice);
			return unless ref $on_ice_table->{_content};
			my $num = scalar @{$on_ice_table->{_content}};
			$event->{on_ice} ||= [];
			$event->{on_ice}[$team-1] = [];
			$event->{_description} = $event->{description};
			for (my $i = 0; $i < $num; $i+=2) {
				my $on_ice_font = $self->get_sub_tree(0, [$i,0,0,0,0], $on_ice_table);
				my $name = $on_ice_font->attr('title') || '';
				$event->{_description} .= " $name";
				my $on_ice_cell = $self->get_sub_tree(0, [$i,0,0,0,0,0], $on_ice_table);
				next unless defined $on_ice_cell;
				$on_ice_cell =
					$self->get_sub_tree(0, [$i,0,0,1,0,0], $on_ice_table) if $on_ice_cell !~ /^\d+$/;
				push(@{$event->{on_ice}[$team-1]}, $on_ice_cell);
			}
		}
	}
}

sub read_old_block ($$$) {

	my $self   = shift;
	my $row    = shift;
	my $r      = shift;
	my $adjust = shift;

	my $block = ref $row->{_content}[$r] ?
		$row->{_content}[$r]{_content}[0] :
		$row->{_content}[$adjust ? 0 : $r];

	my $split_char = $block =~ /\r/ ? "\r\n" : "\n";
	my @lines = split(/$split_char/, $block);

	@lines;
}

sub read_old_on_ice ($$) {

	my $self = shift;
	my $line = shift;

	$self->{events}[-1]{description} .= $line;
	$line =~ /^\s+(\S{3}):\s+(\S.*)/;
	my $team = resolve_team($1, 1);
	$self->{events}[-1]{on_ice} ||= [];
	my $on_ice_text = $2;
	my @on_ice = split(/\,/, $on_ice_text);
	my $index;
	if ($team eq $self->{teams}[0]{name}) {
		$index = 0;
	}
	elsif ($team eq $self->{teams}[1]{name}) {
		$index = 1;
	}
	else {
		die "Couldn't map team $team";
	}
	$self->{events}[-1]{on_ice}[$index] = [ map { s/\D+//g; $_ } @on_ice ];
	$self->{goal_mode}--;
	$self->{goal_mode}-- if $BROKEN_EVENTS{PL}->{$self->{_id}}->{$self->{events}[-1]{id}}{on_ice2};
}

sub fix_old_line ($$) {

	my $self = shift;
	my $line = shift;

	my $id = $self->{events}[-1] ? $self->{events}[-1]{id}+1 : 1;
	$line =~ s/^\s+//;
	$line = sprintf("%5s   %s", $id, $line);
	$line =~ s/\t/  /g;
	$line =~ s/ ATL/ATL /;
	$line =~ s/PENALTY\s+(\S{3})\s/"PENALTY           $1"/e;

	$line;
}

sub read_old_line ($$) {

	my $self = shift;
	my $line = shift;

	if ($line =~ /Shootout/) {
		$self->{so} = 1;
		return;
	}
	return undef if
		$line !~ /\w/ || $line =~ /^\<\!\-\-/ || $line =~ /^\s*(\-+|\#)/ ||
		! $self->{goal_mode} && $line !~ /^\s*(\d+|SO\s|F\s)/;
	$line =~ s/\r//g;
	my $was_missed = 0;
	if ($self->{goal_mode}) {
		$self->read_old_on_ice($line);
		return;
	}
	if ($line =~ /^\s+\d+\s+\d+:\d+/) {
		$line = $self->fix_old_line($line);
		$was_missed = 1;
	}
	my $event = {};
	$event->{id} = $self->{so} ? $self->{events}[-1]{id}+3 : substr($line, 0, 5);
	$event->{id} =~ s/\s//g;
	$event->{id}         += $self->{missed_events};
	return undef if
		defined $BROKEN_EVENTS{PL}->{$self->{_id}}->{$event->{id}} &&
		(! $BROKEN_EVENTS{PL}->{$self->{_id}}->{$event->{id}} ||
		 $BROKEN_EVENTS{PL}->{$self->{_id}}->{$event->{id}}{special});
	if ($self->{so}) {
		$line =~ s/^\s+(\S+)/" "x(9-length($1)).$1/e
	}
	$event->{period}      = $self->{so} ? 5                   : substr($line, 5, 5);
	$event->{period}      =~ s/\s//g;
	return undef if $event->{period} > 5 && $self->{stage} == $REGULAR;
	$event->{type}        = substr($line, 16, 16);
	$event->{team}        = substr($line, 34, 3);
	return if $event->{type} =~ /GOALIE/i;
	$event->{description} = substr($line, 43);
	$event->{so}          = $self->{so} ? 1 : 0;
	$self->{shootout}     = 1 if $event->{period} =~ /\d/ && $event->{period} == 5 && $self->{stage} == $REGULAR;
	$event->{time}        = $self->{so} ? '0:00'              : substr($line, 9, 7);
	$event->{strength}    = $self->{so} ? 'SO'                : substr($line, 37, 6);
	$event->{old} = 1;
	$self->{missed_events} += $was_missed;
	$event;
}

sub cleanup_old_event ($$) {

	my $self  = shift;
	my $event = shift;

	for (keys %{$event}) {
		$event->{$_} =~ s/^\s+//g;
		$event->{$_} =~ s/\s+$//g;
	}
	if ($event->{type} =~ /(.*)\s+\(\s*\S+\s*\)/) {
		$event->{type} = $1;
	}
}

sub fix_old_event_type ($$) {

	my $self = shift;
	my $event = shift;

	if ($event->{type} eq 'Penalty Shot') {
		$event->{strength} ||= 'EV';
		$event->{penaltyshot} = 1;
	}
	$event->{type} = $OLD_EVENT_TYPES{$event->{type}};
	if ($event->{type} eq 'GOAL') {
		$self->{goal_mode} = $self->{shootout} ? 0 : 2;
	}

}

sub configure_old_events ($) {

	my $self = shift;

	my $e = 0;
	while ($self->{events}[$e]{type} ne 'FAC') {
		$e++;
	}
	for my $event (@{$self->{events}}) {
		next if $event->{special};
		if ($event->{type} eq 'GOAL') {
			if ($BROKEN_EVENTS{PL}->{$self->{_id}}->{$event->{id}}{on_ice}) {
				$event->{on_ice} = $BROKEN_EVENTS{PL}->{$self->{_id}}->{$event->{id}}{on_ice};
			}
			elsif ($BROKEN_EVENTS{PL}->{$self->{_id}}->{$event->{id}}{on_ice1}) {
				$event->{on_ice}[0] = $BROKEN_EVENTS{PL}->{$self->{_id}}->{$event->{id}}{on_ice1};
			}
			elsif ($BROKEN_EVENTS{PL}->{$self->{_id}}->{$event->{id}}{on_ice}) {
				$event->{on_ice}[1] = $BROKEN_EVENTS{PL}->{$self->{_id}}->{$event->{id}}{on_ice2};
			}
		}
	}
}

sub read_playbyplay_old ($) {

	my $self = shift;

	my $row = $self->get_sub_tree(0, [(@{$self->{head}} == 2 ? (3, 0) : (3)), 0, 0, 0]);
	my $r = 0;
	$self->{teams}[0]{name} = resolve_team($self->{teams}[0]{name}, 1);
	$self->{teams}[1]{name} = resolve_team($self->{teams}[1]{name}, 1);
	$self->{events} = [];
	$self->{missed_events} = 0;
	my $event_cache = {};
	while ($row->{_content}[$r]) {
		my $adjust = 0;
		if ($r == 1 && ! @{$self->{events}}) {
			$row = $row->{_content}[$r];
			$adjust = 1;
		}
		my @lines = $self->read_old_block($row, $r, $adjust);
		for my $line (@lines) {
			my $event = $self->read_old_line($line, $self);
			next unless $event;
			next if $event_cache->{$event->{id}};
			$event_cache->{$event->{id}} = 1;
			$self->cleanup_old_event($event);
			my $evx = $BROKEN_EVENTS{PL}->{$self->{_id}}->{$event->{id}};
			if ($evx && $evx->{special}) {
				push(@{$self->{events}}, $evx);
				next;
			}
			die "Unknown old event type: " . Dumper($event) . $line . "\n"
				unless $OLD_EVENT_TYPES{$event->{type}};
			$self->fix_old_event_type($event, $self);
			$event->{description} = $evx->{description} if
				defined $evx->{description};
			$event->{type} eq 'PENL' ?
				$self->parse_penalty_old($event) : $self->parse_description_old($event);
			if ($event->{strength} eq '-') {
				$event->{strength} = @{$self->{events}} ? $self->{events}[-1]{strength} : 'EV';
			}
			fill_broken($event, $evx);
			$self->fill_event_values($event);
			next if $event->{period} > 11;
			push(@{$self->{events}}, $event);
		}
		$r++;
		$row = $row->{_parent} if @{$self->{events}} && $self->{events}[-1]{special} || $adjust;
	}
	$self->configure_old_events() unless ($self->{events}[-1]{special});
	if ($BROKEN_EVENTS{PL}->{$self->{_id}}->{-1}) {
		push(@{$self->{events}}, @{$BROKEN_EVENTS{PL}->{$self->{_id}}->{-1}});
	}
}

sub read_event ($$) {

	my $self     = shift;
	my $play_row = shift;

	my $event = {};

	for my $pp (@EVENT_INDICES) {
		my $event_cell = $self->get_sub_tree(0, [$pp,0], $play_row);
		for ($pp) {
			when ($ID_INDEX) {
				return undef if $event_cell eq '#' || $event_cell && ref $event_cell;
				return undef if defined $BROKEN_EVENTS{PL}->{$self->{_id}}{$event_cell} &&
					            !       $BROKEN_EVENTS{PL}->{$self->{_id}}{$event_cell};
			}
			when ($TYPE_INDEX) {
				die "Bad event row: " . $event_cell if ! $event_cell;
				return undef if grep { $event_cell eq $_ } @IGNORED_EVENT_TYPES;
				die "UNKNOWN event $event_cell / $event->{id} " . Dumper($event) . $play_row->dump
					if ! grep { $event_cell eq $_ } @KNOWN_EVENT_TYPES;
			}
		}
		$event->{$event_fields[$pp]} = $event_cell;
		if ($pp == $DESCRIPTION_INDEX && $event->{type} eq 'GOAL') {
			my $extra_description = $self->get_sub_tree(0, [$pp,2], $play_row);
			$event->{description} .= ' ' . $extra_description if $extra_description;
			if ($event->{id} == 1) {
				# games stopped and resumed
				$self->parse_description($event);
				$event->{on_ice} = [[],[]];
				$event->{time} = '0:00';
				$event->{strength} = 'EV';
				$event->{period} = 1;
				$event->{special} = 1;
				return $event;
			}
		}
	}
	$event->{time} = '5:00' if $event->{type} eq 'PEND' && $event->{time} !~ /^\d+/;
	$event;
}

sub add_game_end ($) {

	my $self = shift;

	my $e = 1;
	do {
		if ($self->{events}[-$e]{type} eq 'PEND') {
			my $gend_event = dclone $self->{events}[-$e];
			$gend_event->{type} = 'GEND';
			push(@{$self->{events}}, $gend_event);
			return;
		}
		$e++;
	} while ($self->{events}[-$e]{type} ne 'PSTR');
	if ($self->{events}[-$e]{period} == 5 && $self->{stage} == $REGULAR) {
		my $pend_event = dclone $self->{events}[-$e];
		$pend_event->{type} = 'PEND'; $pend_event->{id} = $self->{events}[-1]{id}+1;
		my $gend_event = dclone $self->{events}[-$e];
		$gend_event->{type} = 'GEND'; $gend_event->{id} = $self->{events}[-1]{id}+2;
		push(@{$self->{events}}, $pend_event, $gend_event);
	}
}

sub fill_broken_events ($) {

	my $self = shift;

	my $evx = $BROKEN_EVENTS{PL}->{$self->{_id}};
	return unless defined $evx;
	if ($evx->{-1}) {
		unshift(@{$self->{events}}, @{$evx->{-1}});
	}
	for my $event (@{$self->{events}}) {
		next unless $evx->{$event->{id}};
		next if $event->{special};
		if ($evx->{$event->{id}}{on_ice}) {
			$event->{on_ice} = $evx->{$event->{id}}{on_ice};
		}
		elsif ($evx->{$event->{id}}{on_ice1}) {
			$event->{on_ice}[0] = $evx->{$event->{id}}{on_ice1};
		}
		elsif ($evx->{$event->{id}}{on_ice}) {
			$event->{on_ice}[1] = $evx->{$event->{id}}{on_ice2};
		}
	}
}

sub skip_event ($$) {

	my $self = shift;
	my $event = shift;

	return 1 if $BROKEN_EVENTS{$self->{_id}} && defined $BROKEN_EVENTS{$self->{_id}}->{$event->{id}} && $BROKEN_EVENTS{$self->{_id}}->{$event->{id}} == 0;
	return 1 if $event && $event->{period} > 11;
	return 1 if
		($event->{type} eq 'PEND' || $event->{type} eq 'PSTR') &&
			@{$self->{events}} && $self->{events}[-1]{type} eq $event->{type};
	0;
}

sub fill_event_values ($$) {

	my $self  = shift;
	my $event = shift;
	$event->{file}    = $self->{file};
	$event->{season}  = $self->{season};
	$event->{game_id} = $self->{_id};
	$event->{stage}   = $self->{stage};
	if ($event->{period} == 5 && $self->{stage} == $REGULAR) {
		$event->{so}          = 1;
		$event->{penaltyshot} = 1;
	}
}

sub read_playbyplay ($) {

	my $self = shift;

	$self->{events} = [];
	my $gend = 0;
	do {
		my $p = 3;
		my $main_table = $self->get_sub_tree(0, [@{$self->{head}}]);
		$gend = 1 unless $main_table;
		while (my $play_row = $self->get_sub_tree(0, [++$p], $main_table)) {
			next unless ref $play_row && scalar @{$play_row->{_content}} >= @event_fields;
			my $event = $self->read_event($play_row, $self->{_id});
			next if ! $event || $self->skip_event($event);
			$self->parse_description($event);
			next if $event->{type} eq 'CHL' && $event->{team1} eq 'html';
			$self->parse_on_ice($event) unless $event->{type} eq 'GEND';
			my $evx = $BROKEN_EVENTS{PL}->{$self->{_id}}
				? $BROKEN_EVENTS{PL}->{$self->{_id}}{$event->{id}}
				: undef;
			fill_broken($event, $evx);
			delete $event->{on_ice1} if $event->{on_ice1} && ref $event->{on_ice1} && ref $event->{on_ice1} ne 'ARRAY';
			delete $event->{on_ice2} if $event->{on_ice2} && ref $event->{on_ice2} && ref $event->{on_ice2} ne 'ARRAY';
			$self->fill_event_values($event);
			push(@{$self->{events}}, $event);
			last if $self->{events}[-1]{type} eq 'GEND';
		}
		$self->{head}[-1]++;
	} until ($self->{events}[-1]{type} eq 'GEND' || $gend);
	$self->fill_broken_events();
}

sub normalize ($$) {

	my $self = shift;

	for my $event (@{$self->{events}}) {
		$event->{file} = $self->{file};
		if ($event->{penalty}) {
			if ($event->{penalty} =~ /\bbench\b/i && $event->{penalty} !~ /leav/i) {
				$event->{player1} = $BENCH_PLAYER_ID;
				$event->{penalty} =~ s/\s*\-\s+bench//i;
			}
			elsif ($event->{penalty} =~ /(.*\w)\W*\bcoach\b/i) {
				$event->{player1} = $COACH_PLAYER_ID;
				$event->{penalty} = $1;
			}
			$event->{penalty} = uc ($event->{penalty});
			if ($event->{penalty} =~ /(.*)\s+\(MAJ\)/i) {
				$event->{penalty} = $1;
				$event->{severity} = 'major';
			}
			elsif ($event->{penalty} =~ /(.*)\s+\(10 MIN\)/i) {
				$event->{penalty} = $1;
				$event->{severity} = 'misconduct';
			}
			$event->{penalty} =~ s/(game)-(\S)/"$1 - $2"/ie;
		}
		for my $v (qw(penalty miss shot_type stopreason strength)) {
			next unless exists $event->{$v};
			if ($v eq 'stopreason') {
				$event->{$v} = [ split(/\,/, $event->{$v}) ];
				for my $ev (@{$event->{$v}}) {
					$ev = vocabulary_lookup($v, $ev);
				}
			}
			elsif ($v eq 'penalty') {
				$event->{$v} = normalize_penalty($event->{$v});
			}
			else {
				$event->{$v} = vocabulary_lookup($v, $event->{$v});
			}
		}
		if ($event->{assist1}) {
			$event->{assists} = [ $event->{assist1} ];
			push(@{$event->{assists}}, $event->{assist2}) if ($event->{assist2});
		}
		if ($event->{period} == 5 && $self->{stage} == $REGULAR) {
			$event->{so} = 1;
			$self->{so}  = 1;
		}
	}
}

sub parse ($) {

	my $self = shift;

	$self->{old}
		? $self->read_playbyplay_old()
		: $self->read_playbyplay();
}

1;

=head1 AUTHOR

More Hockey Stats, C<< <contact at morehockeystats.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<contact at morehockeystats.com>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Sport::Analytics::NHL::Report::PL>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Sport::Analytics::NHL::Report::PL

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Sport::Analytics::NHL::Report::PL>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Sport::Analytics::NHL::Report::PL>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Sport::Analytics::NHL::Report::PL>

=item * Search CPAN

L<https://metacpan.org/release/Sport::Analytics::NHL::Report::PL>

=back
