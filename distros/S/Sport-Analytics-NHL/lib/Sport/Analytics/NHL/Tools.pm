package Sport::Analytics::NHL::Tools;

use v5.10.1;
use strict;
use warnings FATAL => 'all';
use experimental qw(smartmatch);
no warnings 'qw';

use Carp;

use File::Find;
use File::Path qw(make_path);
use List::Util qw(reduce sum);
use POSIX qw(strftime);
use Storable qw(store retrieve dclone);

use BSON::OID;
use Date::Parse;
use Date::Format qw(time2str);
use JSON;
use List::MoreUtils qw(any part firstval);

use Sport::Analytics::NHL::Vars	qw(
	:globals :web
	$DATA_DIR $REPORTS_DIR $CURRENT_SEASON $MONGO_DB $NORMALIZED_JSON
);
use Sport::Analytics::NHL::Config
	qw(:ids :basic :files $FIRST_SEASON %TEAMS :vocabularies);
use Sport::Analytics::NHL::Errors;
use Sport::Analytics::NHL::DB;
#use Sport::Analytics::NHL::SQL;
#use Sport::Analytics::NHL::Elo;
use Sport::Analytics::NHL::Util qw(:debug :utils :file); # qw(:all);
#use Sport::Analytics::NHL::Magick;

use Data::Dumper;

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

=head1 GLOBAL VARIABLES

=over 2

=item $DB

This global exported variable is used to hold an instance of a MongoDB connection.

=item $CACHES

This global exported hash reference is used to hold various information for caching purposes

=back

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

=item C<get_catalog_map>

Convert a catalog collection (i.e. stopreasons) to a hashref NAME to MongoID

 Arguments: the catalog name

 Returns: the aforementioned hashref

=item C<get_event_strength>

Gets the event strength from the 'str' collection.

 Arguments: the event
            the timeline of the game's strengths

 Returns: the matched strength.

=item C<get_first_coord_adjust_event>

The NHL coordinates are inconsistent in a way that sometimes the home team's zone is a negative X, and sometimes is a positive.
Therefore there's a need to coordinate adjustments. This function returns the first suitable event to deduce this adjustment.

 Arguments: the game
            the zones map

 Returns: the matched event or undef.

=item C<get_game_coords_adjust>

As described above, this produces an adjustment for the coordinates. The coordinates are adjusted either by the first goal, or by other suitable event.

 Arguments: the game
            the zones map

 Returns: 1 or -1

=item C<get_game_first_coord_goal>

Gets the first goal that allows to adjust the coordinates.

 Arguments: the game
            the zones map

 Returns: the matched goal or undef.

=item C<get_game_goalies>

Gets the list of all goalies who participated in the game

 Arguments: the game

 Returns: the arrayref with the goalies.

=item C<get_games_from_schedule>

Gets the scheduled games from the schedule collection by game ids

 Arguments: array of game ids

 Returns: array of scheduled game entries

=item C<get_player_position>

Gets the position of a given player and stores it in the global cache ($CACHE->{players})

 Arguments: player's NHL ID

 Returns: the position or 'S'

=item C<get_zones>

Gets the catalog map of zones

 Arguments: none

 Returns: hashref of four zones (OFF, NEU, DEF, UNK) and their Mongo IDs.

=item C<has_on_ice>

Tests if the event has a valid on-ice field (an array of two vectors)

 Arguments: the event

 Returns: 0 or 1

=item C<is_lead_changing_goal>

Tests if the goal changes the lead in the game

 Arguments: the current score
            the scoring team index (0 or 1)

 Returns: 0 or 1

=item C<is_lead_swinging_goal>

Tests if the goal swings the lead in the game

 Arguments: the current score
            the scoring team index (0 or 1)
            the last leader in the game

 Returns: 0 or 1

=back

=cut

our @basic = qw(
	parse_nhl_game_id parse_our_game_id
	get_season_from_date get_start_stop_date
);

our @path = qw(
	make_game_path get_game_id_from_path
	get_game_path_from_id read_existing_game_ids
	get_game_files_by_id get_schedule_json_file
);

our @web = qw(
);

our @schedule = qw(
	convert_schedule_game arrange_schedule_by_date get_schedule_json_file
	read_schedules get_games_from_schedule
);

our @db = qw(
	resolve_team get_games_for_dates
	get_player_position get_zones get_catalog_map get_game_goalies
);

our @sql = qw(
);

our @parser = qw(
	vocabulary_lookup normalize_penalty is_noplay_event has_on_ice
	set_player_stat
);

our @gameutils = qw(
	is_noplay_event has_on_ice get_game_goalies get_player_position
	is_lead_changing_goal is_lead_swinging_goal get_event_strength get_game_coords_adjust
);

our @generic = (@basic, @path, @schedule, @db);
our @EXPORT_OK = (@basic, @path, @web, @schedule, @db, @sql, @parser, @gameutils);
our @EX = qw(
	is_noplay_event
	set_player_stat fix_playergoals
	create_table_func
	prepare_seasonteams_cache get_team_full_name_at_season get_team_conference
	has_pulled_goalie get_zones is_lead_changing_goal is_lead_swinging_goal
	get_catalog_map cc get_game_goalies
	generate_player_lookup_table generate_coach_lookup_table
	get_game_coords_adjust numerify_structure
	calculate_pick_adjustment
	print_events get_daily_coaches_f2f execute_templated_table_query
	get_shootout_rating build_shootout_teams
	generate_prediction_summary restart_hypnotoad
	build_game_scores update_daily_tables get_current_goalies get_current_teams
	get_points_projections produce_daily_games compute_teams_elo
	create_match_crosstable get_divs_cons_standings format_divs_crosstable
	get_gamestamp generate_density_sql generate_density_animation
	aggregate_season_shots_by_periods produce_team_data svp_vs_shots
);

our %EXPORT_TAGS = (
	basic     => [@basic],
	generic   => [@generic],
	path      => [@path],
	web       => [@web],
	schedule  => [@schedule],
	gameutils => [@gameutils],
	db        => [@db],
	sql       => [@sql],
	parser    => [@parser],
	all       => [@EXPORT_OK],
);

my %POSITION_ORDER = (
	'N/A' => 1,
	C => 1,
	L => 1,
	R => 1,
	D => 2,
	G => 3,
);

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
	my $data_dir = shift || $ENV{HOCKEYDB_DATA_DIR} || $REPORTS_DIR;

	sprintf("%s/%s/schedule.json", $data_dir, $season);
}

sub get_games_for_dates_from_db (;@) {

	my @dates = @_;

	@dates = (strftime("%Y%m%d",localtime(time))) unless @dates;
	$DB ||= Sport::Analytics::NHL::DB->new();
	my @games = $DB->{dbh}->get_collection('schedule')->find(
		{ date => {
			'$in' => [map($_+0, @dates)],
		}},
		{_id => 0, season => 1, stage => 1, season_id => 1}
	)->all();
	if (! @games) {
		verbose "No matching games found in the database, trying files";
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
	return 'NHL' if ($team eq 'League' || $team eq 'NHL');
	for my $team_id (keys %TEAMS) {
		return $team_id if $team_id eq $team;
		for my $type (qw(short long full)) {
			return $team_id if grep { uc($_) eq uc($team) } @{$TEAMS{$team_id}->{$type}};
		}
	}
	die "Couldn't resolve team $team";
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
		my $schedule_file = sprintf("%s/%d/schedule.json", $ENV{HOCKEYDB_DATA_DIR} || $REPORTS_DIR, $season);
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
			verbose "No games scheduled for $date, skipping...\n";
			next;
		}
		push(@games, @{$schedule_by_date->{$date}})
	}
	@games;
}

sub get_games_for_dates (;@) {

	my @dates = @_;

	$MONGO_DB || $ENV{MONGO_DB} ?
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
	my $base_dir       = shift || $ENV{HOCKEYDB_DATA_DIR} || $REPORTS_DIR;

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
	my $data_dir = shift || $ENV{HOCKEYDB_DATA_DIR} || $REPORTS_DIR;

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
	my $data_dir = shift || $ENV{HOCKEYDB_DATA_DIR} || $REPORTS_DIR;

	my $path = get_game_path_from_id($game_id, $data_dir);
	debug "Using path $path";
	opendir(DIR, $path);
	my @game_files = map { "$path/$_" } grep {
		$_ ne $NORMALIZED_JSON &&
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
	return $string if $VOCABULARY{$vocabulary}->{$string};
	for my $word (keys %{$VOCABULARY{$vocabulary}}) {
		my $alternatives = $VOCABULARY{$vocabulary}->{$word};
		if (any {
			$string eq $_
		} @{$alternatives}) {
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
	vocabulary_lookup('penalty', $penalty);

}

sub get_games_from_schedule (@) {

	$DB ||= Sport::Analytics::NHL::DB->new();

	my $schedule_c = $DB->get_collection('schedule');
	my @scheduled_games = $schedule_c->find({
		game_id => { '$in' => [map($_+0, @_) ] }
	})->sort({ts => 1})->all();

	@scheduled_games;
}

=over 2

=item C<is_noplay_event>

Check if the event is not a played one (PEND, GEND, PSTR, STOP)

=back

=cut

sub is_noplay_event ($) {
	my $event = shift;

	$event->{type} eq 'PEND'    || $event->{type} eq 'PSTR'
        || $event->{type} eq 'GEND' || $event->{type} eq 'STOP';
}

sub has_on_ice ($) {
	my $event = shift;

	$event->{on_ice} && @{$event->{on_ice}} &&
		@{$event->{on_ice}[0]} && @{$event->{on_ice}[1]};
}

sub get_player_position ($) {

	my $player_id = shift;

	$DB ||= Sport::Analytics::NHL::DB->new();
	my $players_c = $DB->get_collection('players');
	$CACHES->{players}{$player_id} ||=
		$players_c->find_one({_id => $player_id+0});
	$CACHES->{players}{$player_id}{position} || 'S';
}

sub get_game_goalies ($) {

	my $game = shift;

	my $goalies = [];
	for my $t (0,1) {
		$goalies->[$t] = [
			grep { $_->{position} eq 'G' } @{$game->{teams}[$t]{roster}}
		];
	}

	$goalies;
}

sub get_catalog_map ($) {

	my $catalog = shift;

	$DB ||= Sport::Analytics::NHL::DB->new();
	my $catalog_c = $DB->get_collection($catalog);
	my @items     = $catalog_c->find()->all();

	my $map = {};
	for my $item (@items) {
		$map->{$item->{name}} = $item->{_id};
	}

	$map;
}

sub get_zones () { get_catalog_map('zones'); }

=over 2

=item C<set_player_stat>

A testing helper that sets the player stats the way they seem to appear in the event summary rather than in the boxscore, or finds a way to arbitrate the discrepancies.

Arguments:
 * The boxscore
 * The NHL id of the player being fixed
 * The stat to fix
 * The value of the stat in the event summary
 * The possible arbitration delta

Returns: void. The boxscore is updated.

=back

=cut

sub set_player_stat ($$$$;$) {

	my $boxscore  = shift;
	my $player_id = shift;
	my $stat      = shift;
	my $value     = shift;
	my $delta     = shift || 0;

	for my $t (0,1) {
		for my $player (@{$boxscore->{teams}[$t]{roster}}) {
			if ($player->{_id} == $player_id) {
				if ($stat eq 'goalsAgainst' && defined $player->{saves}) {
					$player->{saves} = $player->{shots} - $value;
					debug "Setting $player->{_id} $stat to $value";
					$player->{$stat} = $value;
				}
				elsif ($stat eq 'penaltyMinutes') {
					if ($delta) {
						debug "Setting $player->{_id} $stat to $value+$delta";
						$player->{$stat} = $delta;
					}
				}
				elsif (defined $player->{$stat}) {
					debug "Setting $player->{_id} $stat to $value";
					$player->{$stat} = $value;
				}
				return;
			}
		}
	}
	die "Couldn't find $player_id / $stat\n";
	1;
}

sub is_lead_changing_goal ($$) {

	my $score  = shift;
	my $scorer = shift;

	return 1 if $score->[0]           == $score->[1];
	return 1 if $score->[$scorer] + 1 == $score->[1-$scorer];
	return 0;
}

sub is_lead_swinging_goal ($$$) {

	my $score       = shift;
	my $scorer      = shift;
	my $last_leader = shift;

	return 0 unless defined $last_leader;
	return 1 if $score->[0] == $score->[1] && $scorer != $last_leader;
	return 0;
}

sub get_event_strength ($@) {

	my $event     = shift;
	my @strengths = @_;

	my $str = firstval {
		(
			$event->{type} eq 'FAC' && $_->{from} <= $event->{ts}
			|| $event->{type} ne 'FAC' && $_->{from} < $event->{ts}
		) && (
			$event->{type} eq 'FAC' && $_->{to} > $event->{ts}
			|| $event->{type} ne 'FAC' && $_->{to} >= $event->{ts}
		)
	} @strengths;
	$str;
}

sub get_game_first_coord_goal ($$) {

	my $game = shift;
	my $zones = shift;

	my $GOAL_c = $DB->get_collection('GOAL');
	my $goal = $GOAL_c->find_one({
		game_id         => $game->{_id} + 0, so => 0,
		'coordinates.x' => { '$exists' => 1 },
		zone            => $zones->{OFF},
	});
	$goal;
}

sub get_first_coord_adjust_event ($$) {

	my $game     = shift;
	my $zones    = shift;

	my $events_c = $DB->get_collection('events');
	for my $event_id (@{$game->{events}}) {
		my $_event = $events_c->find_one({event_id => $event_id+0});
		next if is_noplay_event($_event);
		my $collection = $DB->get_collection($_event->{type});
		my $event = $collection->find_one({_id => $event_id+0});
		next if !$event->{zone} || $event->{zone} ne $zones->{DEF};
		next if $event->{so};
		next if ! $event->{coordinates} || ! $event->{coordinates}{x};
		return $event;
	}
	undef;
}

sub get_game_coords_adjust ($$) {

	my $game     = shift;
	my $zones    = shift;

	$DB ||= Sport::Analytics::NHL::DB->new();
	my $adjust = 1;

	return if $BROKEN_FILES{$game->{_id}}{BS};
	my $event = get_game_first_coord_goal($game, $zones) ||
		get_first_coord_adjust_event($game, $zones);
	return unless $event;
	my $x = $event->{coordinates}{x};
	my $t = $event->{t};
	my $p = $event->{period};
	if ($t == 1 && $event->{zone} eq $zones->{OFF}
		|| $t == 0 && $event->{zone} eq $zones->{DEF}) {
		$adjust = -1 if $x > 0 && $p % 2 || $x < 0 && ! ($p % 2);
	}
	else {
		$adjust = -1 if $x < 0 && $p % 2 || $x > 0 && ! ($p % 2);
	}
	$adjust;
}

__END__

sub init_web () {

	$WEB_STAGES = {
		name     => 'stage',
		label    => 'Stage',
		$REGULAR => 'Regular',
		$PLAYOFF => 'Playoff',
	};

	$WEB_STAGES_TOTAL = {
		%{$WEB_STAGES},
		total => 'Total',
	};

	our @START_STOP    = (
		{ name => 'seasonstart', label => 'Start season' },
		{ name => 'seasonstop',  label => 'Stop season'  },
	);
}

sub create_table_func ($;$$) {

	my $self       = shift;
	my $table_name = shift || $self->{sql_table};
	my $table_def  = shift || $self->{sql_table_def};

	$SQL->do(qq{
DROP TABLE IF EXISTS $table_name
}) if $self->{force_drop_table};
	$SQL->do(qq{
CREATE TABLE IF NOT EXISTS $table_name(
$table_def
)
});
}

sub convert_ids_to_names ($$$;$$) {

	my $indices         = shift;
	my $collection_name = shift;
	my $row             = shift;
	my $cache           = shift || $CACHES;
	my $last_name_only  = shift || 0;

	$cache->{$collection_name} ||= {};
	my $collection = $DB->get_collection($collection_name);

	$indices = [$indices] unless ref $indices;
	for my $i (@{$indices}) {
		next unless $row->[$i];
		$row->[$i] += 0 if $row->[$i] =~ /^\d{7}$/;
		$cache->{$collection_name}{$row->[$i]} ||=
			$collection->find_one({
				_id => length($row->[$i]) == 24 ? BSON::OID->new({
					oid => pack("H*",$row->[$i])
				}) : $row->[$i],
			});
		die "Invalid $row->[$i] id for collection $collection_name"
			unless $cache->{$collection_name}{$row->[$i]};
		$row->[$i] = $cache->{$collection_name}{$row->[$i]}{name};
		$row->[$i] =~ s/(.*\b)(\S+.*)/$2/e if $last_name_only;
	}
	@{$row};
}



sub get_shootout_rating ($;$) {

	my $player_id = shift;
	my $is_goalie = shift || 0;

	my $default_rating = $START_RATING + ($is_goalie ? 1 : -1) * $PS_OFFSET;
	$SQL ||= Sport::Analytics::NHL::SQL->new();

	my $season = $SQL->selectcol_arrayref(qq{
SELECT max(season) FROM players_penaltyshots WHERE player=$player_id
})->[0];
	my $rating = $season ? $SQL->selectcol_arrayref(qq{
SELECT rating FROM players_penaltyshots
WHERE player=$player_id AND season=$season
})->[0] : $default_rating;

	$rating;
}

sub build_shootout_teams ($) {

	my $game  = shift;

	my $teams = [ [], [] ];
	for my $t (0,1) {
		my @g_s = part {
			$_->{position} eq 'G' ? 0 : 1
		} grep {
			my $timeonice = $_->{timeOnIce} || $_->{timeonice} || $_->{TIMEONICE};
			if ($timeonice) {
				$timeonice = get_seconds($timeonice);
				$_->{start} ||= 1;
			}
			$timeonice;
		} @{$game->{teams}[$t]{roster}};
		my $goalie;
		if (@{$g_s[0]} == 1) {
			$goalie = $g_s[0]->[0];
		}
		else {
			print Dumper $g_s[0], $g_s[1];
			if (
				$g_s[0]->[0]{start} == 1 && !$g_s[1]->[0]{timeOnIce} ||
				$g_s[1]->[0]{start} == 1 &&  $g_s[0]->[0]{timeOnIce}
			) {
				$goalie = $g_s[0]->[0];
			}
			else {
				$goalie = $g_s[0]->[0];
			}
		}
		my $goalie_rating = get_shootout_rating($goalie->{_id}, 1);
		for my $skater (@{$g_s[1]}) {
			my $skater_rating = get_shootout_rating($skater->{_id}, 0);
			push(@{$teams->[$t]}, {
				name => $skater->{name}, rating => $skater_rating, position => 'S',
			});
		}
		$teams->[$t] = [
			{ name => $goalie->{name}, rating => $goalie_rating, position => 'G' },
			sort { $b->{rating} <=> $a->{rating} } @{$teams->[$t]}
		];
	}
	$teams;
}

sub build_game_scores ($) {

	my $rosters = shift;

	my @scores = ();
	$DB ||= Sport::Analytics::NHL::DB->new();
	$SQL ||= Sport::Analytics::NHL::SQL->new();

	#$ENV{HOCKEYDB_DEBUG} = 1;
	for my $t (0,1) {
		my $roster = $rosters->{teams}[$t]{roster};
		my @player_ids = ();
		my $extra_score = 0;
		for my $player (@{$roster}) {
			my $player_id = $DB->find_player(
				$player->{name},
				$rosters->{teams}[$t]{name},
				$rosters->{season},
				$rosters->{stage},
			);
			if ($player_id) {
				push(@player_ids, $player_id);
			}
			else {
				$extra_score += 0.16;
			}
		}
		my $player_ids = join(',', @player_ids);
		my $_t = 2-$t;
		my $_team = resolve_team($rosters->{teams}[1-$t]{name});
		my $score = $SQL->selectall_arrayref(qq{
SELECT sum(GOALS)
FROM (
	SELECT GOALS
	FROM skater_expectations
	WHERE _team='$_team'
      AND _player IN ($player_ids)
      AND _home_away = $_t
	ORDER BY GOALS DESC
) s
});
		push(@scores, $score->[0][0] + $extra_score);
	}
	@scores;
}

sub update_daily_tables ($@) {

	my $rosters = shift;
	my @scores = @_;

	$SQL ||= Sport::Analytics::NHL::SQL->new();
	$SQL->do(qq{
UPDATE daily_results
SET predicted_home = $scores[1], predicted_away = $scores[0]
WHERE game_id = $rosters->{_id}
});
	my $p_home = sprintf("%2.1f", ($scores[1] / ($scores[1] + $scores[0]) * 100));
	my $p_away = 100 - $p_home;
	$SQL->do(qq{
UPDATE daily_summary_games
SET predicted_home = $scores[1], predicted_away = $scores[0],
    pwin_home = $p_home, pwin_away = $p_away, roster = 1
WHERE game_id = $rosters->{_id}})

}

sub get_current_goalies (;$) {

	my $auto_convert = shift || 0;
	$DB  ||= Sport::Analytics::NHL::DB->new();
	$SQL ||= Sport::Analytics::NHL::SQL->new();

	my $goalies = $SQL->selectall_arrayref(qq{
SELECT player, ROUND(expected_svp,3), ROUND(svp,3), ROUND(rating,0), ROUND(expected_remaining_svp,3)
FROM players_goalieratings
WHERE season=$CURRENT_SEASON AND stage=$CURRENT_STAGE AND games > 6
ORDER BY rating DESC
});
	if ($auto_convert) {
		for my $row (@{$goalies}) {
			convert_ids_to_names([0], 'players', $row);
		}
	}
	unshift(@{$goalies}, [qw|Player xSVP SVP Elo xSVP(Rem)|]);
	$goalies;
}

sub get_current_teams (;$) {

	my $auto_convert = shift || 0;
	$DB  ||= Sport::Analytics::NHL::DB->new();
	$SQL ||= Sport::Analytics::NHL::SQL->new();

	my $teams = $SQL->selectall_arrayref(qq{
SELECT team, ROUND(rating,0), points, span_games, span_totalpts
FROM teams_eloseason
WHERE span='season'
ORDER BY conference DESC, division ASC, span_totalpts DESC
});
	if ($auto_convert) {
		for my $row (@{$teams}) {
			$row->[0] = get_team_name_at_season($row->[0], $CURRENT_SEASON);
		}
	}
	unshift(@{$teams}, [qw|Team Elo Pts rGm xPt|]);
	splice(@{$teams},  9, 0, [('--') x 5]);
	splice(@{$teams}, 18, 0, [('--') x 5]);
	splice(@{$teams}, 26, 0, [('--') x 5]);
	$teams;
}

sub get_points_projections (;$) {

	my $auto_convert = shift || 0;
	$DB  ||= Sport::Analytics::NHL::DB->new();
	$SQL ||= Sport::Analytics::NHL::SQL->new();

	my $current_points = $SQL->selectall_hashref(qq{
SELECT _player, _team, _position, (GOALS+ASSISTS) as points, games_played
FROM skater_stats
}, [qw(_team _player)]);
	my $today = strftime("%Y%m%d", localtime);
	my @h_a = qw(away home);
	my $pp = {};
	my $schedule_c = $DB->get_collection('schedule');
	my $players_c  = $DB->get_collection('players');
	my $schedule_i = $schedule_c->find({date => {'$gte' => $today+0}});
	while (my $game = $schedule_i->next()) {
		my $t = 0;
		for my $h_a (@h_a) {
			my $team = $game->{$h_a};
			my $_team = $game->{$h_a[1-$t]};
			my $_t = 2-$t;
			for my $players (values %{$current_points->{$team}}) {
				my $p = $players->{_player};
				$CACHES->{players}{$p} ||=  $players_c->find_one({_id => $p+0});
				next unless $CACHES->{players}{$p}{active};
				$CACHES->{xpoints}{$_team}{$p}{$_t} ||= $SQL->selectrow_arrayref(qq{
SELECT (GOALS+ASSISTS) as points
FROM skater_expectations
WHERE _team='$_team' AND _player = $p AND _home_away = $_t
})->[0];
				my $xpoints = $CACHES->{xpoints}{$_team}{$p}{$_t};
				$pp->{$p} ||= {
					player   => $CACHES->{players}{$p}{name},
					position => $players->{_position},
					team     => $team,
					games    => $players->{games_played},
					points   => $players->{points},
					xpoints  => 0,
					xg       => 0,
				};
				$pp->{$p}{xpoints} += $xpoints;
				$pp->{$p}{xg}++;
			}
			$t++;
		}
	}
#	print Dumper $pp;
#	exit;
	my $r = 0;
	my $points_table = [
		map {
			[
				++$r,
				$_->{player}, $_->{position}, $_->{team},
				$_->{games},  $_->{points},
				sprintf("%2.3f", $_->{xpoints} / $_->{xg}),
				sprintf("%2.1f", $_->{xpoints} + $_->{points}),
			];
		} sort {
			($b->{xpoints} + $b->{points}) <=> ($a->{xpoints}+$a->{points})
		} values %{$pp}
	];
	splice(@{$points_table}, 50);
	unshift(@{$points_table}, ['#', qw(Player Pos TEAM GP P xPt/g xPts)]);
	$points_table;
}

sub get_optimal_score ($$$) {

	my $game      = shift;
	my $t         = shift;
	my $players_c = shift;

	my @h_a = qw(away home);
	my @players = $players_c->find({
		team => $game->{$h_a[$t]}, active => 1, injury_status => 'OK',
		position => { '$ne' => 'G' },
	})->all();
	my @sd = ([], []);
	my $o = $h_a[1-$t];
	my $h = 2-$t;
	for my $player (@players) {
		my $sd = $player->{position} eq 'D' ? 1 : 0;
		my $goals = $SQL->selectall_arrayref(qq{
SELECT _player, GOALS
FROM skater_expectations
WHERE _player = $player->{_id} AND _team = '$game->{$o}' AND _home_away = $h
});
		next unless defined $goals->[0];
		push(@{$sd[$sd]}, $goals->[0]);
	}
	$sd[0] = [ sort { ($b->[1] || 0) <=> ($a->[1] || 0) } @{$sd[0]} ];
	$sd[1] = [ sort { ($b->[1] || 0) <=> ($a->[1] || 0) } @{$sd[1]} ];

	splice(@{$sd[0]}, 12);
	splice(@{$sd[1]}, 6);
	sum map($_->[1], @{$sd[0]}, @{$sd[1]});
}

sub update_daily_results ($$$$) {

	my $game  = shift;
	my $score = shift;
	my $table = shift;
	my $today = shift;

	$SQL->do(qq{DELETE FROM daily_results WHERE game_id = $game->{game_id}});
	$SQL->do(qq{INSERT INTO daily_results VALUES(
$CURRENT_SEASON, $game->{ts}, $game->{date}, $game->{game_id},
'$game->{home}', '$game->{away}', $score->[1], $score->[0], NULL, NULL
)});
	return if $game->{date} != $today;
	my $chance = $score->[0] / ($score->[0] + $score->[1]);
	my $c1 = $chance*100; my $c2 = (1-$chance)*100;
	my $_away = get_team_full_name_at_season($game->{away}, $CURRENT_SEASON);
	my $_home = get_team_full_name_at_season($game->{home}, $CURRENT_SEASON);
	$SQL->do(qq{INSERT INTO daily_summary_games VALUES(
$game->{game_id},
'$_away', $score->[0], $c1, $c2, $score->[1], '$_home', 0
)});
	verbose sprintf "$game->{away} %.3f %.1f - %.1f %.3f $game->{home}\n",
		$score->[0],
		$chance*100, (1-$chance)*100,
		$score->[1];
	push(@{$table}, [
		$game->{away}, $score->[0],
		$chance*100, (1-$chance)*100,
		$score->[1], $game->{home}
	]);
}

sub produce_daily_games (;$$$) {

	my $today        = shift || strftime("%Y%m%d",localtime());
	my $this_game    = shift || '';
	my $no_propagate = shift || 0;

	$DB  ||= Sport::Analytics::NHL::DB->new();
	$SQL ||= Sport::Analytics::NHL::SQL->new();

	$SQL->do(qq{TRUNCATE TABLE daily_summary_games});
	my $table = [];
	my $players_c = $DB->get_collection('players');
	my $schedule_c = $DB->get_collection('schedule');
	my $schedule_i = $schedule_c->find({date => { '$gte' => $today+0}});
	while (my $game = $schedule_i->next()) {
		next if $this_game && $game->{game_id} != $this_game;
		verbose "Predicting results: $game->{_id}";
		my $score = [];
		for my $t (0,1) {
			$score->[$t] = get_optimal_score($game, $t, $players_c);
		}
		if ($this_game) {
			print sprintf "$game->{away} %.3f - %.3f $game->{home}\n",
				$score->[0],
				$score->[1];
			return [];
		}
		return $table if ($game->{date} > $today && $no_propagate);
		update_daily_results($game, $score, $table, $today);
	}
	$table;
}

sub restart_hypnotoad (;$) {

	my $pid_file = shift || '/home/romm/RP/hockeydb/html/hypnotoad.pid';
	return unless -f $pid_file;

	my $pid = qx(cat $pid_file); chomp $pid;
	system(qq(sudo kill -USR2 $pid));
}

=over 2

=item C<fix_playergoals>

Fixes the number of goals and assists for players in the boxscore as shown by the summary.

Arguments:
 * The boxscore
 * The index of the team of the player (0 - away, 1 - home)
 * The event summary

Returns: void. Boxscore is modified.

=back

=cut

sub fix_playergoals ($$$) {

	my $boxscore      = shift;
	my $t             = shift;
	my $event_summary = shift;

	for my $player (@{$boxscore->{teams}[$t]{roster}}) {
		if (my $es = $event_summary->{$player->{_id}}) {
			$player->{goals} = $es->{goals};
			$player->{assists} = $es->{assists};
		}
	}
}

=over 2

=item C<print_events>

Prints the list of parsed events in a compact for. Work in progress. Do not use.

=back

=cut

sub print_events ($) {

	my $events = shift;

	for (@{$events}) {
		$_->{t} = -1 unless exists $_->{t};
		$_->{ts} ||= get_seconds($_->{time});
		print "$_->{game_id}\t$_->{period}\t$_->{t}\t$_->{ts}\t$_->{type}\n";
	}
}

sub get_team_name_at_season ($$) {

	my $team   = shift;
	my $season = shift;

	if (ref $TEAM_FULL_NAMES{$team}) {
		my $default = $TEAM_FULL_NAMES{$team}->{default};
		for my $year (sort keys %{$TEAM_FULL_NAMES{$team}}) {
			next if $year eq 'default';
			return $TEAM_FULL_NAMES{$team}->{$year} if $season < $year;
		}
		return $default;
	}
	else {
		return $TEAMS{$team}->{full}[0] if $TEAMS{$team};
		for my $k (keys %TEAMS) {
			return $k if $k eq $team;
			for my $s (1..@{$TEAMS{$k}->{short}}) {
				return $TEAMS{$k}->{full}[$s] || $TEAMS{$k}->{full}[0]
					if $s eq $team;
			}
		}
	}
	confess "Couldn't resolve full name for team $team" unless $TEAM_FULL_NAMES{$team};
	$TEAM_FULL_NAMES{$team};
}

sub get_team_full_name_at_season ($$) {

	my $team   = shift;
	my $season = shift;

	my $team_name = $team;
	if ($TEAMS{$team}->{timeline}) {
		V3:
		for my $v (keys %{$TEAMS{$team}->{timeline}}) {
			if ($TEAMS{$team}->{timeline}{$v}[0] <= $season &&
					$TEAMS{$team}->{timeline}{$v}[1] >= $season) {
				$team_name = $v;
				last V3;
			}
		}
	}
	get_team_name_at_season($team_name, $season) || $TEAMS{$team}->{full}[0];
}

sub prepare_seasonteams_cache () {

	$DB  ||= Sport::Analytics::NHL::DB->new();

	return if $CACHES->{seasonteams};

	my $seasons_c     = $DB->get_collection('seasons');
	my $conferences_c = $DB->get_collection('conferences');
	my $divisions_c   = $DB->get_collection('divisions');

	for my $season_db ($seasons_c->find()->all()) {
		for my $conference (@{$season_db->{conferences}}) {
			my $conference_db = $conferences_c->find_one({_id => $conference});
			for my $division (@{$conference_db->{divisions}}) {
				my $division_db = $divisions_c->find_one({_id => $division});
				for my $team (@{$division_db->{teams}}) {
					my $_team = resolve_team($team);
					$CACHES->{seasonteams}{$season_db->{year}}{$_team} = [
						$conference_db->{name},
						$division_db->{name},
						$_team,
						$team,
						get_team_full_name_at_season($_team, $season_db->{year}),
					];
				}
			}
		}
	}
}

sub get_team_conference ($$) {

	my $team   = shift;
	my $season = shift;

	prepare_seasonteams_cache() unless $CACHES->{seasonteams};
	return $CACHES->{seasonteams}{$season}{$team}[0]
		if $CACHES->{seasonteams}{$season}{$team};
	print STDERR "NHL Conference for team $team not found, assuming PCHA\n";
	if ($TEAMS{$team}) {
		$CACHES->{seasonteams}{$season}{$team} =
			[ 'PCHA', 'PCHA', $team, $team, $TEAMS{$team}->{full}[0] ];
		return $CACHES->{seasonteams}{$season}{$team}[0];
	}
	print STDERR "Team $team is not configured";
	return undef;
}

sub generate_player_lookup_table () {

	$DB  ||= Sport::Analytics::NHL::DB->new();
	$SQL ||= Sport::Analytics::NHL::SQL->new();
	$SQL->do(qq{
CREATE TABLE IF NOT EXISTS player_lookup(
  p          INT(7)      NOT NULL DEFAULT 0,
  p_name     VARCHAR(40) NOT NULL DEFAULT 'UNKNOWN',
  p_team     VARCHAR(3)  NOT NULL DEFAULT 'NHL',
  p_position VARCHAR(1)  NOT NULL DEFAULT 'S',
  p_status   SMALLINT(1) NOT NULL DEFAULT 0,
  p_injury   VARCHAR(10) NOT NULL DEFAULT 'OK',
  PRIMARY KEY(p)
);
        });
	my $players_c = $DB->get_collection('players');
	my $players_i = $players_c->find();
	my $sth = $SQL->{dbh}->prepare(qq{
REPLACE INTO player_lookup (p, p_name, p_team, p_position, p_status, p_injury)
VALUES(?,?,?,?,?, ?)
        });
	while (my $player = $players_i->next()) {
		debug "Adding player $player->{_id}";
		$sth->execute(@{$player}{qw(_id name team position active injury_status)});
	}
}

sub generate_coach_lookup_table () {

	$DB  ||= Sport::Analytics::NHL::DB->new();
	$SQL ||= Sport::Analytics::NHL::SQL->new();
	$SQL->do(qq{
CREATE TABLE IF NOT EXISTS coach_lookup(
  c          VARCHAR(32) NOT NULL,
  c_name     VARCHAR(40) NOT NULL DEFAULT 'UNKNOWN',
  PRIMARY KEY(c)
);
        });
	my $coaches_c = $DB->get_collection('coaches');
	my $coaches_i = $coaches_c->find();
	my $sth = $SQL->{dbh}->prepare(qq{
REPLACE INTO coach_lookup (c, c_name)
VALUES(?,?)
        });
	while (my $coach = $coaches_i->next()) {
		debug "Adding coach $coach->{_id}";
		$sth->execute(@{$coach}{qw(_id name)});
	}
}

sub execute_templated_table_query ($$) {

	my $query = shift;
	my $opts  = shift;

	$query =~ s/_KEY_/$opts->{key}/ge if $opts->{popup};
	$query =~ s/_LIMIT_/$opts->{query_limit}/ge;
	my $table = $SQL->selectall_arrayref($query);
	if (defined $opts->{convert_indices}) {
		for my $row (@{$table}) {
			convert_ids_to_names(
				$opts->{convert_indices}, $opts->{convert_collection}, $row
			);
		}
	}
	$table;
}

sub get_daily_coaches_f2f (;$$) {

	my $auto_convert = shift || 0;
	my $date         = shift || strftime("%Y%m%d",localtime);
	$DB  = Sport::Analytics::NHL::DB->new();
	$SQL = Sport::Analytics::NHL::SQL->new();

	my $coaches_c  = $DB->get_collection('coaches');
	my $f2f = [];
	my $games = [get_games_for_dates($date)];
	for my $game (@{$games}) {
		my $coach_away = reduce {
			my $a_team = (sort {
				$b->{start} <=> $a->{start}
			} grep { $_->{team} eq $game->{away} } @{$a->{teams}})[0];
			my $b_team = (sort {
				$b->{start} <=> $a->{start}
			} grep { $_->{team} eq $game->{away} } @{$b->{teams}})[0];
			$a_team->{end} > $b_team->{end} ? $a : $b
		} $coaches_c->find({team => $game->{away}, name => {
			'$ne' => 'UNKNOWN COACH',
		}})->all();
		my $coach_home = reduce {
			my $a_team = (sort {
				$b->{start} <=> $a->{start}
			} grep { $_->{team} eq $game->{home} } @{$a->{teams}})[0];
			my $b_team = (sort {
				$b->{start} <=> $a->{start}
			} grep { $_->{team} eq $game->{home} } @{$b->{teams}})[0];
			$a_team->{end} > $b_team->{end} ? $a : $b
		} $coaches_c->find({team => $game->{home}})->all();
		my $query = qq{
SELECT coach1,sum(wins),sum(losses),coach2
FROM coaches_face2face
WHERE stage=0 AND (coach1='$coach_away->{_id}' AND coach2='$coach_home->{_id}')
};
		my $f2f_row = $SQL->selectall_arrayref($query);
		push(
			@{$f2f},
			$f2f_row->[0][0] ?
				$f2f_row->[0] : [ $coach_away->{_id}, '-', '-', $coach_home->{_id} ],
		);
	}
	if ($auto_convert) {
		for my $row (@{$f2f}) {
			convert_ids_to_names([0,3], 'coaches', $row);
		}
	}
	$SQL->do(qq{TRUNCATE TABLE daily_summary_coaches});
	for my $game (@{$f2f}) {
		$game->[1] = "'-'" if $game->[1] eq '-';
		$game->[2] = "'-'" if $game->[2] eq '-';
		$SQL->do(qq{
INSERT INTO daily_summary_coaches VALUES(
"$game->[0]", $game->[1], $game->[2], "$game->[3]"
)
            });
		$game->[1] =~ s/\'//g;
		$game->[2] =~ s/\'//g;
	}
	$f2f;
}

sub build_crosstable_standings ($) {

	my $played  = shift;

	my $standings = {};
	my $games_c = $DB->get_collection('games');
	my $games_i = $games_c->find({season => $CURRENT_SEASON, stage => $REGULAR});
	prepare_seasonteams_cache() unless $CACHES->{seasonteams};
	while (my $game = $games_i->next()) {
		$played->{$game->{_id}} = 1;
		for my $t (0,1) {
			my $team = $game->{teams}[ $t ]{name};
			my $opp  = $game->{teams}[1-$t]{name};
			my $result = $game->{result}[$t]; $result = 2 if $result > 2;
			$standings->{$team}{games}{$opp}++;
			$standings->{$team}{results}{$opp} += $result;
			$standings->{$team}{pts} += $result;
			$standings->{$team}{gms}++;
			$standings->{$team}{conference} = $CACHES->{seasonteams}{$CURRENT_SEASON}{$team}[0];
			$standings->{$team}{division} = $CACHES->{seasonteams}{$CURRENT_SEASON}{$team}[1]; 
		}
	}
	$standings;
}

sub build_expected_schedule ($$) {

	my $standings = shift;
	my $played    = shift;

	my $schedule_c = $DB->get_collection('schedule');
	my $schedule_i = $schedule_c->find({
		season => $CURRENT_SEASON, stage => $REGULAR
	});
	my $elo = $SQL->selectall_hashref(qq{
SELECT team, rating FROM teams_eloseason
}, 'team');
	while (my $game = $schedule_i->next()) {
		next if $played->{$game->{game_id}};
		$standings->{$game->{home}}{remaining}{$game->{away}}++;
		$standings->{$game->{away}}{remaining}{$game->{home}}++;
	}
	my $ppg = {};
	for my $team (keys %{$standings}) {
		for my $opp (keys %{$standings->{$team}{remaining}}) {
			my $expected = hexpected($elo->{$opp}{rating} - $elo->{$team}{rating});
#			print Dumper $expected, $standings
			$standings->{$team}{rempoints}{$opp} =
				$standings->{$team}{remaining}{$opp}*$expected;
		}
		$ppg->{$team} = $standings->{$team}{pts} / $standings->{$team}{gms};
	}
	$ppg;
}

sub init_crosstable_rankings ($$) {

	my $standings = shift;
	my $ppg       = shift;

	my $crosstable = {points => [], games => [], remaining => [], rempoints => []};
	my $ranking = {};
	my $t = 1;
	for my $team (sort {
		$standings->{$a}{conference} cmp $standings->{$b}{conference} ||
			$standings->{$a}{division}   cmp $standings->{$b}{division}   ||
			$ppg->{$b} <=> $ppg->{$a} || $standings->{$b}{pts} <=> $standings->{$a}{pts}
        } keys %{$ppg}) {
		$ranking->{$team} = $t;
		$crosstable->{points}[$t-1] = [$team];
		$crosstable->{games}[$t-1]  = [$team];
		$crosstable->{rempoints}[$t-1] = [$team];
		$crosstable->{remaining}[$t-1]  = [$team];
		$t++;
	}
	($crosstable, $ranking);
}

sub crosstable_fill_xo ($) {

	my $crosstable = shift;

	for my $type (keys %{$crosstable}) {
		my $table = $crosstable->{$type};
		for my $r (0..$#{$table}) {
			for my $c (1..@{$table}) {
				unless ($table->[$r][$c]) {
					$table->[$r][$c] = $c == $r+1 ? 'X' : 0;
				}
			}
		}
	}
}

sub create_match_crosstable () {

	$DB  ||= Sport::Analytics::NHL::DB->new();
	$SQL ||= Sport::Analytics::NHL::SQL->new();

	my $played = {};
	my $standings = build_crosstable_standings($played);
	my $ppg = build_expected_schedule($standings, $played);
	my ($crosstable, $ranking) = init_crosstable_rankings($standings, $ppg);
	my $t = 0;
	for my $team ( sort { $ranking->{$a} <=> $ranking->{$b} } keys %{$ranking}) {
		for my $opp (keys %{$standings->{$team}{games}}) {
			$crosstable->{games}[$t][$ranking->{$opp}]  =
				$standings->{$team}{games}{$opp};
			$crosstable->{points}[$t][$ranking->{$opp}] =
				$standings->{$team}{results}{$opp};
		}
		for my $opp (keys %{$standings->{$team}{remaining}}) {
			$crosstable->{remaining}[$t][$ranking->{$opp}] =
				$standings->{$team}{remaining}{$opp};
			$crosstable->{rempoints}[$t][$ranking->{$opp}] =
				$standings->{$team}{rempoints}{$opp};
		}
		$t++;
	}
	crosstable_fill_xo($crosstable);
	$crosstable;
}

sub calculate_pick_adjustment ($$$) {

	my $pick   = shift;
	my $season = shift;
	my $year   = shift;

	my $adjustment = 1;
	if ($year) {
		my $career_year = $season - $year + 1;
		if ($career_year < 4) {
			$adjustment = $career_year / 4;
		}
		elsif ($career_year > 16) {
			$adjustment = ($career_year - 20) / 4;
			$adjustment = -0.25 if $adjustment > -0.25;
		}
	}
	$adjustment;
}

sub compute_teams_elo (;$) {

	my $season = shift || $CURRENT_SEASON;
	$SQL ||= Sport::Analytics::NHL::SQL->new();

	my $start_date = $season . '1001';
	my $elo_history = $SQL->selectall_arrayref(qq{
SELECT * FROM history_teams_elo
WHERE date >= $start_date
ORDER by date ASC
});
	my $teams_elo = {};
        prepare_seasonteams_cache() unless $CACHES->{seasonteams};
	for my $row (@{$elo_history}) {
		my $team = $row->[1];
		$CACHES->{team_divisions}{$team} ||=
			$CACHES->{seasonteams}{$CURRENT_SEASON}{$team}[1];
		$teams_elo->{$CACHES->{team_divisions}{$team}}{max} ||= 0;
		$teams_elo->{$CACHES->{team_divisions}{$team}}{min} ||= 3000;
		$teams_elo->{$CACHES->{team_divisions}{$team}}{$team} ||= [
			{
				elo => $START_RATING,
				date => $start_date, ts => str2time($start_date)
			},
		];
		push(
			@{$teams_elo->{$CACHES->{team_divisions}{$team}}{$team}},
			{
				date => $row->[0], ts => str2time($row->[0]),
				elo => $row->[2],
			},
		);
#		print "$CACHES->{team_divisions}{$team} $row->[2] $teams_elo->{$CACHES->{team_divisions}{$team}}{max}\n";
		if ($row->[2] > $teams_elo->{$CACHES->{team_divisions}{$team}}{max}) {
			$teams_elo->{$CACHES->{team_divisions}{$team}}{max} = $row->[2];
		}
		if ($row->[2] < $teams_elo->{$CACHES->{team_divisions}{$team}}{min} ) {
			$teams_elo->{$CACHES->{team_divisions}{$team}}{min} = $row->[2];
		}
	}
	$teams_elo;
}

sub generate_prediction_summary () {

	$DB  ||= Sport::Analytics::NHL::DB->new();
	$SQL ||= Sport::Analytics::NHL::SQL->new();

	my $results = $SQL->selectall_hashref(qq{
SELECT * FROM daily_results
WHERE season = $CURRENT_SEASON AND actual_home IS NOT NULL
}, 'game_id');
	my $summary;
	my @outcomes = qw(losses wins total);
	for my $result (values %{$results}) {
		my $outcome;
		if (($result->{predicted_home} > $result->{predicted_away})	^
			($result->{actual_home} > $result->{actual_away})) {
			$outcome = 0;
		}
		else {
			$outcome = 1;
		}
		my $r0 = $result->{actual_home} > $result->{actual_away} ? 1 : 0;
		my $p0 = $result->{predicted_home} / (
			$result->{predicted_home} + $result->{predicted_away}
		);
		my $p1 = 1 - $p0;
		my $r1 = 1 - $r0;
		my $log_loss = -($r0*log($p0) + ($r1*log($p1)));
		my $month = 'm' . substr($result->{date}, 4, 2);
		my $round = 'r' . substr($result->{game_id}, 6, 1);
		my $week  = time2str('%W', str2time($result->{date}));
		$week -= 38;
		$week += 52 if $week < 0;
		for my $count ($outcome,2) {
			for my $span (($result->{date}, $week, $round, 'season')) {
#			for my $span (($result->{date}, $week, $month, 'season')) {
				$summary->{$span}{$outcomes[$count]}++;
				$summary->{$span}{$outcomes[1-$count]} ||= 0;
			}
		}
		for my $span (($result->{date}, $week, $round, 'season')) {
#		for my $span (($result->{date}, $week, $month, 'season')) {
			$summary->{$span}{logloss} += $log_loss;
		}
	}
	for my $span (keys %{$summary}) {
		$summary->{$span}{logloss} /= $summary->{$span}{total};
	}

	$summary;
}

sub get_divs_cons_standings (;$) {

	my $season = shift || $CURRENT_SEASON;

	$DB = Sport::Analytics::NHL::DB->new();
	my $games_c = $DB->get_collection('games');
	my $games_i = $games_c->find({season => $season+0, stage => $REGULAR});

	my $divs = {};
	my $cons = {};

	prepare_seasonteams_cache() unless $CACHES->{seasonteams};
	while (my $game = $games_i->next()) {
		my $ta = $game->{teams}[0]{name};
		my $th = $game->{teams}[1]{name};

		for my $t ($ta, $th) {
			my $cd = $CACHES->{seasonteams}{$CURRENT_SEASON}{$t};
			$CACHES->{teams}{conferences}{$t} = $cd->[0];
			$CACHES->{teams}{divisions}{$t}   = $cd->[1];
		}

		my $da = $CACHES->{teams}{divisions}{$ta};
		my $dh = $CACHES->{teams}{divisions}{$th};
		next if $da eq $dh;
		my $ra = $game->{result}[0] == 2
			? 3 - $game->{result}[1]
			: $game->{result}[0];
		my $rh = 3 - $ra;
		$divs->{$da}{$dh} ||= [0,0,0,0];
		$divs->{$da}{$dh}[$rh]++;
		$divs->{$dh}{$da} ||= [0,0,0,0];
		$divs->{$dh}{$da}[$ra]++;

		my $ca = $CACHES->{teams}{conferences}{$ta};
		my $ch = $CACHES->{teams}{conferences}{$th};
		next if $ca eq $ch;
		$cons->{$ca}{$ch} ||= [0,0,0,0];
		$cons->{$ca}{$ch}[$ra]++;
		$cons->{$ch}{$ca} ||= [0,0,0,0];
		$cons->{$ch}{$ca}[$rh]++;
	}
	($divs, $cons);
}

sub format_divs_crosstable ($) {

	my $divs = shift;

	my $scores = {};
	for my $d1 (keys %{$divs}) {
		$scores->{$d1} = 0;
		for my $d2 (keys %{$divs->{$d1}}) {
			$scores->{$d1} +=
				$divs->{$d1}{$d2}[0]*2 +
				$divs->{$d1}{$d2}[1]*2 +
				$divs->{$d1}{$d2}[2];
		}
	}
	my @sorted_divs = sort { $scores->{$b} <=> $scores->{$a} } keys %{$divs};
	my $divs_table = [ ['Division', map(substr($_, 0, 7), @sorted_divs), 'Points' ] ];
	my $d = 0;
	for my $d1 (@sorted_divs) {
		push(
			@{$divs_table},
			[ $d1, ]
		);
		for my $d2 (@sorted_divs) {
			if ($d1 eq $d2) {
				push(@{$divs_table->[-1]}, 'XXXXXXX');
			}
			else {
				push(@{$divs_table->[-1]}, join('-', @{$divs->{$d1}{$d2}}));
			}
		}
		push(@{$divs_table->[-1]}, $scores->{$d1});
	}
	$divs_table;
}

sub get_gamestamp ($) {

	my $event = shift;

	$DB ||= Sport::Analytics::NHL::DB->new();
	my $games_c = $DB->get_collection('games');

	my $game = $games_c->find_one({_id => $event->{game_id} + 0});
	my $eventid = substr($event->{_id}, 4);
	my $seconds = get_seconds($event->{time}) + ($event->{period}-1)*1200;
	my $timestamp = sprintf("%02d:%02d", $seconds / 60, $seconds % 60);
	if ($event->{t}) {
		$game->{teams}[1]{name} = b($game->{teams}[1]{name});
	}
	else {
		$game->{teams}[0]{name} = b($game->{teams}[0]{name});
	}
	substr($game->{date},6,0) = '/';
	substr($game->{date},4,0) = '/';
	my $gamestamp = "$game->{date}: $game->{teams}[0]{name} at $game->{teams}[1]{name} @ $timestamp";
	$gamestamp;
}

sub generate_season_density ($$) {

	my $season  = shift;
	my $games_c = shift;

	my @games = sort { $a->{start_ts} <=> $b->{start_ts} } $games_c->find({
		season => $season+0, stage => $REGULAR
	})->fields({result => 1, start_ts => 1, "teams.name" => 1})->all();
	my $w = -1;
	my $min_count = 0;
	my $data = {};
	my $W = 0;
	my $points = 0; my $games = 0;

	while (my $game = shift @games) {
		my $gW = time2str("%W", $game->{start_ts});
		if ($gW != $w) {
			if ($min_count) {
				for my $team (keys %{$data}) {
					$points += $data->{$team}{points};
					$games  += $data->{$team}{games};
				}
				my $average = $points / $games;
				for my $team (keys %{$data}) {
					$data->{$team}{ppg} =
						$data->{$team}{points} / $data->{$team}{games};
					$data->{$team}{delta} = sprintf(
						"%d", sprintf("%.2f", ($data->{$team}{ppg} - $average)*100)/5
					);
					$SQL->{dbh}->do(qq{
INSERT INTO history_standings VALUES(
$season, $W, '$team', $data->{$team}{ppg}, $data->{$team}{delta}
);
});
				}
				$SQL->{dbh}->do(qq{
INSERT INTO history_standings VALUES(
$season, $W, 'NHL', $average, 0
);
});
			}
			$W++;
			debug "Standings Density: Season $season / week $W";
			$w = $gW;
			$min_count = 1;
		}
		for my $t (0,1) {
			my $team = $game->{teams}[$t]{name};
			$data->{$team}{points} += $game->{result}[$t];
			$data->{$team}{games}++;
		}
	}
}

sub generate_density_sql ($) {

	my $opts = shift;

	$DB  ||= Sport::Analytics::NHL::DB->new();
	$SQL ||= Sport::Analytics::NHL::SQL->new();

	my @seasons = parse_start_stop_opts($opts);
	my $self = {
		sql_table => 'history_standings',
		sql_table_def => qq{
season SMALLINT(4) NOT NULL DEFAULT 0,
week   SMALLINT(2) NOT NULL DEFAULT 0,
team   VARCHAR(3)  NOT NULL DEFAULT '',
ppg    FLOAT(8,7)  NOT NULL DEFAULT 0,
delta  SMALLINT(2) NOT NULL DEFAULT 0,
PRIMARY KEY(season, week, team)
}
	};
	create_table_func($self);
	$SQL->do(q{TRUNCATE TABLE history_standings});
	my $games_c =  $DB->get_collection('games');
	for my $season (@seasons) {
		generate_season_density($season, $games_c);
	}
}

sub get_min_max_hash ($$) {

	my $hash  = shift;
	my $field = shift;

	my $max = -1E15;
	my $min = 1E15;
	for my $key (keys %{$hash}) {
		if ($max < $hash->{$key}{$field}) {
			$max = $hash->{$key}{$field}
		}
		if ($min > $hash->{$key}{$field}) {
			$min = $hash->{$key}{$field}
		}
	}
	($min, $max);
}

sub bucket_density_teams ($$) {

	my $teams = shift;
	my $min   = shift;

	my $scale = [];
	for my $team (keys %{$teams}) {
		my $idx = $teams->{$team}{delta} - $min;
		$scale->[$idx] ||= [];
		my $i = 0;
		while (
			$scale->[$idx][$i] &&
			$scale->[$idx][$i]{ppg} < $teams->{$team}{ppg}
		) {
			$i++;
		}
		splice(@{$scale->[$idx]}, $i, 0, $teams->{$team});
	}
	$scale;
}

sub generate_density_animation ($) {

	my $opts = shift;

	my @seasons = parse_start_stop_opts($opts);
	my @weeks   = parse_start_stop_opts($opts, 'week');

	my $endweeks;
	$SQL ||= Sport::Analytics::NHL::SQL->new();
	if ($opts->{end}) {
		$endweeks =  $SQL->selectall_hashref(qq{
SELECT season, MAX(week) AS week
FROM history_standings
GROUP BY season
}, 'season');
	}
	my $sdata = $SQL->selectall_hashref(qq{
SELECT season, team, ppg, delta, week
FROM history_standings
}, ['season', 'week', 'team']);
	my @images;
	my $X = 680; my $Y = 400; my $margin = $Y / 10;
	for my $season (@seasons) {
		next if grep { $_ eq $season } @LOCKOUT_SEASONS;
		@weeks = ($endweeks->{$season}{week}) if $opts->{end};
#		print Dumper $endweeks, \@weeks;
		for my $week (@weeks) {
			next unless $sdata->{$season}{$week};
			my $data = $sdata->{$season};
			verbose "Density animation: $season, Week $week";
			my ($min, $max) = get_min_max_hash($data->{$week}, 'delta');
			my $scale = bucket_density_teams($data->{$week}, $min);
			my $image = init_density_image({
				x => $X, y => $Y,  margin => $margin,
			}, $season, $week);
			my $x_graph = $X - 2*$margin;
			my $spread  = $max - $min;
			my $maxradius = $x_graph / (2*$spread);
			for my $l ($min .. $max) {
				my $s = $l - $min;
				my $x = $margin + $s*$x_graph/$spread;
				make_hash_mark($image, $x, $Y-$margin);
				make_hash_mark($image, $x, $Y-$margin+3, {
					length => 2*$margin-$Y
				}) unless $l;
				if ($scale->[$s] && @{$scale->[$s]}) {
					plot_bucket(
						$image, $scale->[$s], {
							maxradius => $maxradius,
							x => $x, y => $Y-$margin-2,
							margin => $margin,
						}
					);
				}
			}
			push(@images, "frame-$season-$week.gif");
			$image->Write("frame-$season-$week.gif");
		}
	}
	combine_animation(
		{ delay => 100, output => 'density-animation.gif', cleanup => 1 },
		@images,
	);
}

sub aggregate_season_shots_by_periods ($;$) {

	my $season = shift;
	my $opts   = shift;

	my $invert    = $opts->{shots}     || 0;
	my $break     = $opts->{break}     // undef;
	my $gamecount = $opts->{gamecount} || 0;
	my $goals     = $opts->{goals}     || 0;

	$invert = 1 if $invert;
	$DB ||= Sport::Analytics::NHL::DB->new();

	die "Data is not available before 1997\n" if $season < 1997;
	my $games_c = $DB->get_collection('games');
	my $games_i = $games_c->find({
		season => $season+0,
		stage  => $REGULAR,
	});
	my $shots = {};
	my $counts = {};
	while (my $game = $games_i->next()) {
		gamedebug $game, "Shots by period";
		$counts->{$game->{teams}[$_]{name}} ||= 0 for 0, 1;
		for my $period (@{$game->{periods}}) {
			next if $period->{id} > 4;
			my $p = $period->{id};
			$shots->{$game->{teams}[0]{name}} ||= [];
			for my $_p (0, $p) {
				for my $t (0, 1) {
					next if defined $break && $game->{break}[$t] != $break;
					next if defined $gamecount
						&& $counts->{$game->{teams}[$t]{name}} > $gamecount;
					$shots->{$game->{teams}[$t]{name}}[$_p]
						+= $period->{score}[$t+1+$invert-2*$t*$invert];
					$shots->{$game->{teams}[$t]{name}}[$_p+5]
						+= $period->{score}[3*($t^$invert)]
						if $goals;
				}
			}
		}
		$shots->{$game->{teams}[0]{name}}[5]++ if defined $break && $game->{break}[0] == $break;
		$shots->{$game->{teams}[1]{name}}[5]++ if defined $break && $game->{break}[1] == $break;
		$counts->{$game->{teams}[$_]{name}}++ for 0, 1;
	}
	$shots;
}

sub produce_shots_faceoffs ($$) {

	my $game = shift;
	my $team = shift;

	my $h_a = $game->{teams}[0]{name} eq $team ? '@' : ' ';
	my $opp = $game->{teams}[0]{name} eq $team ?  1  :  0;
	my @teams;
	my @sf = ((0) x 4);
	for my $t (0,1) {
		$teams[$t] =
			get_team_full_name_at_season($game->{teams}[$t]{name}, $game->{season});
		my $_t = $t == $opp ? 1 : 0;
		for my $player (@{$game->{teams}[$t]{roster}}) {
			$sf[$_t] += $player->{SHOTS} if defined $player->{SHOTS};
			$sf[2+$_t] += $player->{FACEOFFWINS} if defined $player->{FACEOFFWINS};
		}
	}
	(
		$game->{date}, $h_a, $teams[$opp],
		@sf,
	);
}

sub produce_3stars ($$) {

	my $game = shift;
	my $team = shift;

	my $h_a = $game->{teams}[0]{name} eq $team ? '@' : ' ';
	my $opp = $game->{teams}[0]{name} eq $team ?  1  :  0;

	my $path = get_game_path_from_id($game->{_id});
	my $file = "$path/GS.storable";
	my $boxscore;
	if (-f $file) {
		$boxscore = retrieve $file;
	}
	else {
		$file = "$path/BS.json";
		my $json = read_file($file);
		$boxscore = decode_json($json);
	}
	my @s3 = (('n/a') x 12);
	my $s = 0;
	if ($file =~ /GS/) {
		for my $star (@{$boxscore->{stars}}) {
		    next unless $star->{name};
			$s3[$s]   = (split(/ /,$star->{name}))[-1];
			$s3[$s] = 'KRONWALL' if $s3[$s] eq 'KRONVALL';
			$star->{position} = 'G' if $s3[$s] eq 'BACASHIHUA';
			if (! $star->{position}) {
				for my $t (0,1) {
					for my $player (@{$game->{teams}[$t]{roster}}) {
						if ($player->{number} == $star->{number} &&
								$player->{name} =~ /\b$s3[$s]\b/
							) {
							$star->{position} = $player->{position};
							last;
						}
					}
				}
			}
			if (! $star->{position}) {
				for my $t (0,1) {
					for my $player (@{$game->{teams}[$t]{roster}}) {
						if ($player->{name} =~ /\b$s3[$s]\b/) {
							$star->{number} = $player->{number};
							$star->{position} = $player->{position};
							last;
						}
					}
				}
			}
			unless ($star->{position}) {
				die Dumper $star, \@s3;
			}
			$s3[$s+1] = $star->{position};
			$s3[$s+2] = $star->{number};
			$s3[$s+3] = $star->{team};
			$s += 4;
		}
	}
	else {
		my $decisions = $boxscore->{liveData}{decisions};
		for my $startype (qw(firstStar secondStar thirdStar)) {
			my $star = $decisions->{$startype};
			if ($star->{id}) {
				my $_team; my $_position; my $_number;
				for my $t (0,1) {
					for my $player (@{$game->{teams}[$t]{roster}}) {
						if ($player->{_id} == $star->{id}) {
							$_team = $game->{teams}[$t]{name};
							$_position = $player->{position};
							$_number = $player->{number};
							last;
						}
					}
				}
				unless ($_team) {
					if ($star->{id} == 8462082) {
						$_team = 'COL';
				}
					else {
						die Dumper $star;
					}
				}
				$s3[$s] = (split(/ /, uc $star->{fullName}))[-1];
				$s3[$s+1] = $_position;
				$s3[$s+2] = $_number;
				$s3[$s+3] = $_team;
			}
			$s += 4;
		}
	}
	my $_opp =
		get_team_full_name_at_season($game->{teams}[$opp]{name}, $game->{season});
	[
		$game->{date}, $h_a, $_opp,
		@s3,
	];
}

sub get_goalie_periods ($) {

	my $goalie = shift;

	my @periods = ((0) x 8);
	if ($goalie->{SHOT1}) {
		for my $i (1..10) {
			my $field = "SHOT$i";
			if ($goalie->{$field}) {
				my $j = $i > 3 ? 3 : $i-1;
				$periods[2*$j] = $goalie->{$field}[0];
				$periods[2*$j+1] = $goalie->{$field}[1];
			}
		}
	}
	elsif ($goalie->{p1}) {
		for my $i (1..10) {
			my $field = "p$i";
			if ($goalie->{$field}) {
				my $j = $i > 3 ? 3 : $i-1;
				$goalie->{$field} =~ /(\d+)-(\d+)/;
				$periods[2*$j]   = $1;
				$periods[2*$j+1] = $2;
			}
		}
	}
	$periods[6] ||= 0;
	$periods[7] ||= 0;
	@periods;
}

sub produce_goalies ($$) {

	my $game = shift;
	my $team = shift;

	my $h_a = $game->{teams}[0]{name} eq $team ? '@' : ' ';
	my $opp = $game->{teams}[0]{name} eq $team ?  1  :  0;
	my $opp_team = get_team_full_name_at_season(
		$game->{teams}[$opp]{name}, $game->{season},
	);
	my $path = get_game_path_from_id($game->{_id});
	my $file = "$path/GS.storable";
	my $boxscore;
	if (-f $file) {
		$boxscore = retrieve $file;
		if (! @{$boxscore->{goalies}}) {
			$file = "$path/ES.storable";
			if (-f $file) {
				$boxscore = retrieve $file;
			}
		}
	}
	if (! $boxscore) {
		$file = "$path/BS.json";
		my $json = read_file ($file);
		$boxscore = decode_json($json);
	}
	my @entries;
	if ($file =~ /GS/ || $file =~ /ES/) {
		debug "Using $file";
		GOALIE:
		for my $goalie (@{$boxscore->{goalies}}) {
			$goalie->{name} =~ /\b(\S+)$/;
			$goalie->{name} = $1;
			for my $player (@{$game->{teams}[1-$opp]{roster}}) {
				if ($player->{timeonice}
						&& $player->{position} eq 'G'
						&& (
							$player->{name} =~ /\b$goalie->{name}\b/
#							|| (
#								$goalie->{number}
#								&& $player->{number} == $goalie->{number}
#							)
						)
				) {
					my @periods = get_goalie_periods($goalie);
					push(@entries, [
						#date name h/a opponent
						$game->{date}, $player->{name}, $h_a, $opp_team,
						@periods,
						#total,
						0,0,
						#svp
						0,
						# GS
						0,
						# E/P/S goals
						(map {
							my $sa = $player->{$_ . 'shotsagainst'};
							my $ss;
							if (defined $sa) {
								my $sv = $player->{$_ . 'saves'} || 0;
								$ss = $sa - $sv;
							}
							else {
								$ss = 'n/a';
							}
							$ss;
						} qw(even powerplay shorthanded)),
						# TOI, decision
						$goalie->{timeOnIce}, $goalie->{decision} || 'N',
					]);
					next GOALIE;
				}
			}
		}
	}
	else {
		for my $player (@{$game->{teams}[1-$opp]{roster}}) {
			next unless $player->{position} eq 'G' && $player->{timeonice} > 0;
			push(@entries, [
				$game->{date}, $player->{name}, $h_a, $opp_team,
				(0,0) x 4,
				$player->{shots} - $player->{saves},
				$player->{shots},
				0,0,
				(map {
					my $sa = $player->{$_ . 'shotsagainst'};
					my $ss;
					if (defined $sa) {
						my $sv = $player->{$_ . 'saves'} || 0;
						$ss = $sa - $sv;
					}
					else {
						$ss = 'n/a';
					}
					$ss;
				} qw(even powerplay shorthanded)),
				$player->{timeonice}, $player->{decision}
			]);
		}
	}
	if (@entries > 1) {
		my $extra_entry = dclone $entries[-1];
		for my $i (4..19) {
			for my $j (0..@entries-2) {
				$extra_entry->[$i] += $entries[$j]->[$i]
					unless $entries[$j]->[$i] eq 'n/a';
			}
		}
		$extra_entry->[1] = 'TOTAL';
		push(@entries, $extra_entry);
	}
	for my $entry (@entries) {
		$entry->[-2] = get_log_time($entry->[-2]);
		if ($file =~ /GS/) {
			$entry->[12] = $entry->[4] + $entry->[6] + $entry->[8] + $entry->[10];
			$entry->[13] = $entry->[5] + $entry->[7] + $entry->[9] + $entry->[11];
		}
		$entry->[14] = $entry->[13] ? ($entry->[13]-$entry->[12]) / $entry->[13] : 0;
	}
	$entries[-1]->[15] = $game->{teams}[1-$opp]{score};
	die "Cannot be empty\n" unless @entries;
	@entries;
}

sub get_log_toi ($$) {
	my $player = shift;
	my $type   = shift;

	my $toi_field = $type . 'TIMEONICE';
	return '--:--' unless defined $player->{$toi_field};
	get_time($player->{$toi_field});
}

sub get_log_ss ($$) {
	my $player = shift;
	my $type   = shift;

	my $sh_field = $type . 'shots';
	$sh_field .= 'against' if $type;
	my $sa_field = $type . 'saves';
	return '-' unless defined $player->{$sh_field};
	"$player->{$sa_field}-$player->{$sh_field}";
}

sub produce_playerlogs ($$) {

	my $game = shift;
	my $team = shift;

	my $h_a = $game->{teams}[0]{name} eq $team ? '@' : ' ';
	my $opp = $game->{teams}[0]{name} eq $team ?  1  :  0;
	my @teams;
	my @entries = ();
	for my $t (0,1) {
		$teams[$t] = get_team_full_name_at_season($game->{teams}[$t]{name}, $game->{season});
		my @headers = ();
		for my $player ( sort {
			$POSITION_ORDER{$a->{position}} <=>	$POSITION_ORDER{$b->{position}}
				or
			$a->{number} <=> $b->{number}
		} @{$game->{teams}[$t]{roster}}) {
			if (! $headers[$POSITION_ORDER{$player->{position}}]) {
				$headers[$POSITION_ORDER{$player->{position}}] = 1;
				push(@entries, $TEAM_COMMANDS{playerlogs}{headers}[
					$POSITION_ORDER{$player->{position}}
				]);
			}
			if ($POSITION_ORDER{$player->{position}} == 3) {
				push(
					@entries, [
						$teams[$t],	$player->{number}, $player->{name},
						map(
							get_log_ss($player,$_),
							qw(even powerplay shorthanded), ''
						),
						$player->{shots} ?
							$player->{saves} / $player->{shots} : '-',
						$player->{pim} || $player->{penaltyminutes},
						get_log_time($player->{timeonice}),
					]
				);
			}
			else {
				push(
					@entries, [
						$teams[$t],	$player->{number}, $player->{name},
						$player->{GOALS},
						$player->{ASSISTS},
						$player->{GOALS}+$player->{ASSISTS},
						$player->{PLUSMINUS},
						$player->{PENALTYMINUTES},
						$player->{SHOTS},
						$player->{HITS} // '-',
						$player->{BLOCKED} // '-',
						$player->{GIVEAWAYS} // '-',
						$player->{TAKEAWAYS} // '-',
						$player->{FACEOFFTAKEN} ?
							$player->{FACEOFFPCT} : '-',
						map(
							get_log_toi($player, $_),
							'', qw(POWERPLAY SHORTHANDED),
						),
					]
				);
			}
		}
	}
	@entries;
}

sub produce_goallogs ($$) {

	my $game = shift;
	my $team = shift;

	my $h_a = $game->{teams}[0]{name} eq $team ? '@' : ' ';
	my $opp = $game->{teams}[0]{name} eq $team ?  1  :  0;
	my @teams;

	my @entries;
	my $GOAL_c = $DB->get_collection('GOAL');
	my $players_c = $DB->get_collection('players');
	my $GOAL_i = $GOAL_c->find({game_id => $game->{_id}})->sort({ts => 1});
	my $g = 1;
	my $strengths = get_catalog_map('strengths');
	$CACHES->{players} ||= {};
	while (my $goal = $GOAL_i->next()) {
		my $strength = (grep {
			$strengths->{$_} eq $goal->{strength}
		} keys %{$strengths})[0];
		my @involved;
		for my $id ($goal->{player1}, $goal->{assist1}, $goal->{assist2}) {
			unless ($id) {
				push(@involved, undef);
				next;
			}
			$CACHES->{players}{$id} ||= $players_c->find_one({_id => $id+0});
			push(@involved, $CACHES->{players}{$id}->{name});
		}
		my $on_ice_stl = join(',', @{$goal->{on_ice}[$opp]}) if $goal->{on_ice} && $goal->{on_ice}[1-$opp];
		my $on_ice_opp = join(',', @{$goal->{on_ice}[$opp]}) if $goal->{on_ice} && $goal->{on_ice}[$opp];
		push(@entries, [
			$game->{date},
			$h_a,
			$g,
			$goal->{period},
			$goal->{time},
			$strength,
			get_team_full_name_at_season($goal->{team1}, $game->{season}),
			@involved,
			$on_ice_stl,
			$on_ice_opp,
		]);
		$g++;
	}
#	print Dumper \@entries;
#	exit;
	@entries;
}

sub produce_gamelogs ($$) {

	my $game = shift;
	my $team = shift;

	my $h_a = $game->{teams}[0]{name} eq $team ? '@' : ' ';
	my $opp = $game->{teams}[0]{name} eq $team ?  1  :  0;
	my @teams;
	my $PENL_c = $DB->get_collection('PENL');
	my @entries = ();
	for my $t (0,1) {
		$teams[$t] =
			get_team_full_name_at_season($game->{teams}[$t]{name}, $game->{season});
	}
	my @totals = ();
	$totals[4] = 'TOT';
	my $PENL_i = $PENL_c->find({game_id => $game->{_id}});
	my @penls = ([]);
	while (my $penl = $PENL_i->next()) {
		my $t = $penl->{t};
		next if $t == -1;
		my $p = $penl->{period};
		$penls[$p] ||= [];
		$penls[$p][$t*2]++;
		$penls[$p][$t*2+1] += $penl->{length};
		$penls[0][$t*2]++;
		$penls[0][$t*2+1] += $penl->{length};
	}
	for my $period (@{$game->{periods}}) {
		next if $period->{id} == 5 and $game->{stage} == $REGULAR;
		push(
			@entries,
			[
				$game->{date}, $h_a, $teams[$opp], $period->{id},
				$period->{score}[3*$opp],
				$game->{season} > 1996 ? $period->{score}[1+$opp] : '-',
				$penls[$period->{id}][$opp*2] || 0,
				$penls[$period->{id}][$opp*2+1] || 0,
				$period->{id},
				$period->{score}[3*(1-$opp)],
				$game->{season} > 1996 ? $period->{score}[2-$opp] : '-',
				$penls[$period->{id}][(1-$opp)*2] || 0,
				$penls[$period->{id}][(1-$opp)*2+1] || 0,
			]
		);
		$totals[0] += $period->{score}[3*$opp];
		$totals[5] += $period->{score}[3*(1-$opp)];
		$totals[1] += $game->{season} > 1996 ? $period->{score}[1+$opp] : 0;
		$totals[6] += $game->{season} > 1996 ? $period->{score}[2-$opp] : 0;
	}
	$totals[2] = $penls[0][$opp*2]       || 0;
	$totals[3] = $penls[0][$opp*2+1]     || 0;
	$totals[7] = $penls[0][(1-$opp)*2]   || 0;
	$totals[8] = $penls[0][(1-$opp)*2+1] || 0;
	$totals[1] ||= '-';
	$totals[6] ||= '-';
	push(
		@entries,
		[ $game->{date}, $h_a, $teams[$opp], 'TOT', @totals ],
	);
	@entries;
}

sub produce_comebacks ($$) {

	my $game = shift;
	my $team = shift;

	my $h_a = $game->{teams}[0]{name} eq $team ? '@' : ' ';
	my $opp = $game->{teams}[0]{name} eq $team ?  1  :  0;

	$TGC++;
	$SGC++;
	my $GOAL_c    = $DB->get_collection('GOAL');
	my $players_c = $DB->get_collection('players');
	my @entries = ();
	my $GOAL_i = $GOAL_c->find({
		game_id => $game->{_id}+0,
		so => 0,
	});
	my $g = 0;
	my $count = {
		$team => 0,
		opp   => 0,
	};
	my $result =
		$game->{result}[0] == $game->{result}[1] ? 'T'
		: $game->{result}[$opp] == 0             ? 'W'
		: $game->{result}[$opp] == 1             ? ($game->{so} ? 'SW' : 'OW')
		: $game->{result}[1-$opp] == 0           ? 'L'
		: $game->{so}                            ? 'SL' : 'OL';

	my $opponent = get_team_full_name_at_season(
		$game->{teams}[$opp]{name}, $game->{season}
	);
	while (my $goal = $GOAL_i->next()) {
		for my $field (qw(player1 assist1 assist2)) {
			next unless $goal->{$field};
			$CACHES->{players}{$goal->{$field}} ||=
				$players_c->find_one({_id => $goal->{$field}+0});
		}
		$count->{$goal->{team1} eq $team ? $team : 'opp'}++;
		my $entry = [
			$TGC, $SGC, $game->{stage}, $game->{date},
			$h_a, $opponent, ++$g, $goal->{period}, $goal->{time},
			$CACHES->{strength}{$goal->{strength}},
			get_team_full_name_at_season($goal->{team1}, $goal->{season}),
			$CACHES->{players}{$goal->{player1}}{name},
			$goal->{assist1} ? ($CACHES->{players}{$goal->{assist1}}{name}) : (''),
			$goal->{assist2} ? ($CACHES->{players}{$goal->{assist2}}{name}) : (''),
			$count->{$team}, $count->{opp}, $result, $count->{$team} - $count->{opp},
		];
		push(@entries, $entry);
	}
	@entries;
}

sub produce_pp2 ($$;$) {

	my $game = shift;
	my $team = shift;
	my $opts = shift || {};

	my $h_a = $game->{teams}[0]{name} eq $team ? '@' : ' ';
	my $opp = $game->{teams}[0]{name} eq $team ?  1  :  0;
	my $t_t = 1 - $opp;

	$TGC++;
	$SGC++;
	my $str_c     = $DB->get_collection('str');
	my $PENL_c    = $DB->get_collection('PENL');
	my $players_c = $DB->get_collection('players');

	my $query = {
		game_id => $game->{_id} + 0,
		$opts->{invert}
			? ("on_ice.$opp" => 5,"on_ice.$t_t" => 3,)
			: ("on_ice.$opp" => 3,"on_ice.$t_t" => 5,),
	};
#	print Dumper $query;
	my $str_i = $str_c->find($query);
	my $opponent = get_team_full_name_at_season(
		$game->{teams}[$opp]{name}, $game->{season}
	);
	my @entries;
	while (my $str = $str_i->next()) {
		my @penl = $PENL_c->find({
			game_id => $game->{_id} + 0,
			'$or' => [
				{length => 2}, {length => 5},
			],
			ts => {
				'$lte' => $str->{from},
			},
			finish => {
				'$gt' => $str->{from},
			},
			substituted => { '$ne' => 1 },
		})->all();
		my $pbox = '';
		for my $p (@penl) {
			$CACHES->{players}{$p->{player1}} ||=
				$players_c->find_one({_id => $p->{player1}});
			if ($CACHES->{players}{$p->{player1}}) {
				$pbox .= "$CACHES->{players}{$p->{player1}}{name}($p->{length}) ";
			}
			elsif ($p->{servedby}) {
				$CACHES->{players}{$p->{servedby}} ||=
					$players_c->find_one({_id => $p->{servedby}});
				$pbox .= "$CACHES->{players}{$p->{servedby}}{name}}($p->{length}s) ";
			}
		}
		chop $pbox;
		my $entry = [
			$TGC, $SGC, $game->{stage}, $game->{date},
			$h_a, $opponent, $str->{from}, $str->{to}, $str->{length},
			$pbox, scalar(@{$str->{scored}}),
		];
		push(@entries, $entry);
	}
#	print Dumper \@entries;
#	exit if @entries;
	@entries;
}

sub commit_active_streaks ($$;$$) {

	my $opts   = shift;
	my $data   = shift;
	my $season = shift || '';
	my $stage  = shift || '';

	$opts->{streak_field} ||= 'games';
	my @active_streakers = keys %{$opts->{streaks}};
	for my $id (@active_streakers) {
		if ($opts->{streaks}{$id}{$opts->{streak_field}} >= $opts->{duration}) {
			$CACHES->{players}{$id} ||= $DB
				->get_collection('players')->find_one({	_id => $id+0 });
			my $arr;
			if ($season) {
				$arr = $stage ? $data->{$season}{$stage} : $season;
			}
			else {
				$arr = $data->{data};
			}
			push(
				@{$arr},
				[
					$season ? $season : (),
					$stage  ? $stage : (),
					$CACHES->{players}{$id}{name},
					$opts->{streaks}{$id}{start},
					$opts->{streaks}{$id}{end},
					$opts->{streaks}{$id}{games},
					$opts->{streaks}{$id}{count},
				]
			);
		}
		delete $opts->{streaks}{$id};
	}
}

sub produce_playerstreak ($$;$) {

	my $game = shift;
	my $team = shift;
	my $opts = shift;

	my $players_c = $DB->get_collection('players');
	my $roster = $game->{teams}[$game->{teams}[0]{name} eq $team ? 0 : 1]{roster};
	$opts->{threshold} ||= 1;
	my @entries;
	for my $player (@{$roster}) {
		$player->{POINTS} ||= $player->{GOALS} + $player->{ASSISTS}
			if defined $player->{GOALS} && defined $player->{ASSISTS};
		next unless defined $player->{$opts->{event_type}};
		my $id = $player->{_id};
		if ($player->{$opts->{event_type}} >= $opts->{threshold}) {
			if ($opts->{streaks}{$id}) {
#				debug "extending streak for $id on $game->{date}" if $id == 8446187;
				$opts->{streaks}{$id}{games}++;
				$opts->{streaks}{$id}{count} += $player->{$opts->{event_type}};
				$opts->{streaks}{$id}{end} = $game->{date};
			}
			else {
#				debug "starting streak for $id on $game->{date}" if $id == 8446187;
				$opts->{streaks}{$id} = {
					count => $player->{$opts->{event_type}},
					games => 1,
					start => $game->{date},
					end   => $game->{date},
					name  => $id,
				}
			}
		}
		else {
			next unless $opts->{streaks}{$id};
			if ($opts->{streaks}{$id}{games} >= $opts->{duration}) {
				$CACHES->{players}{$id} ||= $DB
					->get_collection('players')->find_one({	_id => $id+0 });
				push(
					@entries, [
						$game->{season},
						$game->{stage},
						$CACHES->{players}{$id}{name},
						$opts->{streaks}{$id}{start},
						$opts->{streaks}{$id}{end},
						$opts->{streaks}{$id}{games},
						$opts->{streaks}{$id}{count},
					],
				);
			}
			delete $opts->{streaks}{$id};
		}
	}
	(@entries);
}

sub produce_pgstreak ($$;$) {

	my $game = shift;
	my $team = shift;
	my $opts = shift;

	$opts->{streaks}   ||= {};
	$opts->{streak_field} = 'count';
	$opts->{commit_by_season} = 1;

	my $GOAL_c = $DB->get_collection('GOAL');
	my $players_c = $DB->get_collection('players');
	my $GOAL_i = $GOAL_c->find({game_id => $game->{_id}})->sort({ts => 1});
	my $roster = $game->{teams}[$game->{teams}[0]{name} eq $team ? 0 : 1]{roster};

	my @entries;
	my $_cache = {};
	while (my $goal = $GOAL_i->next()) {
		next if $goal->{team1} ne $team;
		my $streakon = {};
		for my $field (qw(player1 assist1 assist2)) {
			next unless $goal->{$field};
			my $id = $goal->{$field};
			if ($opts->{streaks}{$id}) {
				$opts->{streaks}{$id}{games}++ unless $_cache->{$id};
				$opts->{streaks}{$id}{count}++;
				$opts->{streaks}{$id}{end} = $game->{date};
			}
			else {
				$opts->{streaks}{$id} = {
					count => 1,
					games => 1,
					start => $game->{date},
					end   => $game->{date},
					name  => $id,
				}
			}
			$streakon->{$id} = 1;
			$_cache->{$id} = 1;
		}
		for my $player (@{$roster}) {
			my $p = $player->{_id};
			next if $streakon->{$p};
			next unless $opts->{streaks}{$p};
			unless ($opts->{streaks}{$p}{count} >= $opts->{duration}) {
				delete $opts->{streaks}{$p};
				next;
			}
			push(
				@entries, [
					$game->{season},
					$player->{name},
					$opts->{streaks}{$p}{start},
					$opts->{streaks}{$p}{end},
					$opts->{streaks}{$p}{games},
					$opts->{streaks}{$p}{count},
				],
			);
			delete $opts->{streaks}{$p};
		}
	}
	@entries;
}

sub produce_eventdrought ($$;$) {

	my $game = shift;
	my $team = shift;
	my $opts = shift;

	my $h_a = $game->{teams}[0]{name} eq $team ? '@' : ' ';
	my $opp = $game->{teams}[0]{name} eq $team ?  1  :  0;
	my $opponent = get_team_full_name_at_season(
		$game->{teams}[$opp]{name}, $game->{season}
	);

	$TGC++;
	$SGC++;

	my $collection = $DB->get_collection($opts->{event_type});
	my @events = $collection->find({game_id => $game->{_id}})->all();
	if ($collection eq 'SHOT') {
		push(
			@events,
			$DB->get_collection('GOAL')->find({game_id => $game->{_id}})->all(),
		);
	}
	push(
		@events,
		$DB->get_collection('GEND')->find({game_id => $game->{_id}})->all(),
	);
	@events = sort { $a->{ts} <=> $b->{ts} } @events;
	my $stretch = 0;
	my @entries;
	$opts->{invert} ||= 0;
	for my $event (@events) {
		next unless ($event->{t} != $opp) ^ $opts->{invert};
		if ($event->{ts} - $stretch > $opts->{duration}*60) {
			push(
				@entries, [
					$TGC, $SGC, $game->{date},
					$h_a, $opponent,
					$opts->{event_type}, map(
						get_log_time($_),
						$stretch, $event->{ts}, $event->{ts} - $stretch
					),
				]
			);
		}
		$stretch = $event->{ts};
	}
	@entries;
}

sub produce_psgstreak ($$;$) {

	my $game = shift;
	my $team = shift;
	my $opts = shift;

	$opts->{streaks}   ||= {};
	$opts->{commit_by_total} = 1;
	my $players_c = $DB->get_collection('players');
	my $roster = $game->{teams}[$game->{teams}[0]{name} eq $team ? 0 : 1]{roster};
	$opts->{threshold} ||= 1;
	my @entries;
	for my $player (@{$roster}) {
		next unless defined $player->{$opts->{event_type}};
		my $id = $player->{_id};
		if ($player->{$opts->{event_type}} >= $opts->{threshold}) {
			if ($opts->{streaks}{$id}) {
				$opts->{streaks}{$id}{games}++;
				$opts->{streaks}{$id}{count} += $player->{$opts->{event_type}};
				$opts->{streaks}{$id}{end} = $game->{date};
				print "extending streak for $id on $game->{date} ($opts->{streaks}{$id}{count}/$opts->{streaks}{$id}{games})\n" if $id == 8452086;
			}
			else {
				$opts->{streaks}{$id} = {
					count => $player->{$opts->{event_type}},
					games => 1,
					start => $game->{date},
					end   => $game->{date},
					name  => $id,
				};
				print "starting streak for $id on $game->{date} ($opts->{streaks}{$id}{count}/$opts->{streaks}{$id}{games})\n" if $id == 8452086;
			}
		}
		else {
			next unless $opts->{streaks}{$id};
				print "stopping streak for $id on $game->{date} ($opts->{streaks}{$id}{count}/$opts->{streaks}{$id}{games})\n" if $id == 8452086;
			if ($opts->{streaks}{$id}{games} >= $opts->{duration}) {
				$CACHES->{players}{$id} ||= $DB
					->get_collection('players')->find_one({	_id => $id+0 });
				push(
					@entries, [
						$CACHES->{players}{$id}{name},
						$opts->{streaks}{$id}{start},
						$opts->{streaks}{$id}{end},
						$opts->{streaks}{$id}{games},
						$opts->{streaks}{$id}{count},
					],
				);
			}
			delete $opts->{streaks}{$id};
		}
	}
	(@entries);
}

sub produce_sogcounts ($$) {

	my $game = shift;
	my $team = shift;

	my $h_a = $game->{teams}[0]{name} eq $team ? '@' : ' ';
	my $opp = $game->{teams}[0]{name} eq $team ?  1  :  0;
	my $opponent = get_team_full_name_at_season(
		$game->{teams}[$opp]{name}, $game->{season}
	);

	$TGC++;
	$SGC++;
	my $players_c = $DB->get_collection('players');
	my $counts = {d => 0, f => 0, ds => 0, fs => 0};
	for my $player (@{$game->{teams}[1-$opp]{roster}}) {
		for ($player->{position}) {
			when ('G') {;}
			when ('D') { $counts->{d}++; $counts->{ds}++ if $player->{SHOTS}};
			default    { $counts->{f}++; $counts->{fs}++ if $player->{SHOTS}};
		}
	}
	$counts->{s}  = $counts->{d}  + $counts->{f};
	$counts->{ss} = $counts->{ds} + $counts->{fs};
	my $entry = [
		$TGC, $SGC, $game->{stage}, $game->{date},
		$h_a, $opponent,
		$counts->{f}, $counts->{fs}, sprintf("%.1f", 100*$counts->{fs}/$counts->{f})+0,
		$counts->{d}, $counts->{ds}, sprintf("%.1f", 100*$counts->{ds}/$counts->{d})+0,
		$counts->{s}, $counts->{ss}, sprintf("%.1f", 100*$counts->{ss}/$counts->{s})+0,
	];
	($entry);
}

sub produce_shootouts ($$) {

	my $game = shift;
	my $team = shift;

	my $h_a = $game->{teams}[0]{name} eq $team ? '@' : ' ';
	my $opp = $game->{teams}[0]{name} eq $team ?  1  :  0;
	my $opponent = get_team_full_name_at_season(
		$game->{teams}[$opp]{name}, $game->{season}
	);
	$SGC++;
	return unless $game->{so};
	my $so_file = make_game_path(
		$game->{season}, $game->{stage}, $game->{season_id},
	) . '/SO.html';
#	print Dumper $so_file;
#	exit;
	my $so_html;
	if (! -f $so_file) {
		my $url = sprintf(
			$Sport::Analytics::NHL::Scraper::HTML_REPORT_URL,
			$game->{season}, $game->{season} + 1, 'SO',
			$game->{stage}, $game->{season_id},
		);
		$so_html = Sport::Analytics::NHL::Scraper::scrape({url => $url});
		write_file($so_html, $so_file);
	}
	else {
		$so_html = read_file($so_file);
	}
	my $te = HTML::TableExtract->new();
	$te->parse($so_html);
	my $so = [];
	my @events;
	for (qw(GOAL SHOT MISS)) {
		my $coll = $DB->get_collection($_);
		push(
			@events,
			$coll->find({
				game_id => $game->{_id},
				stage => $REGULAR,
				period => 5,
			})->all(),
		);
	}
	return unless @events;
#	@events = sort {$a->{_id} <=> $b->{_id}} @events;
	my @entries;
	my $players_c = $DB->get_collection('players');
	my $score = [0,0];
	my $goalies = [];
	for my $event (@events) {
		if ($event->{player2} && ! $goalies->[1-$event->{t}]) {
			$goalies->[1-$event->{t}] = $event->{player2};
		}
		$score->[$event->{t}]++ if $event->{type} eq 'GOAL';
#		print "E $event->{description}\n";
	}
	my $loser_tally = $score->[0] < $score->[1] ? $score->[0] : $score->[1];
	foreach my $ts ($te->tables) {
		if (@{$ts->rows} >= 5) {
#			print "Table (", join(',', $ts->coords), "):\n";
		}
		foreach my $row ($ts->rows) {
			$row = [ map {$_ ||= ''} @{$row}] ;
#			print join(',', @$row), "\n";
			if ($row->[0] =~ /^\d/) {
				if ($row->[3] =~ /^(\d+)\s+(\S+)/i) {
					push(
						@{$so},
						[ $row->[0], $1, $row->[1], $2, ]
					);
				}
				else {
					push(
						@{$so},
						[ $row->[0], $row->[1], $row->[3], $row->[4] ]
					);
				}
			}
		}
	}
	$score = [0,0];
	for my $event (@events) {
		$CACHES->{players}{$event->{player1}} =
			$players_c->find_one({_id => $event->{player1}})
			if ! $CACHES->{players}{$event->{player1}};
		if (! $event->{player2}) {
			if ($event->{on_ice} && @{$event->{on_ice}} &&
					@{$event->{on_ice}[1-$event->{t}]}) {
				if (@{$event->{on_ice}[1-$event->{t}]} > 1) {
					die Dumper $event->{on_ice};
				}
				$event->{player2} = $event->{on_ice}[1-$event->{t}][0];
			}
			elsif ($goalies->[1-$event->{t}]) {
				$event->{player2} = $goalies->[1-$event->{t}];
			}
			else {
				my @goalies = grep {
					$_->{position} eq 'G'
				} @{$game->{teams}[1-$event->{t}]{roster}};
				$event->{player2} = $goalies[0]->{_id};
			}
		}
		$CACHES->{players}{$event->{player2}} =
			$players_c->find_one({_id => $event->{player2}})
			if ! $CACHES->{players}{$event->{player2}};
		my $so_id;
		SO:
		for my $so_row (@{$so}) {
			next if $so_row->[4];
			my $_team = resolve_team($so_row->[2]);
			next if $_team ne $event->{team1};
			my $t = $_team eq $game->{teams}[0]{name}
				? 0 : $_team eq $game->{teams}[1]{name}
				? 1 : die $_team;
			for my $p (@{$game->{teams}[$t]{roster}}) {
				if ($p->{_id} == $CACHES->{players}{$event->{player1}}{_id}
						&& $p->{number} == $so_row->[1]) {
#					print "$CACHES->{players}{$event->{player1}}{name} T $t PN $p->{number}=$so_row->[1] SO $so_row->[0]\n";
					$so_id = $so_row->[0];
					$so_row->[4] = 1;
					last SO;
				}
			}
		}
		die unless $so_id;
		$event->{so_id} = $so_id;
	}
	@events = sort {$a->{so_id} <=> $b->{so_id}} @events;
	for my $event (@events) {
		my $result = substr($event->{type}, 0, 1);
		my $idx = 1-($opp ^ $event->{t});
		$score->[$idx] += $result eq 'G' ? 1 : 0;
		my $gwg;
		if ($result eq 'G' && $score->[$idx] == $loser_tally+1) {
			$gwg = 'X';
		}
		else {
			$gwg = '';
		}
		my $entry = [
			$SGC, $game->{date},
			$h_a, $opponent,
			$event->{so_id},
			$game->{teams}[$event->{t}]{name},
			$CACHES->{players}{$event->{player1}}{name},
			$CACHES->{players}{$event->{player2}}{name},
			$result,
			"$score->[0]-$score->[1]",
			$gwg,
		];
		push(@entries, $entry);
	}
	@entries;
}

sub produce_team_data ($$$) {

	my $opts    = shift;
	my $team    = shift;
	my $command = shift;
	my $data = {};

	$DB ||= Sport::Analytics::NHL::DB->new();
	my $games_c = $DB->get_collection('games');
	my @seasons = $opts->{season}
		? ($opts->{season})
		: (
			($opts->{start_season} || $TEAMS{$team}->{founded}) ..
			($opts->{stop_season}  || $TEAMS{$team}->{folded} || $CURRENT_SEASON)
		);
	my @stages  = $opts->{stage}
		? ($opts->{stage})
		: ($REGULAR, $PLAYOFF);
	my $method = "produce-$command";
	$method =~ s/\-/\_/g;
	if ($TEAM_COMMANDS{$command}->{condition}) {
		for my $value (values %{$TEAM_COMMANDS{$command}->{condition}}) {
			if ($value =~ /\%s/) {
				$value = sprintf($value, $team);
			}
		}
	}
	my %res = %{ get_catalog_map('strengths') };
	$CACHES->{strength} = {reverse %res };
	for my $season (@seasons) {
		$SGC = 0;
		for my $stage (@stages) {
			my $count = $games_c->count_documents({
				season => $season,
				stage  => $stage,
				'teams.name' => $team,
			});
			next unless $count;
			my $games_i = $games_c->find({
				season => $season,
				stage  => $stage,
				'teams.name' => $team,
				$TEAM_COMMANDS{$command}->{condition}
					? %{$TEAM_COMMANDS{$command}->{condition}}
					: (),
			});
			while (my $game = $games_i->next()) {
				gamedebug $game;
				no strict 'refs';
				my @entries = $method->($game, $team, $opts);
				use strict;
				if ($TEAM_COMMANDS{$command}->{level} eq 'career') {
					$data->{data} ||= [];
					push(@{$data->{data}}, @entries);
				}
				elsif ($TEAM_COMMANDS{$command}->{level} eq 'season') {
					if ($opts->{commit_by_season}) {
						$data->{$season} ||= [];
						push(@{$data->{$season}}, @entries);
					}
					else {
						$data->{$season}{$stage} ||= [];
						push(@{$data->{$season}{$stage}}, @entries);
					}
				}
				elsif ($TEAM_COMMANDS{$command}->{level} eq 'game') {
					$data->{$season}{$stage}{$game->{_id}} ||= [
						"$game->{date}-$game->{teams}[0]{name}-$game->{teams}[1]{name}.csv"
					];
					push(@{$data->{$season}{$stage}{$game->{_id}}}, @entries);
				}
			}
			if (! $opts->{commit_by_season} && ! $opts->{commit_by_total}) {
				commit_active_streaks($opts, $data, $season, $stage);
			}
		}
		if ($opts->{commit_by_season}) {
			commit_active_streaks($opts, $data, $season);
		}
	}
#	print Dumper $opts->{streaks};
	if ($opts->{commit_by_total}) {
		commit_active_streaks($opts, $data);
	}
	$data->{header} = $TEAM_COMMANDS{$command}->{header};
	$data;
}

sub svp_vs_shots () {

	$DB ||= Sport::Analytics::NHL::DB->new();
	my $games_c = $DB->get_collection('games');

	my $data = [];
	my $games_i = $games_c->find({ season => { '$gte' => 1998,  '$lte' => 2017 }});
	while (my $game = $games_i->next()) {
		gamedebug $game, 'svp-shots';
		for my $t (0,1) {
			my $shots = 0;
			my $saves = 0;
			for my $player (@{$game->{teams}[$t]{roster}}) {
				next if $player->{position} ne 'G';
				$shots += $player->{shots};
				$saves += $player->{saves};
			}
			$data->[$shots] ||= { count => 0, saves => 0 };
			$data->[$shots]{count}++;
			$data->[$shots]{saves} += $saves;
			print "$shots $saves ", $saves/$shots, "\n" if $shots;
		}
	}
	my $d = -1;
	for my $item (@{$data}) {
		$d++;
		next unless $item && $d;
		print "$d,$item->{count},", $item->{saves}/($item->{count}*$d), "\n";
	}
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
