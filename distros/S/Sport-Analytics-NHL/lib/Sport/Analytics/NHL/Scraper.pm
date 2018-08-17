package Sport::Analytics::NHL::Scraper;

use v5.10.1;
use warnings FATAL => 'all';
use strict;
use experimental qw(smartmatch);
use parent 'Exporter';

use Time::HiRes qw(time usleep);
use POSIX qw(strftime);

use JSON;
use LWP::Simple;

use Sport::Analytics::NHL::LocalConfig;
use Sport::Analytics::NHL::Config;
use Sport::Analytics::NHL::Util;
use Sport::Analytics::NHL::Tools;
use Sport::Analytics::NHL::Report::BS;

=head1 NAME

Sport::Analytics::NHL::Scraper - Scrape and crawl the NHL website for data

=head1 SYNOPSIS

Scrape and crawl the NHL website for data

  use Sport::Analytics::NHL::Scraper
  my $schedules = crawl_schedule({
    start_season => 2016,
    stop_season  => 2017
  });
  ...
  my $contents = crawl_game(
    { season => 2011, stage => 2, season_id => 0001 }, # game 2011020001 in NHL accounting
    { game_files => [qw(BS PL)], retries => 2 },
  );

=head1 IMPORTANT VARIABLE

Variable @GAME_FILES contains specific definitions for the report types. Right now only the boxscore javascript has any meaningful non-default definitions; the PB feed seems to have become unavailable.

=head1 FUNCTIONS

=over 2

=item C<scrape>

A wrapper around the LWP::Simple::get() call for retrying and control.

Arguments: hash reference containing

  * url => URL to access
  * retries => Number of retries
  * validate => sub reference to validate the download

Returns: the content if both download and validation are successful undef otherwise.

=item C<crawl_schedule>

Crawls the NHL schedule. The schedule is accessed through a minimalistic live api first (only works for post-2010 seasons), then through the general /api/

Arguments: hash reference containing

  * start_season => the first season to crawl
  * stop_season  => the last season to crawl

Returns: hash reference of seasonal schedules where seasons are the keys, and decoded JSONs are the values.

=item C<get_game_url_args>

Sets the arguments to populate the game URL for a given report type and game

Arguments:

 * document name, currently one of qw(BS PB RO ES GS PL)
 * game hashref containing
   - season    => YYYY
   - stage     => 2|3
   - season ID => NNNN

Returns: a configured list of arguments for the URL.

=item C<crawl_game>

Crawls the data for the given game

Arguments:

  game data as hashref:
  * season    => YYYY
  * stage     => 2|3
  * season ID => NNNN
  options hashref:
  * game_files => hashref of types of reports that are requested
  * force      => 0|1 force overwrite of files already present in the system
  * retries    => N number of the retries for every get call

=item C<crawl_player>

Crawls the data for an NHL player given his NHL id. First, the API call is made, and the JSON is retrieved. Unfortunately, the JSON does not contain the draft information, so another call to the HTML page is made to complete the information. The merged information is stored in a json file at the ROOT_DATA_DIR/players/$ID.json path.

 Arguments:
 * player's NHL id
 * options hashref:
   - data_dir root data dir location
   - playerfile_expiration -how long the saved playerfile should be trusted
   - force - crawl the player regardless

 Returns: the path to the saved file

=back

=cut

our $SCHEDULE_JSON     = 'http://live.nhle.com/GameData/SeasonSchedule-%s%s.json';
our $SCHEDULE_JSON_API = 'https://statsapi.web.nhl.com/api/v1/schedule?startDate=%s&endDate=%s';
our $HTML_REPORT_URL   = 'http://www.nhl.com/scores/htmlreports/%d%d/%s%02d%04d.HTM';
our $PLAYER_URL        = 'https://statsapi.web.nhl.com/api/v1/people/%d?expand=person.stats&stats=yearByYear,yearByYearPlayoffs&expand=stats.team&site=en_nhl';
our $SUPP_PLAYER_URL   = "https://www.nhl.com/player/%d";
#our $ROTOWORLD_URL     = 'http://www.rotoworld.com/teams/injuries/nhl/all/';
#our %ROTO_CENSUS = (
#        'CHRIS TANEV' => 'CHRISTOPHER TANEV',
#);
our @GAME_FILES = (
	{
		name      => 'BS',
		pattern   => 'https://statsapi.web.nhl.com/api/v1/game/%s/feed/live',
		extension => 'json',
		validate  => sub {
			my $json = shift;
			my $bs = Sport::Analytics::NHL::Report::BS->new($json);
			return scalar @{$bs->{json}{liveData}{plays}{allPlays}};
			1;
		},
	},
	{
		name      => 'PB',
		pattern   => 'http://live.nhle.com/GameData/%s%s/%s/PlayByPlay.json',
		extension => 'json',
		disabled  => 1,
	},
	{ name => 'ES' },
	{ name => 'GS' },
	{ name => 'PL' },
	{ name => 'RO' },
);

our @EXPORT = qw(
	crawl_schedule crawl_game crawl_player
);

our $DEFAULT_RETRIES = 3;

sub scrape ($) {

	my $opts = shift;
	die "Can't scrape without a URL" unless defined $opts->{url};

	return undef if $ENV{HOCKEYDB_NONET};
	$opts->{retries}  ||= $DEFAULT_RETRIES;
	$opts->{validate} ||= sub { 1 };

	my $now = time;
	my $r = 0;
	my $content;
	while (! $content && $r++ < $opts->{retries}) {
		debug "Trying ($r/$opts->{retries}) $opts->{url}...";
		$content = get($opts->{url});
		unless ($opts->{validate}->($content)) {
			verbose "$opts->{url} failed validation, retrying";
			$content = undef;
		}
	}
	debug sprintf("Retrieved in %.3f seconds", time - $now) if $content;
	$content;

}

sub crawl_schedule ($) {

	my $opts        = shift;

	my $start_season = $opts->{start_season} || $FIRST_SEASON;
	my $stop_season  = $opts->{stop_season}  || $CURRENT_SEASON;

	my $schedules = {};
	for my $season ($start_season .. $stop_season) {
		next if grep { $_ == $season } @LOCKOUT_SEASONS;
		my $schedule_json;
		my $schedule_json_file = get_schedule_json_file($season);
		if ($season == $CURRENT_SEASON || ! -f $schedule_json_file) {
			my $schedule_json_url = sprintf($SCHEDULE_JSON, $season, $season+1);
			$schedule_json = scrape({ url => $schedule_json_url });
			if (! $schedule_json) {
				my ($start_date, $stop_date) = get_start_stop_date($season);
				$schedule_json_url = sprintf($SCHEDULE_JSON_API, $start_date, $stop_date);
				$schedule_json = scrape({ url => $schedule_json_url });
				if (! $schedule_json) {
					verbose "Couldn't download from $schedule_json_url, skipping...";
					next;
				}
			}
			write_file($schedule_json, $schedule_json_file);
			if (! -f $schedule_json_file) {
				print "ERROR: could not find a JSON schedule file, skipping...";
				next;
			}
		}
		$schedule_json      ||= read_file($schedule_json_file);
		$schedules->{$season} = decode_json($schedule_json);
	}
	$schedules;
}

sub get_game_url_args ($$) {

	my $doc_name = shift;
	my $game     = shift;

	my $game_id = sprintf(
		"%04d%02d%04d",
		$game->{season}, $game->{stage}, $game->{season_id}
	);
	my @args;
	for ($doc_name) {
		when ('BS') {
			@args = ($game_id);
		}
		when ('PB') {
			@args = ($game->{season}, $game->{season} + 1, $game_id);
		}
		default {
			@args = (
				$game->{season}, $game->{season} + 1, $doc_name,
				$game->{stage}, $game->{season_id}
			);
		}
	}
	@args;
}

sub crawl_game ($;$) {

	my $game = shift;
	my $opts = shift || {};

	my $path = make_game_path($game->{season}, $game->{stage}, $game->{season_id});
	my $contents = {};
	for my $doc (@GAME_FILES) {
		next if $doc->{disabled};
		next if $opts->{game_files} && ! $opts->{game_files}{$doc};
		next if $game->{season} < $FIRST_REPORT_SEASONS{$doc->{name}};
		my @args = get_game_url_args($doc->{name}, $game);
		$doc->{pattern}   ||= $HTML_REPORT_URL;
		$doc->{extension} ||= 'html';
		my $file = "$path/$doc->{name}.$doc->{extension}";
		if (-f $file && ! $opts->{force}) {
			print STDERR "[NOTICE] File $file already exists, not crawling\n";
			$contents->{$doc->{name}} = read_file($file);
			next;
		}
		my $url     = sprintf($doc->{pattern}, @args);
		my $content = scrape({
			url => $url, validate => $doc->{validate}, retries => $opts->{retries}
		});
		if (! $content) {
			print STDERR "[WARNING] Got no content for $game->{season}, $game->{stage}, $game->{season_id}, $doc->{name}\n";
			next;
		}
		$content =~ s/\xC2\xA0/ /g unless $doc->{extension} eq 'json';
		write_file($content, $file);
		$contents->{$doc->{name}} = {content => $content, file => $file};
	}
	$contents;
}

sub crawl_player ($;$$$) {

	my $id       = shift;
	my $opts     = shift;

	$opts->{data_dir}              ||= $ENV{HOCKEYDB_DATA_DIR} || $DATA_DIR;
	$opts->{playerfile_expiration} ||= $DEFAULT_PLAYERFILE_EXPIRATION;
	my $sfx = 'json';
	my $file = sprintf("%s/players/%d.%s", $opts->{data_dir}, $id, $sfx);

	if (-f $file && -M $file < $opts->{playerfile_expiration} && ! $opts->{force}) {
		debug "File exists and is recent, skipping";
		return $file;
	}

	my $content = scrape({ url => sprintf($PLAYER_URL, $id) });
	if (! $content) {
		print STDERR "ID $id missing or network unavailable\n";
		if (-f $file) {
			print STDERR "Using old available file\n";
			return $file;
		}
		return;
	}
	my $json = decode_json($content);
	$json = $json->{people}[0];
	if (-f $file) {
		my $existing_json = decode_json(read_file($file));
		for my $key (qw(draftyear draftteam round undrafted pick)) {
			$json->{$key} = $existing_json->{$key} if exists $existing_json->{$key};
		}
	}
	else {
		my $supp_url = sprintf($SUPP_PLAYER_URL, $id);
		$content = scrape({url => $supp_url});
		if ($content =~ /Draft:.*(\d{4}) (\S{3}), (\d+)\S\S rd, .* pk \((\d+)\D+ overall\)/) {
			$json->{draftyear} = $1+0;
			$json->{draftteam} = $2;
			$json->{round}     = $3+0;
			$json->{undrafted} = 0;
			$json->{pick}      = $4+0;
		}
		else {
			$json->{undrafted} = 1;
			$json->{pick}      = $UNDRAFTED_PICK;
        }
	}
	write_file(encode_json($json), $file);
	$file;
}

1;

=head1 AUTHOR

More Hockey Stats, C<< <contact at morehockeystats.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<contact at morehockeystats.com>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Sport::Analytics::NHL::Scraper>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Sport::Analytics::NHL::Scraper

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Sport::Analytics::NHL::Scraper>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Sport::Analytics::NHL::Scraper>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Sport::Analytics::NHL::Scraper>

=item * Search CPAN

L<https://metacpan.org/release/Sport::Analytics::NHL::Scraper>

=back
