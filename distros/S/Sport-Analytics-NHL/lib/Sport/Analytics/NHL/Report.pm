package Sport::Analytics::NHL::Report;

use v5.10.1;
use strict;
use warnings FATAL => 'all';
use experimental qw(smartmatch);

use Storable;

use Date::Calc qw(Decode_Date_US Decode_Date_EU);
use HTML::TreeBuilder;
use List::MoreUtils qw(firstval);
use Module::Pluggable require => 1, search_path => ['Sport::Analytics::NHL::Report'];
use Time::Local;

use Sport::Analytics::NHL::Util qw(:debug :file :times :utils);
use Sport::Analytics::NHL::Tools qw(:db);
use Sport::Analytics::NHL::Config qw(:basic :ids :seasons);
use Sport::Analytics::NHL::Errors;

=head1 NAME

Sport::Analytics::NHL::Report - Generic class for an NHL report

=head1 SYNOPSYS

Generic class for an NHL report

Contains methods common for most (usually HTML) or all NHL reports.

    use Sport::Analytics::NHL::Report;
 	my $report = Sport::Analytics::NHL::Report->new($args);
	$report->process();

=head1 METHODS

=over 2

=item C<new>

Common constructor wrapper. Assigns the report plugin, and initializes the report object. For a json report usually an overloaded constructor is required. For an HTML report, the generic html_new (q.v.) method is usually sufficient.
Arguments: the arguments hashref
 * file: the file with the report OR
 * data: the scalar with the report
   BUT NOT BOTH
 * type: explicitly specify the type of the report
Returns: the blessed object of one of the Report's Plugins.

The object represents an NHL game.

=item C<html_new>

Specific constructor for the HTML reports. Parses the HTML using HTML::TreeBuilder, immediately storing the tree as another storable (.tree) for re-use. The tree resides in $obj->{html}. The raw HTML is stored in $obj->{source}. The type of the report is set in $obj->{type}.
Arguments: see new() (q.v.)
Returns: the blessed object.

=item C<convert_time_date>

Converts the NHL HTML header date strings of start and end of the game into $obj->{start_ts} and $obj->{end_ts} timestamps and sets the object's time zone in $obj->{tz} and the month in $obj->{month}.
Arguments: whether to force US date parsing or not.
Note: uses $self->{date} anf $self->{time} from get_header() (q.v.)
Returns: void. Sets object fields

=item C<force_decision>

Forces a decision setting on a goaltender in case the reports miss on it explicitly. Usually happens in tied games.
Arguments: the team to force the decision
Returns: void. Sets a team's goaltender with the decision.

=item C<get_header>

Gets the HTML node path for the HTML report header (teams, score, location, attendance etc.)
Arguments: none
Returns: void. Sets the path in $obj->{head}

=item C<get_sub_tree>

Gets the node in the HTML Tree as set by a path.
Arguments:
 * flag 0|1 whether the node or its contents are wanted
 * the walk path to the node as arrayref
 * optional: the sub tree to walk (or $obj->{html})

=item C<normalize>

A post-process function for the report that should be overloaded.

=item C<parse>

A processing function for the specific report that must be overloaded.

=item C<process>

Read the boxscore: read the header, parse the rest (overloaded), normalize it (may be overloaded), delete the html tree to free the memory and delete the HTML source for the same purpose.
Arguments: none
Returns: void

=item C<read_arena_info>

Reads the arena information from the game header
Arguments: the HTML element with the arena information
Returns: void. Sets the arena and the attendance in the object.

=item C<read_date_info>

Reads the date from the game header
Arguments: the HTML element with the date information
Returns: void. Sets the date in the object. Implies calling convert_date_time (q.v.) later.

=item C<read_game_info>

Reads the NHL id from the game header
Arguments: the HTML element with the game id information
Returns: void. Sets the nhl season game id in the object.

=item C<read_header>

Parses the header of the HTML report, dispatching the processing of the discovered information elements.
Arguments: none
Returns: void. Everything is set in the object.

=item C<has_html>

Checks if one of the sources of the boxscore is an HTML report
Arguments: none
Returns: True|False

=item C<read_status>

Reads the game status block from the game header
Arguments: the HTML element with the game status and other information
Returns: void. Sets the information in the object.

=item C<read_status_info>

Reads the actual status of the game from the header
Arguments: the HTML element with the status information
Returns: void. Sets the status in the object.

=item C<read_team>

Reads the team information from the game header
Arguments: the HTML element with the team information and the index of the team
Returns: void. Sets the team information in the object.

=item C<read_time_info>

Reads the time from the game header
Arguments: the HTML element with the time information
Returns: void. Sets the date in the object. Implies calling convert_date_time (q.v.) later.

=item C<set_args>

Sets the argument for the constructor. Juggles the data, file and type fields.
Arguments: the args hashref:
 * the file to process OR
 * the scalar with the data to process, BUT NOT BOTH.
 * the explicit data type setting,
   optional when 'file' is specified.
Returns: void. Updates the args hashref.

=item C<set_event_extra_data>

Sets extra data to already parsed events:

 * The file type as event source
 * The game_id normalized
 * Bench player in case of bench penalty
 * Resolves teams to standard 3-letter codes
 * Converts time to timestamp (ts)
 * Sets field t for primary event team:
   0 for away, 1 for home, -1 - noplay event

Arguments: none
Returns: void. Updates the events in the object.

=back

=cut

use Data::Dumper;

our %REPORT_TYPES = (
	BS => 'json',
	PB => 'json',
	Player => 'json',
	PL => 'html',
	RO => 'html',
	GS => 'html',
	BH => 'html',
	ES => 'html',
	TV => 'html',
	TH => 'html',
);

our @HEADER_STATUS_METHODS = (
	undef,
	undef,
	undef,
	undef,
	qw(
		read_date_info
		read_arena_info
		read_time_info
		read_game_info
		read_status_info
	),
);
our @HEADER_STATUS_METHODS_OLD = (
	undef,
	undef,
	undef,
	undef,
	'read_game_info',
	undef,
	'read_date_info',
	undef,
	'read_arena_info',
	undef,
	'read_time_info',
	undef,
	'read_status_info',
);

our $tb;

sub set_args ($) {

	my $args = shift;

	if (! $args->{data} && ! $args->{file}) {
		print STDERR "Need to specify either file or data, choose one!\n";
		return undef;
	}
	if ($args->{data} && $args->{file}) {
		print STDERR "Cannot specify both data and file, choose one!\n";
		return undef;
	}
	my $type = $args->{type} || (
		$args->{file} ? ($args->{file} =~ m|/([A-Z]{2}).[a-z]{4}$| ? $1 : '') : ''
	);
	if (! $type) {
		print STDERR "Unable to determine the type of the report, please specify explicitly\n";
		return undef;
	}
	$args->{type} = $type;
	$args->{data} = read_file($args->{file}) if ($args->{file});
	1;
}

sub new ($$) {

	my $class = shift;
	my $args  = shift || {};

	set_args($args) || return undef;
	my $self = {};
	bless $self, $class;
	$class .= "::$args->{type}" unless $class =~ /\:\:[A-Z]{2}$/;
	my $plugin = firstval {$class eq $_} $self->plugins();
	if (! $plugin) {
		print STDERR "Unknown report type $args->{type}\n";
		return undef;
	}
	$self = $REPORT_TYPES{$args->{type}} eq 'json'
		? $plugin->new($args->{data})
		: $plugin->html_new($args);
	$self->{type} = $args->{type};
	$self;
}

sub html_new ($$) {

	my $class = shift;
	my $args = shift;

	$tb = HTML::TreeBuilder->new;
	my $self = {};
	if ($args->{file}) {
		my $tree = $args->{file};
		$tree =~ s/html/tree/;
		if (-f $tree && (stat($tree))[9] > (stat($args->{file}))[9]-2) {
			debug "Using tree file";
			$tb = retrieve $tree;
			$self->{html} = $tb->{_body};
		}
	}
	if (! $self->{html}) {
		$tb->ignore_unknown(0);
		$tb->implicit_tags(1);
		#               unidecode($args->{data);
		$args->{data} =~ tr/ / /;
		if ($args->{type} eq 'ES' &&
			$args->{data} =~ /width\=100\%/i &&
			$args->{data} !~ /width\=100\%\>/i
		) {
			$args->{data} =~ s/width\=100\%/width\=100\%\>/ig
		}
		$tb->parse($args->{data});
		if ($args->{file}) {
			my $tree = $self->{file} = $args->{file};
			$tree =~ s/html/tree/;
			verbose "Storing tree file $tree";
			store $tb, $tree;
		}
		$self->{html} = $tb->{_body};
	}
	$self->{source} = $args->{data};
	$self->{type}   = $args->{type};
	bless $self, $class;
	$self;
}

sub has_html ($$) {

	my $self = shift;

	return $self->{GS} || $self->{ES} || $self->{RO} || $self->{PL};
}

sub read_status ($$$) {

	my $self   = shift;
	my $cell   = shift;

	my $r = 0;
	$cell = $self->get_sub_tree(0, [0,0], $cell) if $self->{old};
	my $offset = 0;
	my $no_att = 0;
	while (my $row = $self->get_sub_tree(0, [$r], $cell)) {
		my $content = $self->{old} ? $row : $self->get_sub_tree(0, [0,0], $row);
		$r++;
		next unless $content and ! ref($content);
		if ($self->{old} && $r == 4 && $content =~ /\,/) {
			$offset = 1 + $self->{old};
		}
		my $method = $self->{old} ? $HEADER_STATUS_METHODS_OLD[$r+$offset+$no_att] : $HEADER_STATUS_METHODS[$r+$offset];
		if ($content && $content =~ /\s*(attendance|attd)\s+(\d+\S+\d+)\s*$/i) {
			$self->{attendance} = $2;
			$self->{attendance} =~ s/\D//g;
			next;
		}
		if ($r == 11 && ! $self->{attendance}) {
			$method = 'read_status_info';
		}
		if ($content && $content =~ /^\s*(\d+\:\d+)\s+(\S\S)\s+(\S\S)\s+at\s+(.*)/) {
			$self->{time} = "$1 $3";
			$self->{tz}   = $3;
			$self->{location} = $4;
			next;
		}
		next unless $method;
		$self->$method($content);
	}
	$self->convert_time_date();
	$self->{status} ||= 'Preview';
	$self->{status} = 'Final' if
		$self->{status} eq 'End of Game'
			|| $self->{status} eq 'End of Period 4'
			|| $self->{status} eq 'Period 4 (0:00 Remaining)';
}

sub read_date_info ($$$) {

	my $self   = shift;
	my $date   = shift;

	($date) = ($date =~ /\S+,.*?(\S.*)$/);
	$date =~ s/Sept\./Sep/g;
	$date =~ s/Fev\.\S*/Feb/g;
	$date =~ s/Avr\.\S*/Apr/g;
	$date =~ s/Mai\S*/May/g;
	$self->{date} = $date;
}

sub read_time_info ($$$) {

	my $self   = shift;
	my $time   = shift;

	$self->{time} = $time;
}

sub read_arena_info ($$$) {

	my $self       = shift;
	my $arena_info = shift;

	my $stadium;
	my $attendance;

	$arena_info =~ tr/\xA0/ /;
	if ($arena_info !~ /att/i) {
		$stadium = $arena_info;
		if ($arena_info =~ /(\d+\:\d+ \w\w \w\w) (at|\@) (.*)/) {
			$self->{time} = $1;
			$stadium = $3;
		}
		$attendance = 0;
	}
	elsif ($arena_info =~ /attendance.*?(\d+)\,(\d+)\s*$/i) {
		$stadium = 'Unknown';
		$attendance = $1*1000+$2;
	}
	else {
		my $sep;
		($attendance, $sep, $stadium) = ($arena_info =~ /(\S+\d).*?(at\b|\@).*?(\w.*)/);
		unless ($attendance) {
			$attendance = 0;
			if ($arena_info =~ /(at|\@).*?(\w.*)/) {
				$stadium = $2,
			}
		}
		else {
			$attendance =~ s/\D//g;
		}
	}
	$self->{attendance} = $attendance;
	$stadium =~ s/^\s+//;
	$stadium =~ s/\s+$//;
	$stadium =~ s/\s+/ /g;
	$self->{location} = $stadium;
}

sub read_game_info ($$$) {

	my $self = shift;
	my $game_info = shift;

	$game_info =~ /(Game|NHL)\D*(\d{4})/;
	$self->{season_id} = $2;
	return;
}

sub read_status_info ($$$) {

	my $self = shift;
	my $status_info = shift;

	$status_info =~ s/^\s+//;
	$status_info =~ s/\s+$//;
	$self->{status} = $status_info;
	if ($status_info =~ / (\d+) \- (\S.*)/) {
		$self->{season_id}     = $1;
		$self->{status} = $2;
	}
	else {
		$self->{status} = $status_info;
	}
}

sub read_team ($$$$) {

	my $self   = shift;
	my $cell   = shift;
	my $idx    = shift;

	my $name = $self->{old} ?
		$self->get_sub_tree(0, [0,0,6], $cell) :
		$self->get_sub_tree(0, [2,0,0], $cell);
	if (ref $name && $self->{old}) {
		$name = $self->get_sub_tree(0, [0,0,5], $cell);
	}
	my $score = $self->{old} ?
		$self->get_sub_tree(0, [
			2 - (scalar(@{$self->{head}})-1)*(1-$idx)
			+ $idx*($self->{gs}-5)-(scalar(@{$self->{head}})-1)*2*$idx,
			,0,0
		], $cell->{_parent}) : $self->get_sub_tree(0, [1,0,0,0,1,0], $cell);
	$score = $self->get_sub_tree(0, [2+5*$idx+($self->{gs}>=12)*(1-$idx),0,0], $cell->{_parent}) if $score !~ /^\d{1,2}\s*$/;
	$score = $self->get_sub_tree(0, [9,0,0], $cell->{_parent}) if !defined $score || $score !~ /^\d{1,2}\s*$/;
	if (!defined $score || $score !~ /^\s*\d{1,2}\s*$/) {
		die "Unreadable header";
	}
	if ($name) {
		$name =~ s/^\s+//g;
		$name =~ s/\s+$//g;
		$name =~ s/\s+/ /g;
		$name = 'MONTREAL CANADIENS' if $name eq 'CANADIENS MONTREAL';
		$self->{teams}[$idx]{name} = $name;
	}
	$score =~ s/\D//g;
	$self->{teams}[$idx]{score} = $score;
}

sub get_header ($) {

	my $self = shift;

	my $i = 0;
	$self->{head}  = [];
	$self->{teams} = [];
	while(my $base_element = $self->get_sub_tree(0, [$i])) {
		my $extra_div = 0;
		if ($base_element->tag eq 'div' && $base_element->attr('class') eq 'pageBreakAfter') {
			$base_element = $self->get_sub_tree(0, [0], $base_element);
			$extra_div = 1;
		}
		last unless ref $base_element;
		if ($base_element->tag eq 'table') {
			push(@{$self->{head}}, $i);
			push(@{$self->{head}},  0) if $base_element->{_content}[0]->tag eq 'tbody' || $extra_div;
			last;
		}
		$i++;
	}
}

sub read_header ($) {

	my $self = shift;

	$self->get_header();

	my $main_table = $self->get_sub_tree(0, [@{$self->{head}}]);
#	print Dumper $self->{head};
#	print $main_table->dump;

	my $gameinfo_table;
	my $offset = 0;
	if ($main_table->attr('class')) {
		my $content_table = $self->get_sub_tree(0, [0,0,0],$main_table);
		$gameinfo_table = $self->get_sub_tree(0, [0,0,0], $content_table);
		$self->{content_table} = $content_table;
		$self->{old} = 0;
		$offset = 0;
	}
	else {
		$gameinfo_table = $main_table;
		$self->{old} = 1;
		$offset = 2;
	}
	my $gameinfo_row = $self->get_sub_tree(0, [0], $gameinfo_table);
	my $gameinfo_size = @{$gameinfo_row->{_content}};
	$self->{gs} = $gameinfo_size;
	for my $i (0..2) {
		my $cell;
		if ($self->{old} && @{$self->{head}} == 2) {
			$cell = $self->get_sub_tree(0, [ $i*$self->{old}*5 + $self->{old}*(2-$i) - 1 ], $gameinfo_row);
		}
		else {
			$offset = $i + $i*$self->{old}*$gameinfo_size/2 + $self->{old}*(1-2*$i);
			$offset += 1-$i if $gameinfo_size == 12;
			$offset += 1-$i if $gameinfo_size == 14;
			$cell = $self->get_sub_tree(0, [ $self->{old} ? $offset : ($offset, 0), ], $gameinfo_row);
		}
		($i % 2) ? $self->read_status($cell) : $self->read_team($cell, $i / 2);
	}
	if ($self->{status} =~ /end.*period (3|4)/i
			&& $self->{teams}[0]{score} != $self->{teams}[1]{score}) {
		$self->{status} = 'final';
	}
	$self->{season}-- if ($self->{month} < 9);
	if (
		($self->{season} != 2012 && $self->{month} > 3 &&
		 $self->{month} < 8 && $self->{season_id} <= $LAST_PLAYOFF_GAME_INDEX) ||
		($self->{season} == 2012 && $self->{start_ts} >= $LATE_START_IN_2012)) {
		$self->{stage} = $PLAYOFF;
	}
	else {
		$self->{stage} = $REGULAR;
	}
	$self->{teams}[0]{name} = 'MONTREAL CANADIENS'
		if $self->{teams}[0]{name} eq 'CANADIENS MONTREAL';
	$self->{teams}[1]{name} = 'MONTREAL CANADIENS'
		if $self->{teams}[1]{name} eq 'CANADIENS MONTREAL';
	$self->{_id} = $self->{season} * 100000 + $self->{stage} * 10000 + $self->{season_id};
	$self->{periods} ||= [{},{},{}];
	delete $self->{gs};
	$self->fill_broken($BROKEN_HEADERS{$self->{_id}});
	$self->{attendance} ||= 0;
	ref ($self) =~ /\:\:(\w\w)$/;
	$self->{type} = $1;
	$self->{status} = uc $self->{status};
}

sub convert_time_date ($;$) {

	my $self     = shift;
	my $force_us = shift || 0;
	
	my $date = $self->{date};
	my $time = $self->{time};
	my ($year, $month, $day) = $date =~ /^\d/ && ! $force_us
		? Decode_Date_EU($date)
		: Decode_Date_US($date);

	$self->{season} ||= $year;
	$self->{month}    = $month;
	$year -= 1900;
	$month--;
	my ($start_h, $start_m, $start_tz, $end_h, $end_m, $end_tz) =
		($time =~ /(\d+):(\d+)\W*(\w{1,2}T)\s*\;\D*(\d+):(\d+)\W*(\w{1,2}T)/);
	unless ($end_h) {
		($start_h, $start_m, $start_tz) = ($time =~ /(\d+):(\d+)\W*(\w{1,2}T)\W*/);
		unless ($start_h) {
			$start_h  = 12;
			$start_m  = 0;
			$start_tz = 'EDT';
		}
		$end_h = $start_h + 3;
		$end_m = $start_m;
		$end_tz = $start_tz;
	}
	$start_h += 12 if $start_h < 12;
	$end_h   += 12 if $end_h   < $start_h;
	$self->{start_ts} = timelocal(0, $start_m, $start_h, $day, $month, $year);
	if ($end_h > 23) {
		$self->{end_ts} = $self->{start_ts} + 10800;
	}
	else {
		$self->{end_ts} = timegm(0, $end_m, $end_h, $day, $month, $year);
	}
	$self->{tz} ||= $start_tz;
}

sub parse     ($) { die "Overload me" }
sub normalize ($) { }

sub force_decision ($$) {

	my $self = shift;
	my $team = shift;

	my @goalies = sort {
		get_seconds($b->{timeOnIce}) <=>  get_seconds($a->{timeOnIce})
	} grep { $_->{position} eq 'G' } @{$team->{roster}};
	my $goalie = $goalies[0];
	if ($self->{_score}[0] == $self->{_score}[1]) {
		$goalie->{decision} = 'T';
	}
	elsif ($self->{_score}[$self->{_t}] > $self->{_score}[1 - $self->{_t}]) {
		$goalie->{decision} = 'W';
	}
	else {
		$goalie->{decision} = $self->{ot} || $self->{so} ? 'O' : 'L';
	}

}

sub get_sub_tree ($$$;$) {

	my $self         = shift;
	my $want_content = shift;
	my $walk         = shift;
	my $tree         = shift || $self->{html} || $self;

	print "Walking ",join(".", @{$walk}), "\n" if $ENV{SHOW_WALK};
	my $tpointer = \$tree;
	for my $node (@{$walk}) {
		return undef unless $$tpointer && ref $$tpointer;
		my $tc = ${$tpointer}->{_content}[$node];
		$tpointer = \$tc;
	}
	my $tcopy = $$tpointer;
	return $want_content ? $tcopy->{_content} : $tcopy;
}

sub process ($) {

	my $self = shift;

	$self->read_header() unless $self->{type} eq 'BH';
	$self->parse();
	$self->normalize();
	$self->{html}->delete();
	delete $self->{source};
}

sub set_event_extra_data ($) {

	my $self   = shift;
	for my $event (@{$self->{events}}) {
		$event->{sources} = {$self->{type} => 1};
		$event->{game_id} = delete $event->{game} if $event->{game};
		$event->{player1} ||= $BENCH_PLAYER_ID if ($event->{penalty});
		my $t = -1;
		if ($event->{team1}) {
			$event->{team1} = resolve_team($event->{team1}) if
				$event->{team1} ne 'OTH';
			$t = $event->{team1} eq $self->{teams}[0]{name}
				? 0
				: $event->{team1} eq $self->{teams}[1]{name}
				? 1
				: -1;
		}
		$event->{team2} = resolve_team($event->{team2}) if $event->{team2} && $event->{team2} ne 'OTH';
		$event->{t} = $t;
		$event->{ts} =
			$event->{special} ? 0 :
				$event->{stage} == $PLAYOFF || $event->{stage} == $REGULAR && $event->{period} < 5 ?
					($event->{period}-1) * 1200 + get_seconds($event->{time}) : 3900;
	}
	$self->{no_events} unless @{$self->{events}};
}

END {
	$tb->delete if defined $tb;
}

1;

=head1 AUTHOR

More Hockey Stats, C<< <contact at morehockeystats.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<contact at morehockeystats.com>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Sport::Analytics::NHL::Report>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Sport::Analytics::NHL::Report


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Sport::Analytics::NHL::Report>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Sport::Analytics::NHL::Report>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Sport::Analytics::NHL::Report>

=item * Search CPAN

L<https://metacpan.org/release/Sport::Analytics::NHL::Report>

=back

