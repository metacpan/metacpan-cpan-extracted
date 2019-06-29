package Sport::Analytics::NHL::Populator;

use v5.10.1;
use strict;
use warnings FATAL => 'all';
use experimental qw(smartmatch);

use Sport::Analytics::NHL::Vars qw(:globals);
use Sport::Analytics::NHL::DB;
use Sport::Analytics::NHL::Util qw(:debug :utils);
#use Sport::Analytics::NHL::Tools;
use Sport::Analytics::NHL::Scraper qw(crawl_player);
use Sport::Analytics::NHL::Normalizer;

=head1 NAME

Sport::Analytics::NHL::Populator - populates the Mongo DB from the normalized boxscores - see Sport::Analytics::NHL::Normalizer for that and from other sources.

=head1 SYNOPSYS

Populates the Mongo DB from the normalized boxscores - see Sport::Analytics::NHL::Normalizer for that and from other sources.


This module serves as a buffer between the external parts and the Sport::Analytics::NHL::DB MongoDB interface.

    use Sport::Analytics::NHL::Populator;
    my @db_game_ids = populate_db($boxscore, $opts)

=head1 FUNCTIONS

=over 2

=item C<populate_db>

Creates and/or updates all the entries in the MongoDB related to the given normalized boxscore. If necessary, and if enabled, the player files from the NHL website are crawled for each participating player. Additional entries are created for:

 * game events
 * team coaches
 * game location

See the documentation for Sport::Analytics::NHL::DB for more details.

 Arguments:
 * the normalized boxscore
 * options hashref:
   - crawl_players - whether to crawl for playerfiles
   - force - overwrite previous data

 Returns: the id of the inserted boxscore.

=item C<populate_injured_players>

Work in progress. Do not use yet.

=back

=cut

use parent 'Exporter';

our @EXPORT_OK = qw(create_player_id_hash populate_db populate_injured_players);
our @EXPORT = (@EXPORT_OK);
our %EXPORT_TAGS = (
	all => \@EXPORT_OK,
);

=over 4

=item C<create_player_id_hash>

Creates a hash of player ids from the boxscore as keys and references to their stat entries as values

 Argument: the boxscore
 Returns: the hash of player ids

=back

=cut

sub create_player_id_hash ($) {

	my $boxscore = shift;

	my $player_ids;
	for my $t (0,1) {
		my $team = $boxscore->{teams}[$t];
		for my $player (@{$team->{roster}}) {
			$player_ids->{$player->{_id}} = \$player;
		}
	}
	$player_ids;
}

sub populate_db ($;$$) {

	my $boxscore = shift;
	my $opts     = shift;

	$CACHES->{gameplayers} = create_player_id_hash($boxscore);
	verbose "Populating $boxscore->{_id}";
	$DB ||= Sport::Analytics::NHL::DB->new();
	$DB->remove_game($boxscore) if $opts->{force} || $opts->{repopulate};
	if ($boxscore->{location}) {
		my $location = $DB->create_location({
			name     => $boxscore->{location},
			capacity => $boxscore->{attendance} || 0,
		});
		$boxscore->{location} = $location->{_id};
	}
	unless ($opts->{no_crawl}) {
		for my $player_id (keys %{$CACHES->{gameplayers}}) {
			next if $player_id == 8400001;
			my $team = ${$CACHES->{gameplayers}{$player_id}}->{team};
			debug "Crawling $player_id";
			my $player;
			if ($CACHES->{players}{$player_id}) {
				$player = $CACHES->{players}{$player_id};
			}
			else {
				my $p_file = crawl_player($player_id, $opts);
				die "Player $player_id is not available" unless $p_file;
				$player = Sport::Analytics::NHL::Report->new({
					file => $p_file,
					type => 'Player',
				});
				$player->process();
				$CACHES->{players}{$player_id} = $player;
			}
			debug "Adding player $player->{name} ($player->{_id})";
			$DB->add_game_player($player, $boxscore, $team, $opts->{force});
		}
	}
	$DB->add_game_coaches($boxscore);
	my %events = (_ids => [], types => {}, events => []);
	for my $event (@{$boxscore->{events}}) {
		$DB->prepare_event($event, \%events);
	}
	insert('events', @{$events{events}});
	for my $collection (keys %{$events{types}}) {
		insert($collection, @{$events{types}->{$collection}});
	}
	$boxscore->{events} = $events{_ids};
	$DB->add_game($boxscore);
	$boxscore->{_id};
}

sub populate_injured_players ($) {

	my $players = shift;

	$DB ||= Sport::Analytics::NHL::DB->new();
	my $players_c = $DB->get_collection('players');
	my $today = strftime("%Y%m%d", localtime(time));
	for my $player (@{$players}) {
		my @players = $players_c->find({
			name   => $player->{name},
			active => 1,
			team   => $player->{team},
		})->all();
		if (! @players) {
			print "Skipping missing player $player->{player_name}\n";
			next;
		}
		debug "Updating $players[0]->{_id} / $player->{player_name} / $players[0]->{team}";
		set_injury_history($players[0], {start_ts => time }, $player->{injury});
	}
}

1;

=head1 AUTHOR

More Hockey Stats, C<< <contact at morehockeystats.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<contact at morehockeystats.com>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Sport::Analytics::NHL::Populator>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Sport::Analytics::NHL::Populator

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Sport::Analytics::NHL::Populator>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Sport::Analytics::NHL::Populator>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Sport::Analytics::NHL::Populator>

=item * Search CPAN

L<https://metacpan.org/release/Sport::Analytics::NHL::Populator>

=back

=cut

