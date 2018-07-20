package Sport::Analytics::NHL::Tools;

use v5.10.1;
use strict;
use warnings FATAL => 'all';

use File::Find;
use File::Path qw(make_path);
use POSIX qw(strftime);

use Date::Parse;
use JSON;
use List::MoreUtils qw(any);

use Sport::Analytics::NHL::LocalConfig;
use Sport::Analytics::NHL::Config;
use Sport::Analytics::NHL::DB;
use Sport::Analytics::NHL::Util;

use parent 'Exporter';

=head1 NAME

Sport::Analytics::NHL::Tools - Commonly used routines that are system-dependent

=head1 SYNOPSIS

Commonly used routines that are specific to the Sport::Analytics::NHL ecosystem. For the independent stuff see Sport::Analytics::NHL::Util .

  use Sport::Analytics::NHL::Tools;
  my $game = parse_nhl_game_id(2011020001);
  my $season = get_season_from_date(20110202); # returns 2010
  my $team = resolve('NY Rangers'); # returns NYR
  #and so on

Provides global variable $DB that can be used to store the MongoDB handle.

=head1 FUNCTIONS

=over 2

=item C<parse_nhl_game_id>

 Parses the SSSSTTNNNN nhl id
 Arguments: the nhl game id
 Returns: hashref with season, stage, season id and our SSSSTNNNN id

=item C<parse_our_game_id>

 Parses the SSSSTNNNN our id
 Arguments: our game id
 Returns: hashref with season, stage, season id and our SSSSTNNNN id

=item C<get_season_from_date>

 Figures out the NHL season (start year) the given YYYYMMDD date refers to
 Arguments: the YYYYMMDD date
 Returns: the YYYY or YYYY-1 season

=item C<get_schedule_json_file>

 Returns the path to the schedule file in the filesystem
 Arguments: the season and the root of the data (optional)
 Returns: the path to the schedule file

=item C<resolve_team>

 Attempts to resolve the name of a team to the normalized 3-letter id
 Arguments: the name of a team, optional no-db force flag
 Returns: the 3-letter normalized id

=item C<convert_new_schedule_game>

Converts a game record obtained from the 'live' interface to a normalized form

 Arguments: the game record
 Returns: the normalized game

=item C<arrange_new_schedule_by_date>

Arranges the schedule obtained from the 'live' interface by dates

 Arguments: the schedule
 Returns: hashref with keys of dates,
  values of lists of normalized game records

=item C<convert_old_schedule_game>

Converts a game record obtained from the API interface to a normalized form

 Arguments: the game record
 Returns: the normalized game

=item C<arrange_old_schedule_by_date>

Arranges the schedule obtained from the API interface by dates

 Arguments: the schedule
 Returns: hashref with keys of dates,
  values of lists of normalized game records

=item C<convert_schedule_game>

Converts a game record obtained scraping the schedules to a normalized form

 Arguments: the game record
 Returns: the normalized game

=item C<arrange_schedule_by_date>

Arranges the schedule obtained by the scraper by dates

 Arguments: the schedule
 Returns: hashref with keys of dates,
  values of lists of normalized game records

=item C<get_games_for_dates_from_db>

Gets the list of the games scheduled for given dates using the file storage

 Arguments: the list of dates
 Returns: the list of normalized game records

=item C<get_games_for_dates_from_fs>

Gets the list of the games scheduled for given dates using the database

 Arguments: the list of dates
 Returns: the list of normalized game records

=item C<get_games_for_dates>

Gets the list of the games scheduled for given dates

 Arguments: the list of dates
 Returns: the list of normalized game records

=item C<get_start_stop_date>

Gets the earliest possible start and latest possible end for a season in format YYYY-MM-DD

 Arguments: the season
 Returns: (YYYY-09-02,YYYY+1-09-01)

=item C<make_game_path>

Creates and/or returns the game path for a given season, stage, season_id

 Arguments: season, stage, season_id, root storage dir (optional)
 Returns: the storage path (created if necessary)

=item C<read_schedules>

Reads the existing schedules for the given range of seasons

 Arguments: the hashref with first and last season of the range
 Returns: the schedule data, hashref by season

=item C<get_game_id_from_path>

Given the game path, produces our SSSSTNNNN game id

 Arguments: the game path
 Returns the SSSSTNNNN id, or undef if the matching of the path failed

=item C<read_existing_game_ids>

Find games already scraped into the filesystem and returns the game ids of them.

 Arguments: the season to look for
 Returns: hashref of game ids as keys and 1s as values

=back

=cut

our @EXPORT = qw(
	$DB
	parse_nhl_game_id parse_our_game_id
	resolve_team get_games_for_dates
	get_season_from_date get_start_stop_date str3time
	get_schedule_json_file make_game_path get_game_id_from_path
	get_game_files_by_id
	arrange_schedule_by_date convert_schedule_game read_schedules
	read_existing_game_ids
	vocabulary_lookup normalize_penalty
);

our $DB;

sub parse_nhl_game_id ($) {

	my $nhl_id = shift;

	$nhl_id =~ /^(\d{4})(\d{2})(\d{4})$/;
	{
		season    => $1,
		stage     => $2 + 0,
		season_id => $3,
		game_id   => $1*100000 + $2*10000 + $3
	};
}

sub parse_our_game_id ($) {

	my $our_id = shift;

	$our_id =~ /^(\d{4})(\d{1})(\d{4})/;
	{
		season    => $1,
		stage     => $2 + 0,
		season_id => $3,
		game_id   => $our_id,
	};
}

sub get_season_from_date ($) {

	my $date = shift;

	$date =~ /^(\d{4})(\d{2})(\d{2})/;
	$2 > 8 ? $1 : $1 - 1;
}

sub get_schedule_json_file ($;$) {

	my $season   = shift;
	my $data_dir = shift || $ENV{HOCKEYDB_DATA_DIR} || $DATA_DIR;

	sprintf("%s/%s/schedule.json", $data_dir, $season);
}

sub get_games_for_dates_from_db (@) {

	my @dates = @_;

	$DB ||= Sport::Analytics::NHL::DB->new();
	my @games = $DB->{dbh}->get_collection('schedule')->find(
		{ date => {
			'$in' => [map($_+0, @dates)],
		}},
		{_id => 0, season => 1, stage => 1, season_id => 1}
	)->all();
	if (! @games) {
		print STDERR "No matching games found in the database, trying files\n";
		@games = get_games_for_dates_from_fs(@dates);
	}
	@games;
}

sub resolve_team ($;$) {

	my $team = shift;
	my $force_no_db = shift || 0;

	if (! $force_no_db && $ENV{MONGO_DB}) {
		$DB ||= Sport::Analytics::NHL::DB->new();
		my $team_id = $DB->resolve_team_db($team);
		return $team_id if $team_id;
	}
	return 'MTL' if ($team =~ /MONTR.*CAN/i || $team =~ /CAN.*MONTR/);
	return 'NHL' if ($team eq 'League');
	for my $team_id (keys %TEAMS) {
		return $team_id if $team_id eq $team;
		for my $type (qw(short long full)) {
			return $team_id if grep { uc($_) eq uc($team) } @{$TEAMS{$team_id}->{$type}};
		}
	}
	die "Couldn't resolve team $team";
}

=over 2

=item C<str3time>

Wraps around str2time to fix its parsing the pre-1969 dates to the same timestamp as their 100 years laters.
Arguments: the str2time argument string
Returns: the correct timestamp (negative for pre-1969)

=back

=cut

sub str3time ($) {

	my $str   = shift;

	my $time = str2time($str);
	my $year = substr($str, 0, 4);

	$time -= (31536000 + 3124224000) if $year < 1969;
	$time;
}

sub convert_new_schedule_game ($) {

	my $schedule_game = shift;
	my $game = {};
	$game->{stage}     = substr($schedule_game->{id},5,1)+0;
	return undef if $game->{stage} ne $REGULAR && $game->{stage} ne $PLAYOFF;
	$game->{season}    = substr($schedule_game->{id},0,4)+0;
	$game->{season_id} = $schedule_game->{id} % 10000+0;
	$game->{_id}       = (delete $schedule_game->{id})+0;
	$game->{game_id}   = sprintf(
		"%04d%d%04d",$game->{season},$game->{stage},$game->{season_id}
	)+0;
	$game->{ts}        = str3time(delete $schedule_game->{est})+0;
	$game->{date}      = strftime("%Y%m%d", localtime($game->{ts}))+0;
	$game->{away}      = resolve_team(delete $schedule_game->{a});
	$game->{home}      = resolve_team(delete $schedule_game->{h});
	$game;
}

sub arrange_new_schedule_by_date ($$) {

	my $schedule_by_date   = shift;
	my $schedule_json_data = shift;


	for my $schedule_game (@{$schedule_json_data}) {
		my $game = convert_new_schedule_game($schedule_game);
		next unless $game;
		$schedule_by_date->{$game->{date}} ||= [];
		push(@{$schedule_by_date->{$game->{date}}}, $game);
	}
}

sub convert_old_schedule_game ($) {

	my $schedule_game = shift;

	my $stage     = substr($schedule_game->{gamePk},5,1);
	return undef if $stage != $REGULAR && $stage != $PLAYOFF;
	my $game = {
		away      => resolve_team($schedule_game->{teams}{away}{team}{name}),
		home      => resolve_team($schedule_game->{teams}{home}{team}{name}),
		_id       => $schedule_game->{gamePk} + 0,
		stage     => $stage + 0,
		season    => substr($schedule_game->{gamePk}, 0, 4) + 0,
		season_id => $schedule_game->{gamePk} % 10000 + 0,
		ts        => str3time($schedule_game->{gameDate}),
		year      => substr($schedule_game->{gameDate}, 0, 4) + 0,
	};
	$game->{game_id}   = sprintf(
		"%04d%d%04d",$game->{season},$game->{stage},$game->{season_id}
	)+0;
	$game->{date}      = strftime("%Y%m%d", localtime($game->{ts}))+0;
	#use Data::Dumper;
	#print Dumper $game;
	$game;
}

sub arrange_old_schedule_by_date ($$) {

	my $schedule_by_date   = shift;
	my $schedule_json_data = shift;

	for my $schedule_date (@{$schedule_json_data->{dates}}) {
		for my $schedule_game (@{$schedule_date->{games}}) {
			my $game = convert_old_schedule_game($schedule_game);
			if ($game) {
				$schedule_by_date->{$game->{date}} ||= [];
				push(@{$schedule_by_date->{$game->{date}}}, $game);
			}
		}
	}
}

sub convert_schedule_game ($) {

	my $game = shift;

	$game->{gamePk}
		? convert_old_schedule_game($game)
		: convert_new_schedule_game($game);
}

sub arrange_schedule_by_date ($$) {
	my $schedule_by_date   = shift;
	my $schedule_json_data = shift;

	ref $schedule_json_data eq 'ARRAY' ?
		arrange_new_schedule_by_date($schedule_by_date, $schedule_json_data) :
		arrange_old_schedule_by_date($schedule_by_date, $schedule_json_data);
}

sub get_games_for_dates_from_fs(@) {

	my @dates = @_;

	my %jsons = ();
	my $schedule_by_date = {};
	my @games = ();
	for my $date (@dates) {
		my $season = get_season_from_date($date);
		my $schedule_file = sprintf("%s/%d/schedule.json", $ENV{HOCKEYDB_DATA_DIR} || $DATA_DIR, $season);
		if (! -f $schedule_file) {
			print STDERR
				"[ERROR] No schedule crawl specified, and no schedule file $schedule_file present for $date\n";
			next;
		}
		unless ($jsons{$season}) {
			my $json = read_file($schedule_file);
			$jsons{$season} = decode_json($json);
			arrange_schedule_by_date($schedule_by_date, $jsons{$season});
		}
		unless ($schedule_by_date->{$date}) {
			print STDERR "No games scheduled for $date, skipping...\n";
			next;
		}
		push(@games, @{$schedule_by_date->{$date}})
	}
	@games;
}

sub get_games_for_dates (@) {

	my @dates = @_;

	$ENV{MONGO_DB} ?
		get_games_for_dates_from_db(@dates) :
		get_games_for_dates_from_fs(@dates);
}

sub get_start_stop_date ($) {

	my $season = shift;

	(
		sprintf("%04d-%02d-%02d", $season+0, 9, 2),
		sprintf("%04d-%02d-%02d", $season+1, 9, 1),
	);
}

sub make_game_path ($$$;$) {

	my $season         = shift;
	my $stage          = shift;
	my $season_id      = shift;
	my $base_dir       = shift || $ENV{HOCKEYDB_DATA_DIR} || $DATA_DIR;

	my $path = sprintf("%s/%04d/%04d/%04d", $base_dir, $season, $stage, $season_id);
	return $path if -d $path && -w $path;
	make_path($path) or die "Couldn't create path $path\n";

	$path;
}

sub read_schedules ($) {

	my $opts = shift;

	my $start_season = $opts->{start_season} || $FIRST_SEASON;
	my $stop_season  = $opts->{stop_season}  || $CURRENT_SEASON;
	my $schedules = {};

	for my $season ($start_season .. $stop_season) {
		my $json_file = get_schedule_json_file($season);
		debug "Using schedule from file $json_file";
		next unless -f $json_file;
		my $json = read_file($json_file);
		$schedules->{$season} = decode_json($json);
	}
	$schedules;
}

sub get_game_id_from_path ($) {

	my $path = shift;

	$path =~ m|^$ENV{HOCKEYDB_DATA_DIR}/(\d{4})/(\d{4})/(\d{4})|;
	$1 && $2 && $3 ? $1*100000 + $2*10000 + $3 : undef;
}

=over 2

=item C<get_game_path_from_id>

Gets the expected SSSS/TTTT/NNNN path for our 9-digit game id.
Arguments: our 9-digit game id
Returns: the path (creates it if necessary)

=back

=cut

sub get_game_path_from_id ($;$) {

	my $id       = shift;
	my $data_dir = shift;

	my $game = parse_our_game_id($id);
	make_game_path($game->{season}, $game->{stage}, $game->{season_id}, $data_dir);
}

sub read_existing_game_ids ($) {

	my $season = shift;

	my $game_ids = {};
	find(
		sub {
			if ($_ eq $MAIN_GAME_FILE || $_ eq $SECONDARY_GAME_FILE) {
				$game_ids->{get_game_id_from_path($File::Find::dir)} = 1;
			}
		},
		"$ENV{HOCKEYDB_DATA_DIR}/$season",
	);
	$game_ids;
}

=over 2

=item C<get_game_files_by_id>

Gets existing game files for the given game Id. Assumes SSSS/TTTT/NNNN file tree structure under the root data directory.
Arguments:
 * our 9-digit game id
 * (optional) root data directory
Returns: The list of html/json reports from the game directory

=back

=cut

sub get_game_files_by_id ($;$) {

	my $game_id  = shift;
	my $data_dir = shift || $ENV{HOCKEYDB_DATA_DIR} || $DATA_DIR;

	my $path = get_game_path_from_id($game_id, $data_dir);
	debug "Using path $path";
	opendir(DIR, $path);
	my @game_files = map { "$path/$_" } grep {
		-f "$path/$_" && (/html$/ || /json$/)
	} readdir(DIR);
	closedir(DIR);

	@game_files;
}

=over 2

=item C<vocabulary_lookup>

Normalizes one of the following event properties from different variants:
 * penalty
 * shot_type
 * miss
 * strength
 * stoppage reason

Arguments: the property name and the original string
Returns: the normalized, vocabulary-matched string

=back

=cut

sub vocabulary_lookup ($$) {

	my $vocabulary = shift;
	my $string     = shift;

	$string =~ tr/ / /;
	$string =~ s/^\s+//;
	$string =~ s/\s+$//;
	$string = uc $string;
	#print "resolving $string\n";
	return $string if $VOCABULARY{$vocabulary}->{$string};
	for my $word (keys %{$VOCABULARY{$vocabulary}}) {
		my $alternatives = $VOCABULARY{$vocabulary}->{$word};
		if (any {
			#print "!$string!-!$_!\n";
			$string eq $_
		} @{$alternatives}) {
#			print "resolved to $word\n";
			return $word;
		}
	}
	die "Unknown word $string for vocabulary $vocabulary";
}

=over 2

=item C<normalize_penalty>

Normalizes an NHL Report penalty string including a vocabulary lookup
Arguments: the original string
Returns: the normalized, vocabulary-matched string

=back

=cut

sub normalize_penalty ($) {

	my $penalty = shift;

	$penalty =~ s/(\- double minor)//i;
	$penalty =~ s/(\- obstruction)//i;
	$penalty =~ s/(\-\s*bench\b)//i;
	$penalty =~ s/(PS \- )//i;
	#print Dumper $ld_event->{result}{secondaryType};
	vocabulary_lookup('penalty', $penalty);

}

1;

=head1 AUTHOR

More Hockey Stats, C<< <contact at morehockeystats.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<contact at morehockeystats.com>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Sport::Analytics::NHL::Tools>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Sport::Analytics::NHL::Tools

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Sport::Analytics::NHL::Tools>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Sport::Analytics::NHL::Tools>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Sport::Analytics::NHL::Tools>

=item * Search CPAN

L<https://metacpan.org/release/Sport::Analytics::NHL::Tools>

=back
