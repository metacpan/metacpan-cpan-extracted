package Sport::Analytics::NHL::DB;

use strict;
use warnings FATAL => 'all';

use Carp;
use POSIX;
use MongoDB;
use MongoDB::OID;
use MongoDB::MongoClient;

use Tie::IxHash;
use boolean;

use Sport::Analytics::NHL::Config;
use Sport::Analytics::NHL::LocalConfig;
use Sport::Analytics::NHL::Util;

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

=back

=cut

our $DEFAULT_DB = 'hockey';
our $DEFAULT_HOST = '127.0.0.1';
our $DEFAULT_PORT = 27017;

sub new ($;$) {

	my $class    = shift;
	my $database = shift || $ENV{HOCKEYDB_DBNAME} || $MONGO_DB || $DEFAULT_DB;

	my $self = {};
	my $host = $MONGO_HOST || $DEFAULT_HOST;
	my $port = $MONGO_PORT || $DEFAULT_PORT;
	$self->{client} = MongoDB::MongoClient->new(
		host => sprintf(
			"mongodb://%s:%d", $host, $port
		)
	);
	my $db = $database || $DEFAULT_DB;
	$self->{dbh} = $self->{client}->get_database($db);
	$ENV{HOCKEYDB_DBNAME} = $db;
	verbose "Using Mongo database $db";
	$self->{dbname} = $db;
	bless $self, $class;
	$self;
}

sub resolve_team_db ($$) {

	my $self = shift;
	my $team = shift;

	$team = uc $team;
	my $teams_c = $self->{dbh}->get_collection('teams');

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
	my $schedule_c = $self->{dbh}->get_collection('schedule');
	my $schedule_x = $schedule_c->indexes();
	$schedule_x->create_many(
		{ keys => [ game_id => 1 ], options => {unique => 1}  },
		{ keys => [ date    => 1 ],                           },
		{ keys => [ season => 1, stage => 1, season_id => 1 ] },
	);
	@games = grep {
		if ($_->{stage} == $REGULAR || $_->{stage} == $PLAYOFF) {
			$_->{game_id} += 0;
			$_->{ts} += 0;
		}
		else { 0 }
	} map(ref $_ && ref $_ eq 'ARRAY' ? @{$_} : $_, @games);
	$schedule_c->delete_many({_id => { '$in' => [ map {$_->{_id}} @games ] } });
	$schedule_c->insert_many([@games]);
	debug "Inserted " . scalar(@games) . " games for season $games[0]->{season}";
	scalar @games;
}

sub get_existing_game_ids ($;$) {

	my $self = shift;
	my $opts = shift || {
		stop_season => $CURRENT_SEASON, start_season => $CURRENT_SEASON
	};

	my @games = $self->{dbh}->get_collection('games')->find({
		season => {
			'$gte' => $opts->{start_season}+0,
			'$lte' => $opts->{stop_season} +0
		},
	}, {_id => 1})->all();

	[ map($_->{_id}+0,@games) ];
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
