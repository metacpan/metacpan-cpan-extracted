package Sport::Analytics::NHL;

use v5.10.1;
use strict;
use warnings FATAL => 'all';
use experimental qw(smartmatch);

use File::Basename;
use Storable;
use POSIX qw(strftime);

use List::MoreUtils qw(uniq);

use Sport::Analytics::NHL::LocalConfig;
use Sport::Analytics::NHL::Config;
use Sport::Analytics::NHL::Errors;

use if ! $ENV{HOCKEYDB_NODB} && $MONGO_DB, 'Sport::Analytics::NHL::DB';
use Sport::Analytics::NHL::Merger;
use Sport::Analytics::NHL::Report;
use Sport::Analytics::NHL::Scraper;
use Sport::Analytics::NHL::Test;
use Sport::Analytics::NHL::Tools;
use Sport::Analytics::NHL::Util;

use parent 'Exporter';

=head1 NAME

Sport::Analytics::NHL - Crawl data from NHL.com and put it into a database

=head1 VERSION

Version 1.20

=cut

our @EXPORT = qw(
	hdb_version
);

our $VERSION = "1.20";

=head1 SYNOPSIS

Crawl data from NHL.com and put it into a database.

Crawls the NHL.com website, processes the game reports and stores them into a Mongo database or into the filesystem.

    use Sport::Analytics::NHL;

    my $nhl = Sport::Analytics::NHL->new();
    $nhl->scrape_games();
    ...
    # more functionality to be added in later releases.

=head1 EXPORT

hdb_version() - report the version. All the other interface is OOP via the new() constructor.

=cut

sub hdb_version () {

	$VERSION;
}

=head1 METHODS

=over 2

=item C<hdb_version>

Returns the current version of the package

=item C<new>

Returns a new Sport::Analytics::NHL object. If a Mongo DB is configured, the connection to the database is established, and the handle is stored in the object.

=item C<parse_game_args>

 Parses various game arguments to the scrape_games() method:
 * NHL IDs of format SSSS0TIIII (2016020201)
 * Our IDs of format SSSSTIIII  (201620201)
 * Dates in format YYYYMMDD (20160202)

 where S stands for starting year of season, T - stage (2 - regular, 3 - playoffs), I - the ID of the game within the year.

Modifies the games array reference passed as the first argument, and dates array reference passed as the second argument, using the list of number strings as the remaining list of arguments.

=item C<get_crawled_games_for_dates>

Gets a list of already crawled games on given list of dates. Crawls the season schedule on the NHL website if necessary.
Arguments: the options to pass to the scraper that crawls and the list of the dates.
Returns: the list of game structures which are hash references with the following fields:
 * season
 * stage
 * season id
 * Our game ID (see the previous section)

=item C<get_nodb_scheduled_games>

 Gets a list of scheduled, uncrawled games in the filesystem, based on the schedules already stored in, or crawled into the system.
 Argument: options hashref that specifies whether new schedules should be crawled, and only specific stage should be filtered.
 Returns: the list of game structures which are hash references with the following fields:
 * season
 * stage
 * season id
 * Our game ID (see the previous section)

=item C<get_db_scheduled_games>

 Same as the previous method, but the information is extracted from the Mongo database rather than the filesystem.

=item C<get_scheduled_games>

 The generic wrapper for the two previous methods.

=item C<scrape_games>

 Scrape the games reports from the NHL website and store them in files on the disk.
 Arguments: the hashref of options for the scrape -
 * no_schedule_crawl - whether fresh schedule should be crawled
 * start_season - the first season to start scraping from (default 1917)
 * stop_season - the last season to scrape (default - ongoing)
 * stage - 2 for Regular, 3 for Playoffs, none for both (default - none)
 * force - override the already present files and data

=item C<compile_file>

Compiles a single JSON or HTML report into a parsed hashref and stores it in a Storable file
Arguments:
 * The options hashref -
   - force: Force overwrite of already existing file
   - test: Test the resulted parsed report
 * The file
 * Our SSSSTNNNN game id
 * Optional: preset type of the report

Returns: the path to the compiled file

=item C<compile>

Compiles reports retrieved into the filesystem into parsed hashrefs and stores them in a Storable file.
Arguments:
 * The options hashref -
   - force: Force overwrite of already existing file
   - test: Test the resulted parsed report
   - doc: limit compilation to these Report types
   - data_dir: the root directory of the reports
 * The list of game ids

Returns: the location of the compiled storables

=item C<retrieve_compiled_report>

Retrieves the compiled storable file for the given game ID and file type.
Compiles the file anew unless explicitly prohibited from doing so.

Arguments:
 * The options hashref -
   - no_compile: don't compile files if required
   - recompile: force recompilation
 * game ID
 * doc type (e.g. BS, PL, RO, ...)
 * path to the storable file.
The file is expected at location $path/$doc.storable

Returns: the file structure retrieved from storable, or undef.

=item C<merge>

Merges reports compiled in the filesystem into one boxscore hashref and stores it in a Storable file.

Arguments:
 * The options hashref -
   - force: Force overwrite of already existing file
   - test: Test the resulted parsed report
   - doc: limit compilation to these Report types
   - data_dir: the root directory of the reports
   - no_compile: don't compile files if required
   - recompile: force recompilation
 * The list of game ids

Returns: the location of the merged storable

=back

=cut

sub new ($$) {

	my $class = shift;
	my $opts  = shift;

	my $self = {};
	unless ($opts->{no_database} || $ENV{HOCKEYDB_NODB} || ! $MONGO_DB) {
		$self->{db} = Sport::Analytics::NHL::DB->new($opts->{database} || $ENV{HOCKEYDB_DBNAME} || $MONGO_DB);
	}
	$ENV{HOCKEYDB_DATA_DIR} = $DATA_DIR = $opts->{data_dir} if $opts->{data_dir};
	bless $self, $class;
	$self;
}

sub parse_game_args ($$@) {

	my $games = shift;
	my $dates = shift;
	my @args  = @_;

	for (@args) {
		my $game = {};
		when (/^\d{10}$/) { $game = parse_nhl_game_id($_); push(@{$games}, $game) }
		when (/^\d{9}$/ ) { $game = parse_our_game_id($_); push(@{$games}, $game) }
		when (/^\d{8}$/ ) { push(@{$dates}, $_) }
		default { warn "[WARNING] Unrecognized argument $_, skipping\n" }
	}
}

sub get_crawled_games_for_dates ($$@) {

    my $self  = shift;
    my $opts  = shift;
    my @dates = @_;

    my $schedules        = {};
    my $schedule_by_date = {};
    my @games            = ();
    for my $date (@dates) {
        $opts->{start_season} = $opts->{stop_season} =
			get_season_from_date($date);
        unless ($schedules->{$opts->{start_season}}) {
			$schedules = crawl_schedule($opts);
			arrange_schedule_by_date(
				$schedule_by_date,
                $schedules->{$opts->{start_season}}
			);
            $self->{db}->insert_schedule(values %{$schedule_by_date})
				if $self->{db};
        }
        unless ($schedule_by_date->{$date}) {
            print STDERR "No games scheduled for $date, skipping...\n";
            next;
        }
        push(@games, @{$schedule_by_date->{$date}});
    }
    @games;
}

sub get_nodb_scheduled_games ($) {

    my $opts = shift;

    my @games = ();
    my $schedules = $opts->{no_schedule_crawl} ?
		read_schedules($opts) : crawl_schedule($opts);
	for my $season (keys %{$schedules}) {
        debug "NODB schedule SEASON $season";
        my $existing_game_ids =
          $opts->{force} ? {} : read_existing_game_ids($season);
        my $season_schedule = ref $schedules->{$season} eq 'ARRAY'
            ? $schedules->{$season}
            : [map(@{$_->{games}}, @{$schedules->{$season}{dates}})];
        for my $schedule_game ( @{$season_schedule} ) {
            my $game = convert_schedule_game($schedule_game);
            next unless $game;
            next unless ($opts->{stage} && $game->{stage} == $opts->{stage})
				|| (!$opts->{stage}
				&& ($game->{stage} == $REGULAR || $game->{stage} == $PLAYOFF)
			);
            next if $existing_game_ids->{$game->{game_id}};
            push(@games, $game);
        }
    }
    @games;
}

sub get_db_scheduled_games ($$) {

    my $self = shift;
    my $opts = shift;

    my @games = ();
    my $existing_game_ids = $opts->{force}
		? []
		: $self->{db}->get_existing_game_ids($opts);

    if ( !$opts->{no_schedule_crawl} ) {
        my $schedules = crawl_schedule($opts);
        for my $season ( sort keys %{$schedules} ) {
            my $schedule_by_date = {};
            arrange_schedule_by_date(
                $schedule_by_date,
                $schedules->{$season}
            );
            $self->{db}->insert_schedule(values %{$schedule_by_date});
        }
    }

	debug scalar(@{$existing_game_ids}) . " total existing games";
    @games = $self->{db}{dbh}->get_collection('schedule')->find(
        {
            game_id => { '$nin' => $existing_game_ids },
            $opts->{stage} ? ( stage => $opts->{stage}+0 ) : (),
            season => {
                '$gte' => $opts->{start_season}+0,
                '$lte' => $opts->{stop_season} +0,
            },
        }
    )->all();
    @games;
}

sub get_scheduled_games ($$) {

	my $self = shift;
    my $opts = shift;

    $opts->{start_season} ||= $CURRENT_SEASON;
    $opts->{stop_season}  ||= $CURRENT_SEASON;

	$self->{db}
		? $self->get_db_scheduled_games($opts)
		: get_nodb_scheduled_games($opts);
}

sub scrape_games ($$;@) {

	my $self = shift;
	my $opts = shift;
	my @args = @_;

	my @games = ();
	if (@args) {
		my @dates = ();
		parse_game_args(\@games, \@dates, @args);
		push(
			@games,
			$opts->{no_schedule_crawl}
				? get_games_for_dates(@dates)
				: $self->get_crawled_games_for_dates( $opts, @dates ),
		) if @dates;
	}
	else {
		@games = $self->get_scheduled_games($opts);
	}
	unless (@games) {
		print STDERR "No games to crawl found!\n";
		return ();
	}
	my @got_games;
	@games = sort { ($a->{ts} || $a->{game_id}) <=> ($b->{ts} || $b->{game_id}) } @games;
	for my $game (@games) {
		if ($game->{date} && $game->{date} > strftime("%Y%m%d", localtime)) {
			print "Game $game->{_id} is in the future ($game->{date}), wrapping up\n";
			last;
		}
		my $crawled_game = crawl_game($game);
		push(@got_games, map($_->{file}, values %{$crawled_game->{content}}));
	}
	@got_games;
}

sub compile_file ($$$$) {

	my $opts    = shift;
	my $file    = shift;
	my $game_id = shift;
	my $type    = shift || 'XX';

	my $args = { file => $file };
	if ($BROKEN_FILES{$game_id}->{$type}) {
		print STDERR "File $file is broken, skipping\n";
		return undef;
	}
	my $storable = $file;
	$storable =~ s/\.([a-z]+)$/.storable/i;
	#my $storable = dirname($file) . '/' . $args->{type} . '.storable';
	if (!$opts->{force} && -f $storable && -M $storable < -M $file) {
		print STDERR "File $storable already exists, skipping\n";
		return $storable;
	}
	my $report = Sport::Analytics::NHL::Report->new($args);
	$report->process();
	if ($opts->{test}) {
		test_boxscore($report, { lc $args->{type} => 1 });
		verbose "Ran $TEST_COUNTER->{Curr_Test} tests";
		$TEST_COUNTER->{Curr_Test} = 0;
	}
	store $report, $storable;
	debug "Wrote $storable";

	$storable;

}

sub compile ($$@) {

	my $self = shift;
	my $opts = shift;
	my @game_ids = @_;

	my @storables = ();
	for my $game_id (@game_ids) {
		if (defined $DEFAULTED_GAMES{$game_id}) {
			print STDERR "Skipping defaulted game $game_id\n";
			next;
		}
		my @game_files = get_game_files_by_id($game_id, $opts->{data_dir});
		for my $game_file (@game_files) {
			$game_file =~ m|/([A-Z]{2}).[a-z]{4}$|;
			my $type = $1;
			next if ($opts->{doc} && !grep {$_ eq $type} @{$opts->{doc}});
			my $storable = compile_file($opts, $game_file, $game_id, $type);
			push(@storables, $storable) if $storable;
		}
	}
	return @storables;
}

sub retrieve_compiled_report ($$$$) {

	my $opts    = shift;
	my $game_id = shift;
	my $doc     = shift;
	my $path    = shift;

@Sport::Analytics::NHL::Report::RO::ISA = qw(Sport::Analytics::NHL::Report);
@Sport::Analytics::NHL::Report::PL::ISA = qw(Sport::Analytics::NHL::Report);
@Sport::Analytics::NHL::Report::GS::ISA = qw(Sport::Analytics::NHL::Report);
@Sport::Analytics::NHL::Report::ES::ISA = qw(Sport::Analytics::NHL::Report);
	my $doc_storable = "$path/$doc.storable";
	my $doc_source   = "$path/$doc." . ($doc eq 'BS' ? 'json' : 'html');
	#$Storable::DEBUGME = 1;
	debug "Looking for file $doc_storable or $doc_source";
	return retrieve $doc_storable if -f $doc_storable && ! $opts->{recompile};
	if ($opts->{no_compile}) {
		print STDERR "No storable file and no-compile option specified, skipping\n";
		return undef;
	}
	if (! -f $doc_source) {
		print STDERR "No storable and no source report available, skipping\n";
		return undef;
	}
	debug "Compiling $doc_source";
	$doc_storable = compile_file($opts, $doc_source, $game_id, $doc);
	retrieve $doc_storable if $doc_storable;
}

sub merge ($$@) {

	my $self = shift;
	my $opts = shift;
	my @game_ids = @_;

	my @storables = ();

	for my $game_id (@game_ids) {
		if (defined $DEFAULTED_GAMES{$game_id})	{
			print STDERR "Skipping defaulted game $game_id\n";
			next;
		}
		my $path = get_game_path_from_id($game_id);
		my $merged = "$path/$MERGED_FILE";
		if (! $opts->{force} && -f "$merged") {
			print STDERR "Merged file $merged already exists, skipping\n";
			next;
		}
		$opts->{doc} ||= [];
		$opts->{doc}   = [qw(PL RO GS ES)];
		my $boxscore = retrieve_compiled_report($opts, $game_id, 'BS', $path);
		next unless $boxscore;
		$boxscore->build_resolve_cache();
		$boxscore->set_event_extra_data();
		for my $doc (@{$opts->{doc}}) {
			my $report = retrieve_compiled_report($opts, $game_id, $doc, $path);
			merge_report($boxscore, $report) if $report;
		}
		if ($opts->{test}) {
			test_merged_boxscore($boxscore);
			verbose "Ran $TEST_COUNTER->{Curr_Test} tests";
			$TEST_COUNTER->{Curr_Test} = 0;
		}
		debug "Storing $merged";
		store($boxscore, $merged);
		push(@storables, $merged)
	}
	return @storables;
}

=head1 AUTHOR

More Hockey Stats, C<< <contact at morehockeystats.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<contact at morehockeystats.com>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Sport::Analytics::NHL>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Sport::Analytics::NHL

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Sport::Analytics::NHL>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Sport::Analytics::NHL>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Sport::Analytics::NHL>

=item * Search CPAN

L<https://metacpan.org/release/Sport::Analytics::NHL>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2018 More Hockey Stats.

This program is released under the following license: gnu


=cut

1; # End of Sport::Analytics::NHL
