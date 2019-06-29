package Sport::Analytics::NHL::DB;

use strict;
use warnings FATAL => 'all';

use Carp;
use POSIX;

use MongoDB::OID;
use List::MoreUtils qw(firstval);
use Tie::IxHash;
use boolean;

use Sport::Analytics::NHL::Config qw(:basic $EMPTY_NET_ID %TEAMS %SEASONS);
use Sport::Analytics::NHL::Vars qw(:globals :mongo :basic);
use Sport::Analytics::NHL::Util qw(:debug :format :utils);

use parent 'Exporter';

our @EXPORT = qw(ensure_index insert update);

use Data::Dumper;

use if ! $ENV{HOCKEYDB_NODB} && $MONGO_DB, 'MongoDB';
use if ! $ENV{HOCKEYDB_NODB} && $MONGO_DB, 'BSON::OID';
use if ! $ENV{HOCKEYDB_NODB} && $MONGO_DB, 'MongoDB::MongoClient';

=head1 NAME

Sport::Analytics::NHL::DB - Interface to MongoDB to store NHL reports.

=head1 SYNOPSYS

Interface to MongoDB in order to store the semi-structured NHL reports into it. Provides the database handle and most of the bulky database operations. Does not subclass MongoDB - the handle is stored in the class's object.

    use Sport::Analytics::NHL::DB;
    my $db = Sport::Analytics::NHL::DB->new();
    my $team_id = $db->resolve_team_db('San Jose Sharks'); # $team_id becomes 'SJS'.

=head1 METHODS

=over 2

=item C<new>

 Constructor. Sets the database connection. Controlled by global variables:
  * $MONGO_HOST - host of the mongodb server (def. 127.0.0.1)
  * $MONGO_PORT - port of the mongodb server (def. 27017)
  * $MONGO_DB   - name of the mongo database (def 'hockey')
  Also, the database can be specified via $ENV{HOCKEYDB_DBNAME}

 The database handle is stored in the dbh field of the object which is a blessed hashref.

=item C<resolve_team_db>

 Resolves a team by a given possible identifier to a normalized 3-letter identifier. The target identifiers are the keys to the %TEAMS hash in Sport::Analytics::NHL::Config.pm (q.v.)
 Argument: the team identifier/name (e.g. 'Rangers')
 Returns: the system identifier (e.g. NYR)

=item C<insert_schedule>

 Inserts the collected schedule (see Sport::Analytics::NHL::Scraper), initializing the indexes for the schedule collection if necessary.
 Collections: schedule
 Arguments: the list of scheduled games with their defined fields
 Returns: the number of the inserted games

=item C<get_existing_game_ids>

 Gets the list of ids of games already in the database
 Collections: games
 Arguments: optional - hashref containing the start_season and stop_season of the query
 Returns: the arrayref of the ids of the existing games

=item C<add_game>

Actually puts the fully prepared boxscore, with set references to other collections, into the database.

 Argument: the boxscore
 Returns: the inserted id

=item C<add_game_coaches>

Adds the coaches of the teams from the boxscore to the database and provides a reference to the added coach in the boxscore.

 Argument: the boxscore
 Returns: void, the coaches names are replaced with OIDs in the boxscore.

=item C<add_game_player>

Adds a player from the boxscore to the database, and sets his team, injury, start and captaincy statuses and histories.

 Arguments:
 * the player hashref as parsed by Sport::Analytics::NHL::Report::Player
 * the game boxscore
 * the player's team name
 * [optional] overwrite force flag

 Returns: void

=item C<add_new_coach>

Initializes a new entry for a coach in the database.

 Arguments:
 * the coaches database collection
 * the boxscore
 * the team of the coach from the boxscore

 Returns: the OID of the coach

=item C<add_new_player>

Initializes a new entry for a player in the database.

 Arguments:
 * the players database collection
 * the player parsed by Sport::Analytics::Report::Player (q.v.)

 Returns: the id of the inserted player

=item C<create_event>

Creates a new event in the database, referencing all relevant fields by their own database catalogs. The event is inserted twice: first, with only least indexing information into the general 'events' collection; second, with the particular information in the event type's collection.

 Argument: the event from the boxscore
 Returns: the inserted event's id.

=item C<create_location>

Creates a new location (stadium/arena) entry in the database by its name and capacity.

 Argument: the location information from the boxscore
 Returns: the location entry as inserted.

=item C<ensure_event_indices>

Ensures the correct extra indices for the event's type collection.

 Arguments:
 * the event
 * the event's collection

 Returns: void

=item C<ensure_index>

Wraps around the new MongoDB collection index creation routine, replacing its own ensure_index() method.

 Arguments:
 * the collection
 * the index mapping as expected by create_one or create_many
 * [optional] - whether to reapply the index on non-empty collection

 Returns: the status of the index creation

=item C<get_catalog_entry>

Creates if necessary a catalog of NHL event subtypes (e.g. zones, penalties, stop reasons) by the name of the event subtype as normalized by the vocabulary in Sport::Analytics::NHL::Config (q.v.), and fetches the corresponding entry.

 Arguments:
 * the catalog's name to operate upon
 * the name of the catalog item

=item C<get_collection>

A wrapper over $self->{dbh}->get_collection();

=item C<remove_game>

Removes a game and references to it from the Mongo DB

 Arguments: the game

 Returns: void

 Caveat: removal of all traces is not guaranteed.

=item C<set_injury_history>

Sets the injury history of the player in the database. Either the current status is extended, or if the status changed, a new chapter is added.

 Arguments:
 * player's db entry
 * the boxscore
 * the injury status

 Returns: void

=item C<set_player_statuses>

Sets the status (captain, assistant captain) history of the player in the database. Either the current status (with the same team) is extended, or if the status changed, a new chapter is added.

 Arguments:
 * player's db entry
 * player's boxscore entry
 * the boxscore
 * the player's team name

 Returns: void

=item C<set_player_teams>

Sets the team history of the player in the database. Either the current team is extended, or if the team changed, a new chapter is added.

 Arguments:
 * player's db entry
 * the boxscore
 * the team

 Returns: void

This function is similar to the two above and all of them may be merged into one.

=item C<wipe_game_from_player_history>

During removal of game data, wipes a game from player's history.

 Arguments:
 * player's db entry
 * game's db entry

 Returns: void

=item C<bootstrap_divisions_conferences>

Bootstraps the NHL divisions and conferences from the Sport::Analytics::NHL::Config definitions

 Arguments: force overwrite flag (optional)

 Returns: void

=item C<bootstrap_teams>

Bootstraps the NHL teams from the Sport::Analytics::NHL::Config definitions

 Arguments: force overwrite flag (optional)

 Returns: void

=item C<ensure_shift_indices>

Ensures the custom indices for the shifts collection.

 Arguments: none

 Returns: void

=item C<find_items_with_games>

Returns the iterator of items by given game ids. Mostly used by the website, but should get the usage expanded.

 Arguments: the hashref of:
  collection of the items
  condition to apply
  [optional] id_field of the collection
  [optional] game_ids to look up
  [optional] return_fields to return
  [optional] count whether to return the iterator or the count

 Returns: the iterator or the count of matching documents.

=item C<find_player>

Finds a player by given name, team, season, stage

 Arguments: the player name
            the team
            the season
            the stage

 Returns: player's ID if the player is unambiguously found
          dies if more than one players are found
          warns if no players are found

=item C<get_catalog_condition>

Get a catalog item's condition for a search

 Arguments: the catalog's name
            the vocabulary entry name

 Returns: hashref catalog_name => catalog_item_id

=item C<get_item_collection>

Gets a collection for a given item by name. Expect to be deprecated.

 Arguments: the collection itself, or the collection name (optional)

 Returns: the collection or by default the games collection.

=item C<get_item_condition>

Expands an item condition from vocabulary names to catalog IDs

 Arguments: the condition

 Returns the expanded condition or
         the original condition
          if the 'verbatim' keyword was specified.

=item C<insert>

A generic wrapper over the MongoDB::Collection's insert_one / insert_many / replace_one methods. Generates the 'inserted' / 'updated' field as well.

 Arguments: the collection
            the array of items

 Returns: void

=item C<prepare_event>

Cleans up an event before inserting it into the Mongo DB.

 Arguments: the event
            the events hashref for tracking and debugging

 Returns: void

=item C<update>

A generic wrapper over the MongoDB::Collection's update_one / update_many methods. Generates the 'updated' field as well.

 Arguments: the one_many flag: 1 means many,
            the collection
            the filter to update
            the update arguments

 Returns: void

=item C<insert_injuries>

Inserts the data structure with injuries as crawled by Sport::Analytics::NHL::Scraper::crawl_injured_players() (q.v.),
The players are resolved to the player ids, and the begin and the end of the injuries are marked. If the player is
already in an injury status with the same team, the injury "end" property is extended.

 Arguments: the injuries structure

 Returns: void

=back

=cut

our $DEFAULT_DB = 'hockey';
our $DEFAULT_HOST = '127.0.0.1';
our $DEFAULT_PORT = 27017;

our @PLAYER_HISTORIES = qw(teams statuses starts games injury_history);
our %EVENT_CATALOGS = (
        shot_type => 'shot_types',
        zone      => 'zones',
        miss      => 'misses',
        penalty   => 'penalties',
        strength  => 'strengths',
);
our %STATS_FORCE_LC = qw(number 1 start 1 position 1 status 1 _id 1 team 1 name 1);
our %STATS_FORCE_NUMBER = qw(last_updated 1 _id 1 attendance 1 month 1 date 1 ot 1 start_ts 1 stop_ts 1 stage 1 season 1 season_id 1);

sub new ($;$) {

	my $class    = shift;
	my $database = shift || $ENV{HOCKEYDB_DBNAME} || $MONGO_DB || $DEFAULT_DB;

	my $slef;

	my $self = {};
	my $host = $MONGO_HOST || $DEFAULT_HOST;
	my $port = $MONGO_PORT || $DEFAULT_PORT;
	$self->{client} = MongoDB::MongoClient->new(
		host => sprintf(
			"mongodb://%s:%d", $host, $port
			#"mongodb://%%2Ftmp%%2Fmongodb-27017.sock"
		), connect_timeout_ms => 60000,
	);
	my $db = $database || $DEFAULT_DB;
	$self->{dbh} = $self->{client}->get_database($db);
	$DB = $self;
	$ENV{HOCKEYDB_DBNAME} = $db;
	verbose "Using Mongo database $db";
	$self->{dbname} = $db;
	bless $self, $class;
	$self;
}

sub get_collection ($$) {

	my $self = shift;
	my $collection = shift;

	$CACHES->{collections}{$collection} ||= $self->{dbh}->get_collection($collection);
	$CACHES->{collections}{$collection};
}

sub insert ($;@) {

	my $collection = shift;
	my @items      = @_;

	my $name = ref $collection ? $collection->{name} : $collection;
	debug "Inserting " . scalar(@items) . " items into $name";
	$collection   = $DB->get_collection($collection) unless ref $collection;
	my @insert_items = ();
	for my $item (@items) {
		if ($item->{_id} && $item->{inserted}) {
			$item->{updated} = time;
			$collection->replace_one({ _id => $item->{_id} }, $item);
		}
		else {
			$item->{inserted} = time;
			push(@insert_items, $item);
		}
	}
	$collection->insert_many(\@insert_items);
}

sub update ($$$$) {

	my $one_many   = shift;
	my $collection = shift;
	my $filter     = shift;
	my $arg        = shift;

	$collection   = $DB->get_collection($collection) unless ref $collection;
	my $method = $one_many ? 'update_many' : 'update_one';
	$arg->{'$set'} ||= {};
	$arg->{'$set'}{updated} = time;
	$collection->$method($filter, $arg);
}

sub ensure_index ($$;$) {

	my $collection = shift;
	my $index_map  = shift;
	my $reapply    = shift || 0;

	return if ! $reapply && $collection->count_documents({});
	debug "Ensuring indices for $collection";
	my $indices   = $collection->indexes();
	my $method    = ref $index_map eq 'ARRAY'
		? 'create_many'
		: 'create_one';
	my @index_map = ref $index_map eq 'ARRAY'
		? @{$index_map}
		: ($index_map);
	$indices->$method(@index_map);
}

sub resolve_team_db ($$) {

	my $self = shift;
	my $team = shift;

	$team = uc $team;
	my $teams_c = $self->get_collection('teams');

	my $team_db = $teams_c->find_one({
		'$or' => [
			{ _id   => $team },
			{ short => $team },
			{ long  => $team },
			{ full  => $team },
		],
	});
	$team_db ? $team_db->{_id} : undef;
}

sub insert_schedule ($@) {

	my $self  = shift;
	my @games = @_;

	return 0 unless @games;
	my $schedule_c = $self->get_collection('schedule');
	ensure_index($schedule_c, [
		{ keys => [ game_id => 1 ], options => {unique => 1}  },
		{ keys => [ date    => 1 ],                           },
		{ keys => [ season => 1, stage => 1, season_id => 1 ] },
	], 1);
	@games = grep {
		if ($_->{stage} == $REGULAR || $_->{stage} == $PLAYOFF) {
			$_->{game_id} += 0;
			$_->{ts} += 0;
		}
		else { 0 }
	} map(ref $_ && ref $_ eq 'ARRAY' ? @{$_} : $_, @games);
	$schedule_c->delete_many({_id => { '$in' => [ map {$_->{_id}} @games ] } });
	insert($schedule_c, @games);
	debug "Inserted " . scalar(@games) . " games for season $games[0]->{season}";
	scalar @games;
}

sub get_existing_game_ids ($;$) {

	my $self = shift;
	my $opts = shift || {
		stop_season => $CURRENT_SEASON, start_season => $CURRENT_SEASON
	};

	my $game_ids = [];
	my $games_i = $self->get_collection('games')->aggregate([
		{
			'$project' => { _id => 1 },
		},
	]);
	while (my $game = $games_i->next()) {
		push(@{$game_ids}, $game->{_id});
	}
	$game_ids;
}

sub create_location ($$) {

	my $self     = shift;
	my $location = shift;

	my $locations_c = $self->get_collection('locations');
	ensure_index($locations_c, [
		{ keys => [ name => 1 ], options => { unique => 1} }
	]);
	$location->{name} = normalize_string($location->{name});
	my $location_db = $locations_c->find_one({name => $location->{name}});
	if ($location_db) {
		if ($location_db->{capacity} < $location->{capacity}) {
			update(
				0, $locations_c,
				{ name => $location->{name} },
				{ '$set' => { capacity => $location->{capacity} }}
			);
		}
	}
	else {
		insert($locations_c, $location);
	}
	$locations_c->find_one({name => $location->{name}});
}

sub add_new_player ($$) {

	my $players_c = shift;
	my $player =    shift;

	for my $h (@PLAYER_HISTORIES) {
		$player->{$h} ||= [];
	}
	$player->{games}  ||= [];
	$player->{starts} ||= [];
	insert($players_c, $player);
	$players_c->find_one({_id => $player->{_id}});
}

sub set_player_statuses ($$$$) {

	my $player_db   = shift;
	my $player_game = shift;
	my $game        = shift;
	my $team        = shift;

	$player_db->{statuses} ||= [];
	if (
		! @{$player_db->{statuses}}
		|| $player_db->{statuses}[-1]{status} ne $player_game->{status}
		|| $player_db->{statuses}[-1]{team}   ne $team
	) {
		push(
			@{$player_db->{statuses}}, {
				start => $game->{start_ts}, end    => $game->{start_ts},
				team  => $team,             status => $player_game->{status},
			},
		);
	}
	else {
		$player_db->{statuses}[-1]{end} = $game->{start_ts}
			if $player_db->{statuses}[-1]{end} < $game->{start_ts};
		$player_db->{statuses}[-1]{start} = $game->{start_ts}
			if $player_db->{statuses}[-1]{start} > $game->{start_ts};
	}
}

sub set_player_teams ($$$) {

	my $player_db = shift;
	my $game      = shift;
	my $team      = shift;

	$player_db->{teams} ||= [];
	if (! @{$player_db->{teams}} || $player_db->{teams}[-1]{team} ne $team) {
		push(
			@{$player_db->{teams}}, {
				start => $game->{start_ts}, end => $game->{start_ts},
				team  => $team,
			},
		);
	}
	else {
		$player_db->{teams}[-1]{end} = $game->{start_ts}
			if $player_db->{teams}[-1]{end} < $game->{start_ts};
		$player_db->{teams}[-1]{start} = $game->{start_ts}
			if $player_db->{teams}[-1]{start} > $game->{start_ts};
	}
	$player_db->{team} = $team;
}

sub set_injury_history ($$$)  {

	my $player_db     = shift;
	my $game          = shift;
	my $injury_status = shift;

	$player_db->{injury_history} ||= [];
	if (! @{$player_db->{injury_history}}
		|| $player_db->{injury_history}[-1]{status} ne $injury_status) {
		push(
			@{$player_db->{injury_history}}, {
				start => $game->{start_ts}, end => $game->{start_ts},
				status => $injury_status,
			},
		);
	}
	else {
		$player_db->{injury_history}[-1]{end} = $game->{start_ts}
			if $player_db->{injury_history}[-1]{end} < $game->{start_ts};
		$player_db->{injury_history}[-1]{start} = $game->{start_ts}
			if $player_db->{injury_history}[-1]{start} > $game->{start_ts};
	}
	$player_db->{injury_status} = $injury_status;
	$player_db;
}

sub wipe_game_from_player_history ($$) {

	my $player_db = shift;
	my $game      = shift;

	debug "Cleaning game $game->{_id} from the records of $player_db->{_id}";
	$player_db->{games}  = [ grep {
		$game->{_id} != $_
	} @{$player_db->{games}}  ];
	$player_db->{starts} = [ grep {
		$game->{_id} != $_
	} @{$player_db->{starts}} ];
}

sub add_game_player ($$$$;$) {

	my $self      = shift;
	my $player    = shift;
	my $game      = shift;
	my $team_name = shift;
	my $force     = shift || 0;

	my $players_c = $self->get_collection('players');
	ensure_index($players_c, {name => 1});
	my $player_db = $players_c->find_one({_id => $player->{_id}})
		|| add_new_player($players_c, $player);
	if (firstval { $game->{_id} == $_ } @{$player_db->{games}} > -1) {
		if ($force) {
			wipe_game_from_player_history($player_db, $game);
		}
		else {
			verbose "Player $player->{_id} already has $game->{_id} in his history, skipping";
			return $player_db;
		}
	}
	for my $h (@PLAYER_HISTORIES) {
		$player_db->{$h} ||= [];
	}
	my $team = $game->{teams}[$game->{teams}[0]{name} eq $team_name ? 0 : 1];
	my $player_game = (grep {
		$player->{_id} == $_->{_id}
	} @{$team->{roster}})[0];
	push(@{$player_db->{games}},  $game->{_id} + 0);
	push(@{$player_db->{starts}}, $game->{_id} + 0)
		if defined $player_game->{start} && $player_game->{start} == 1;
	$player_db->{career} = $player->{career};
	$player_game->{status} ||= 'X';
	$player_game->{start}  ||= 2;
	set_player_statuses($player_db, $player_game, $game, $team->{name});
	set_player_teams($player_db, $game, $team->{name});
	set_injury_history($player_db, $game, 'OK');
	$player_db->{active} //= 1;
	insert($players_c, $player_db);
}

sub add_new_coach ($$$) {

	my $coaches_c = shift;
	my $game      = shift;
	my $team      = shift;

	insert($coaches_c, {
		name  => $team->{coach},
		teams => [{
			start => $game->{start_ts},
			end   => $game->{start_ts},
			team  => $team->{name},
		}],
		games => [ $game->{_id} ],
		team  => $team->{name},
		start => $game->{start_ts},
		end   => $game->{start_ts},
	});
	$coaches_c->find_one({name => $team->{coach}});
}

sub add_game_coaches ($$) {

	my $self = shift;
	my $game = shift;

	my $coaches_c = $self->{dbh}->get_collection('coaches');

	ensure_index($coaches_c, {name => 1});
	for my $t (0,1) {
		my $team = $game->{teams}[$t];
		next if ref $team->{coach};
		my $coach_db = $coaches_c->find_one({name => $team->{coach}})
			|| add_new_coach($coaches_c, $game, $team);
		debug "Setting coach from $team->{coach} to $coach_db->{_id}";
		$team->{coach} = $coach_db->{_id};
		next if $coach_db->{name} eq 'UNKNOWN COACH';

		next if grep { $game->{_id} == $_ } @{$coach_db->{games}};
		$coach_db->{end} = $game->{start_ts};
		push(@{$coach_db->{games}}, $game->{_id});
		if ($coach_db->{team} eq $team->{name}) {
			$coach_db->{teams}[-1]{end} = $game->{start_ts};
		}
		else {
			push(@{$coach_db->{teams}}, {
				start => $game->{start_ts},
				end   => $game->{start_ts},
				team  => $team->{name},
			});
			$coach_db->{start} = $game->{start_ts}
				if $coach_db->{start} > $game->{start_ts};
			$coach_db->{end}   = $game->{start_ts}
				if $coach_db->{end} < $game->{start_ts};
			$coach_db->{team}  = $team->{name};
		}
		insert($coaches_c, $coach_db);
	}
}

sub get_catalog_entry ($$$) {

	my $self    = shift;
	my $catalog = shift;
	my $name    = shift;

	return $name if ref $name;
	my $catalog_c = $self->get_collection($catalog);
	ensure_index($catalog_c, [
		{ keys => [ name => 1 ], options => { unique => 1 } },
	]);
	my $entry = $catalog_c->find_one({ name => $name });
	if (! $entry) {
		debug "DB: $self->{dbname} inserting $name into catalog $catalog";
		$catalog_c->insert_one({ name => $name });
		$entry = $catalog_c->find_one({ name => $name });
	}
	$entry;
}

sub ensure_event_indices ($$$) {

	my $self    = shift;
	my $event   = shift;
	my $event_c = shift;

	my $keys = [
		{ keys => [ game_id => 1 ], },
		{ keys => [ season  => 1 ], },
		{ keys => [ stage   => 1 ], },
		$event->{team1}   ? { keys => [ team1 => 1 ], }   : (),
		$event->{team2}   ? { keys => [ team2 => 1 ], }   : (),
		$event->{player1} ? { keys => [ player1 => 1 ], } : (),
		$event->{player2} ? { keys => [ player2 => 1 ], } : (),
	];
	$keys->[0]{options} = { unique => 1 }
		if $event->{type} eq 'GEND'
		|| $event->{type} eq 'PSTR'
		|| $event->{type} eq 'PEND';
	push(@{$keys->[0]{keys}}, period => 1)
		if $event->{type} eq 'PEND'
		|| $event->{type} eq 'PSTR';
	my @indices = $event_c->indexes->list->all();
	debug "Ensure: " . scalar(@indices) . ' vs ' . scalar(@{$keys});
	ensure_index($event_c, $keys) unless @indices == @{$keys} + 1;
	if (exists $event->{coordinates}{x}) {
		$event->{coordinates}{x} += 0;
		$event->{coordinates}{y} += 0;
	}
	$event->{_id} += 0;
}

sub ensure_shift_indices () {

	my $shifts_c = $DB->get_collection('shifts');
	my @indices = $shifts_c->indexes->list->all();
	my $keys = [
		{ keys => [ game_id => 1 ], },
		{ keys => [ season  => 1 ], },
		{ keys => [ stage   => 1 ], },
		{ keys => [ player  => 1 ], },
		{ keys => [ team    => 1 ], },
	];
	ensure_index($shifts_c, $keys) unless @indices == @{$keys} + 1;
}

sub prepare_event ($$$) {

	my $self       = shift;
	my $event      = shift;
	my $_events    = shift;

	my $event_c  = $self->get_collection($event->{type});
	my $event_db = $event_c->find_one({_id => $event->{_id}+0});
	return $event->{_id} if $event_db;
	for my $field (qw(shot_type miss penalty strength zone)) {
		$event->{$field} = $self->get_catalog_entry(
			$EVENT_CATALOGS{$field}, $event->{$field}
		)->{_id} if exists $event->{$field};
	}
	numerify_structure($event);
	if ($event->{type} eq 'STOP') {
		$event->{stopreasons} = [ map (
			$self->get_catalog_entry('stopreasons', $_)->{_id},
			@{$event->{stopreason}},
		)];
		delete $event->{stopreason};
	}
	debug "ensure indices";
	$self->ensure_event_indices($event, $event_c);
	debug "indices ensured";
	my $events_c = $self->get_collection('events');
	ensure_index($events_c, [
		{ keys => [ event_id => 1 ], options => {unique => 1} },
		{ keys => [ game_id  => 1 ], },
	]);
	push(
		@{$_events->{events}}, {
			type     => $event->{type},
			event_id => $event->{_id}     + 0,
			game_id  => $event->{game_id} + 0,
		}
	);
	$_events->{types}{$event->{type}} ||= [];
	push(@{$_events->{types}{$event->{type}}}, $event);
	push(@{$_events->{_ids}}, $event->{_id});
}

sub remove_game ($$) {

	my $self = shift;
	my $game = shift;

	my $events_c = $self->get_collection('events');
	my $events_i = $events_c->find({game_id => $game->{_id} + 0});
	my %collections = ();
	debug "Cleaning events";
	while (my $_event = $events_i->next()) {
		if (! $collections{$_event->{type}}) {
			$collections{$_event->{type}} = 1;
			my $event_c = $self->get_collection($_event->{type});
			$event_c->delete_many({game_id => $game->{_id} + 0});
		}
	}
	$events_c->delete_many({game_id => $game->{_id} + 0});
	my $coaches_c = $self->get_collection('coaches');
	my $players_c = $self->get_collection('players');
	for my $t (0,1) {
		my $team = $game->{teams}[$t];
		my $coach = $coaches_c->find_one({_id => $team->{coach}});
		if ($coach->{name} && $coach->{name} ne 'UNKNOWN COACH') {
			debug "Cleaning coach";
			$coach->{games} =
				[ grep { $_ != $game->{_id} } @{$coach->{games}} ];
			update(
				0, $coaches_c, {	_id => $coach->{_id}, }, {
					'$set' => { games => $coach->{games} }
				}
			);
		}
		for my $player (@{$team->{roster}}) {
			debug "Cleaning player";
			$player->{games} =
				[ grep { $_ != $game->{_id} } @{$player->{games}} ];
			$player->{starts} =
				[ grep { $_ != $game->{_id} } @{$player->{starts}} ];
			update(0, $players_c, {
				_id => $player->{_id},
			}, {
				'$set' => {
					starts => $player->{starts},
					games  => $player->{games}
				}
			});
		}
	}
	my $str_c = $self->get_collection('str');
	$str_c->delete_many({game_id => $game->{_id}+0 });
	my $games_c = $self->get_collection('games');
	$games_c->delete_one({_id => $game->{_id}+0 });
}

sub add_game ($$) {

	my $self = shift;
	my $game = shift;

	my $games_c = $self->get_collection('games');
	for my $t (0,1) {
		for my $player (@{$game->{teams}[$t]{roster}}) {
			my $method = $player->{position} eq 'G'
				? sub { lc shift }
				: sub { uc shift };
			for my $stat (keys %{$player}) {
				#				delete $player->{$stat} if ref $player->{$stat};
				delete $player->{SHOT};
				next if $STATS_FORCE_LC{$stat};
				my $db_stat = $method->($stat);
				$player->{$db_stat} = delete $player->{$stat};
			}
		}
	}
	for my $field (keys %STATS_FORCE_NUMBER) {
		$game->{$field} ||= 0;
	}
	numerify_structure($game);
	my $shifts = delete $game->{shifts};
	insert('shifts', @{$shifts});
	ensure_shift_indices();
	insert($games_c, $game);
	$game->{_id};
}

sub get_catalog_condition ($$$) {

	my $self    = shift;
	my $catalog = shift;
	my $name    = shift;

	my $catalog_c = $self->get_collection($catalog);
	my $item      = $catalog_c->find_one({name => $name})->{_id};

	{ $catalog => $item };
}

sub get_item_collection ($$) {

	my $self       = shift;
	my $collection = shift;

	$collection
		? (ref $collection ? $collection : $self->get_collection($collection))
		: $self->get_collection('games');

}

sub get_item_condition ($$) {

	my $self       = shift;
	my $condition  = shift;

	my $_condition = {};
	return $condition if delete $condition->{verbatim};
	if ($condition) {
		$_condition = {
			map {
				$self->get_catalog_condition($_, $condition->{$_})
			} keys %{$condition}
		};
	}
	$_condition;
}

sub find_items_with_games ($) {

	my $self = shift;
	my $opts = shift;

	my $collection = $self->get_item_collection($opts->{collection});
	my $condition  = $self->get_item_condition( $opts->{condition} );
	my $id_field   = $opts->{id_field}   || '_id';
	my $ids        = $opts->{game_ids}   || [];
	my @return_fields = $opts->{return_fields}
		? @{$opts->{return_fields}}
		: ();

	$condition->{$id_field} = { '$in' => $ids } if @{$ids};
	my %return_fields = map { $_ => 1 } @return_fields;
	my $method = $opts->{count} ? 'count_documents' : 'find';

	my $iterator = $collection->$method(
		$condition,
	);
	$iterator->fields(\%return_fields) if ! $opts->{count} && @return_fields;
	$iterator;

}

sub find_player ($$$$$) {

	my $self   = shift;
	my $name   = shift;
	my $team   = shift;
	my $season = shift;
	my $stage  = shift;
	
	return $EMPTY_NET_ID if $name eq 'EMPTY NET';

	my $initial = ''; my $last_name = '';
	if ($name =~ /^(\S.*?)\..*\s(\S.*)$/) {
		$initial = $1;
		$last_name = $2;
	}
	elsif ($name =~ /^(\S+)\s+(\S+)$/) {
		$initial = substr($1, 0, 1);
		$last_name = $2;
	}
	else {
		$last_name = $name;
	}
	my $players_c = $self->get_collection('players');
	my @players;
	#       verbose "resolving $name / $initial.*$last_name";
	@players = $players_c->find({name => $name})                         ->all();
	@players = $players_c->find({name => qr/^$initial.*\b$last_name\b/i})->all() unless @players;
	@players = $players_c->find({name => qr/\b$last_name\b/i})           ->all() unless @players;
	@players = grep {$_->{active}} @players if @players > 1;
	return $players[0]->{_id} if (@players == 1);
	@players = grep {$_->{team} eq $team } @players if @players > 1;
	return $players[0]->{_id} if (@players == 1);
	$stage = $stage == $REGULAR ? 'regular' : 'playoff';
	my @candidates = ();
	for my $player (@players) {
		push(@candidates, (grep {
			$_->{start} ||= 0;
			$_->{team} eq $team && $_->{start} == ($season || 0)
		} @{$player->{career}[0]}, @{$player->{career}[1]}) ? $player : ());
	}
	return $candidates[0]->{_id} if @candidates == 1;
	#       return $players[0]->{_id} if @players == 1;
	if (@candidates > 1) {
		dumper [ $name, $team, $season, $stage, ];
		print Dumper [ map {$_->{_id}} @candidates ];
		if ($ENV{HOCKEYDB_TEST}) {
			warn "Couldn't resolve player";
			return 0;
		}
		else {
			confess "Couldn't resolve player";
		}
	}
	elsif (@candidates == 0) {
		dumper [ $name, $team, $season, $stage, ];
		warn "Couldn't find player";
		return 0;
	}
}


sub bootstrap_teams ($) {

	my $self = shift;
	my $force = shift || 0;

	my $teams_c = $self->get_collection('teams');
	return if !$force && $teams_c->count_documents({});
	$teams_c->delete_many({});
	my @teams;
	while (my ($_id, $values) = each %TEAMS) {
		for my $key (keys %{$values}) {
			next unless ref $values->{$key};
			for my $name (@{$values->{$key}}) {
				$name = uc $name;
			}
		}
		$values->{defunct} ||= 0;
		$values->{_id} = $_id;
		push(@teams, $values);
	}
	debug "Bootstrapping teams...";
	insert($teams_c, @teams);
}

sub bootstrap_divisions_conferences ($;$) {

	my $self  = shift;
	my $force = shift || 0;

	my $divisions_c   = $self->get_collection('divisions');
	my $conferences_c = $self->get_collection('conferenc>es');
	my $seasons_c     = $self->get_collection('seasons');

	return if !$force && $seasons_c->count_documents({});
	for ($divisions_c, $conferences_c, $seasons_c) {
		$_->delete_many({}) if $force;
	}
	for my $s_span (keys %SEASONS) {
		$s_span =~ /^(\d{4})_(\d{4})$/;
		my $start  = $1;
		my $finish = $2;
		my $conferences = $SEASONS{$s_span};
		my @c_ids;
		for my $conference (keys %{$conferences}) {
			my $divisions = $conferences->{$conference};
			my @d_ids;
			for my $division (keys %{$divisions}) {
				my $teams = $divisions->{$division};
				my $d_c_id = $divisions_c->insert_one({
					name => $division,
					teams => $teams,
				});
				push(@d_ids, $d_c_id->{inserted_id});
			}
			my $c_c_id = $conferences_c->insert_one({
				name => $conference,
				divisions => [ @d_ids ],
			});
			push(@c_ids, $c_c_id->{inserted_id});
		}
		for my $year ($start..$finish) {
			$seasons_c->insert_one(
				{
					year => $year+0,
					conferences => [ @c_ids ],
				},
			);
		}
	}
}

sub insert_injuries ($$) {

	my $self = shift;
	my $injuries = shift;

	my $i = 1;
	my $injuries_c = $self->get_collection('injuries');
	for my $injury (@{$injuries}) {
		my $player = $self->find_player(
			$injury->{player_name}, $injury->{team},
			$CURRENT_SEASON, $CURRENT_STAGE,
		) || (
			$ENV{HOCKEYDB_TEST}
			? $i++
			: die "Couldn't find $injury->{player_name} on $injury->{team}"
		);
		my $player_injury = $injuries_c->find_one({
			_id  => $player + 0,
			team => $injury->{team},
		});
		if ($player_injury) {
			update(
				0, $injuries_c, { _id => $player+0 },
				{ '$set' => { end => time }},
			);
		}
		else {
			$injury->{_id} = $player;
			$injury->{begin} = time;
			$injury->{end}   = time;
			insert($injuries_c, $injury);
		}
	}
}

1;

=head1 AUTHOR

More Hockey Stats, C<< <contact at morehockeystats.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<contact at morehockeystats.com>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Sport::Analytics::NHL::DB>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Sport::Analytics::NHL::DB


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Sport::Analytics::NHL::DB>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Sport::Analytics::NHL::DB>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Sport::Analytics::NHL::DB>

=item * Search CPAN

L<https://metacpan.org/release/Sport::Analytics::NHL::DB>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2018 More Hockey Stats.

This program is released under the following license: gnu

=cut
