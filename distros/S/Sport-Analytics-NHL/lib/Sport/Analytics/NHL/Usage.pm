package Sport::Analytics::NHL::Usage;

use v5.10.1;
use strict;
use warnings FATAL => 'all';

use Getopt::Long qw(:config no_ignore_case bundling);

use Sport::Analytics::NHL::Config qw(:basic :seasons);
#use Sport::Analytics::NHL::Web;
use Sport::Analytics::NHL::Vars qw(:local_config);
use Sport::Analytics::NHL;

use parent 'Exporter';

our @EXPORT = qw(gopts usage parse_start_stop_opts);

=head1 NAME

Sport::Analytics::NHL::Usage - an internal utility module standardizing the usage of our applications.

=head1 FUNCTIONS

=over 2

=item C<convert_opt>

A small routine converting the CLI option with dashes into a snake-case string

 Arguments: the option text

 Returns: the converted string

=item C<usage>

Produces a usage message and exits

 Arguments: [optional] exit status, defaults to 0

 Returns: exits

=item C<gopts>

This is the main wrapper for GetOptions to keep things coherent.

 Arguments: usage message
            arrayref of options, by tags or specific opts
            arrayref of arguments
 [optional] arrayref of explicitly excluded options

 Returns: a list of options to which convert_opt() was applied.
 Don't ask me why.

=item C<parse_start_stop_opts>

Produces a start and end range of seasons or season weeks based on options specified.

 Arguments: specified options
 [optional] type of range, defaults to 'season'

 Returns: the range between the start and the stop option,
          default applies.

=back

=cut

our $USAGE_MESSAGE = '';
our $def_db  = $ENV{HOCKEYDB_DBNAME}  || $MONGO_DB || 'hockey';
our $def_sql = $ENV{HOCKEYDB_SQLNAME} || 'hockey';

our %OPTS = (
	standard => [
        {
			short => 'h', long => 'help',
			action => sub { usage(); },
			description => 'print this message and exit'
        },
        {
			short => 'V', long => 'version',
			action => sub { say hdb_version(); exit; },
			description => 'print version and exit'
        },
        {
			short => 'v', long => 'verbose',
			action => sub { $ENV{HOCKEYDB_VERBOSE} = 1 },
			description => 'produce verbose output to STDERR'
        },
        {
			short => 'd', long => 'debug',
			action => sub { $ENV{HOCKEYDB_DEBUG} = 1; },
			description => 'produce debug output to STDERR'
		},
		{
			long => 'config-file', type => 's', arg => 'CONFIG',
			description => 'Use config file CONFIG',
		},
		{
			long        => 'dry-run', short => 'n',
			action      => sub { $ENV{HOCKEYDB_DRYRUN} = 1; },
			description => 'Execute a dry run (no updates or posts)',
		},
	],
	season   => [
		{
			short       => 's', long => 'start-season', arg => 'SEASON', type => 'i',
			description => "Start at season SEASON (default $CURRENT_SEASON)",
		},
		{
			long => 'season', arg => 'SEASON', type => 'i',
			description => "Operate on SEASON (default $CURRENT_SEASON)",
		},
		{
			short       => 'S', long => 'stop-season',  arg => 'SEASON', type => 'i',
			description => "Stop at season SEASON (default $CURRENT_SEASON)",
		},
		{
			short       => 'T', long => 'stage', arg => 'STAGE', type => 'i',
			description => "Operate stage STAGE ($REGULAR: REGULAR, $PLAYOFF: PLAYOFF, default: $CURRENT_STAGE",
		},
	],
	week   => [
		{
			short       => 'w', long => 'start-week', arg => 'WEEK', type => 'i',
			description => "Start at week WEEK",
		},
		{
			long => 'week', arg => 'WEEK', type => 'i',
			description => "Operate on WEEK",
		},
		{
			short       => 'W', long => 'stop-week',  arg => 'WEEK', type => 'i',
			description => "Stop at week WEEK",
		},
	],
	feature  => [
		{
			long => 'disable', arg => 'FEATURE', type => 's@',
			description => 'disable feature FEATURE',
		},
		{
			long => 'enable', arg => 'FEATURE', type => 's@',
			description => 'enable feature FEATURE',
		},
	],
	database => [
		{
			long        => 'no-database',
			description => 'Do not use a MongoDB backend',
		},
		{
			short       => 'D', long => 'database', arg => 'DB', type => 's',
			description => "Use Mongo database DB (default $def_db)"
		},
	],
	compile => [
		{
			long => 'no-compile',
			description => 'Do not compile file even if storable is absent',
		},
		{
			long => 'recompile',
			description => 'Compile file even if storable is present',
		}
	],
	merge => [
		{
			long => 'no-merge',
			description => 'Do not merge file even if storable is absent',
		},
		{
			long => 'remerge',
			description => 'Compile file even if storable is present',
		}
	],
	normalize => [
		{
			long => 'no-normalize',
			description => 'Do not normalize file even if storable is absent',
		},
		{
			long => 'renormalize',
			description => 'Compile file even if storable is present',
		}
	],
	poller   => [
		{
			long => 'pid-file', arg => 'PID_FILE', short => 'P',
			description => 'Use pid-file PID_FILE',
		},
		{
			long => 'no-pid',
			description => 'Do not use a pid file',
		},
		{
			long => 'test-mode',
			description => 'Run in test mode (implies dry-run and force)',
		},
	],
	generator => [
		{
			long => 'all',
			description => 'generate everything',
		},
		{
			long => 'pulled-goalie',
			description => 'generate pulled goalies',
		},
		{
			long => 'ne-goals',
			description => 'generate goals scored while with empty net',
		},
		{
			long => 'icings-info',
			description => 'generate icings information',
		},
		{
			long => 'fighting-majors',
			description => 'generate implicit fighting majors',
		},
		{
			long => 'strikebacks',
			description => 'generate strikebacks',
		},
		{
			long => 'lead-changing-goals',
			description => 'generate lead changing goals',
		},
		{
			long => 'icecount-mark',
			description => 'generate icecount marks',
		},
		{
			long => 'challenges',
			description => 'generate challenges',
		},
		{
			long => 'leading-trailing',
			description => 'generate leading/trailing records',
		},
		{
			long => 'offsides_info',
			description => 'generate offsides',
		},
		{
			long => 'gamedays',
			description => 'generates breaks in days before this game',
		},
		{
			long => 'common-games',
			description => 'generate common games',
		},
		{
			long => 'clutch-goals',
			description => 'generate clutch goals',
		},
	],
	twitter  => [
		{
			long => 'bgcolor', short => 'b', arg => 'COLOR',
			description => 'Background color for the tweet',
		},
		{
			long => 'fgcolor', short => 'f', arg => 'COLOR',
			description => 'Foreground color for the tweet',
		},
		{
			long => 'show-text',
			description => 'Show the text before converting it to image',
		},
		{
			long => 'file', short => 'F', arg => 'FILE',
			description => 'Read text from file FILE',
		},
		{
			long => 'tab-file', short => 'T',
			description => 'Indicate the file is TAB-Separated',
		},
		{
			long => 'header', short => 'H', arg => 'HEADER',
			description => 'Provide header HEADER to the tweet',
		},
	],
	yahoomodel => [
		{
			long => 'commit-level', short => 'L', arg => 'N', type => 'i',
			description => 'Commit rating calculations after N games',
		},
		{
			long => 'average', short => 'a', arg => 'FLOAT', type => 's',
			description => 'Set average scoring to FLOAT',
		},
		{
			long => 'spread', short => 's', arg => 'FLOAT', type => 's',
			description => 'Set scoring spread to FLOAT',
		},
	],
	model => [
		{
			long => 'concept', arg => 'TYPE', type => 's',
			description => 'Use concept TYPE',
		},
		{
			long => 'model', arg => 'TYPE', type => 's',
			description => 'Use model TYPE',
		},
		{
			long => 'calculate',
			description => 'calculate ratings for the model',
		},
		{
			long => 'datepoints',
			description => 'generate rating datepoints',
		},
		{
			long => 'score',
			description => 'calculate scores',
		},
		{
			long => 'predict',
			description => 'generate predictions with the model',
		},
	],
	api        => [
		{
			long => 'balance', short => 'b', arg => 'SUM', type => 's',
			description => "Set user's account balance to SUM",
		},
		{
			long => 'pass', short => 'p', arg => 'PASS', type => 's',
			description => 'Set pass to PASS (will be encrypted)',
		},
	],
	penalties => [
		{
			long => 'no-set-strengths',
			description => 'Do not set strengths',
		},
		{
			long => 'no-analyze',
			description => 'Do not analyze penalties, just set strengths',
		}
	],
	publish  => [
		{
			long => 'update', short => 'U',
			description => 'Only update data',
		},
		{
			long => 'no-prepare', short => 'N',
			description => 'Skip the preparation step',
		},
		{
			long => 'prepare-only', short => 'n',
			description => 'Only do the preparation step',
		},
		{
			long => 'no-output', short => 'O',
			description => 'Skip the web pages generation step',
		},
		{
			long => 'output-only', short => 'o',
			description => 'Only do the web pages generation step',
		},
		{
			long => 'no-page', short => 'P', type => 's', arg => 'PAGE',
			description => 'Skip page PAGE (section-page)',
		},
		{
			long => 'page', short => 'p', type => 's', arg => 'PAGE',
			description => 'Only work on page PAGE (section-page)',
		},
		{
			long => 'no-section', short => 'S', type => 's', arg => 'SECTION',
			description => 'Skip section SECTION',
		},
		{
			long => 'section', short => 's', type => 's', arg => 'SECTION',
			description => 'Only work on section SECTION',
		},
		{
			long => 'snippet-only',
			description => 'Only work on snippets',
		},
		{
			long => 'list', short => 'l',
			description => 'List available pages and exit',
		},
		{
			long => 'sitemap', short => 'x',
			description => "Generate sitemaps",
		},
		{
			short       => 'f', long => 'force',
			description => 'force publishing non-publishable pages',
		},
	],
	period => [
		{
			long => 'goals',
			description => 'produce goal records, not just shots',
		},
	],
	misc     => [
		{
			long => 'invert',
			description => 'Invert data, i.e. use shot against, goal against etc.'
		},
		{
			long => 'event-type', type => 's', arg => 'EVENT_TYPE',
			description => 'Specify the type of event to work upon',
		},
		{
			long => 'duration', type => 'i', arg => 'NUM',
			description => 'Specify duration to work with',
		},
		{
			long => 'threshold', type => 'i', arg => 'NUM',
			description => 'Specify threshold to work with',
		},
		{
			short       => 'f', long => 'force',
			description => 'override/overwrite existing data',
		},
		{
			long => 'gamecount', type => 'i', arg => 'NUM',
			description => 'only run for NUM of games from the start of the season',
		},
		{
			short       => 'q', long => 'sql',
			description => "use SQL database DBNAME (default $def_sql)",
			arg         => 'DBNAME', type => 's',
		},
		{
			long => 'generate-sql',
			description => "Produce relevant sql tables",
		},
		{
			long => 'end',
			description => "Generate the data for the end of the season",
		},
		{
			long        => 'test',
			description => 'Test the validity of the files (use with caution)'
		},
		{
			long        => 'doc',
			description => 'Only process reports of type doc (repeatable). Available types are: BS, PL, RO, GS, ES',
			repeatable  => 1, arg => 'DOC',
			type        => 's'
		},
		{
			long        => 'no-schedule-crawl',
			description => 'Try to use schedule already present in the system',
		},
		{
			long        => 'rating', arg => 'NUM', type => 'i', optional => 1,
			description => 'Use Elo ratings in calculations',
		},
		{
			long        => 'train-span', arg => 'NUM', type => 'i',
			description => 'Train the model over NUM YEARS',
		},
		{
			long        => 'twitter-dir', arg => 'DIR',
			description => "Use directory DIR for storing images instead of $TWITTER_DIR",
		},
		{
			short       => 'E', long => 'data-dir', arg => 'DIR', type => 's',
			description => "Data directory root (default $DATA_DIR)",
		},
		{
			long => 'break', arg => 'N', type => 'i',
			description => 'only use games after a break of size N',
		},
	],
);

sub usage (;$) {

	my $status = shift || 0;

	print join("\n", <<ENDUSAGE =~ /^\t\t(.*)$/gm), "\n";
$USAGE_MESSAGE
ENDUSAGE
	exit $status;
}

sub convert_opt ($) {

	my $opt = shift;

	my $c_opt = $opt;
	$c_opt =~ s/\-/_/g;
	$c_opt;
}

sub gopts ($$$;$) {

	my $wid  = shift;
	my $opts = shift;
	my $args = shift;
	my $ipts = shift || [];

	my %g_opts = ();
	my $u_opts = {};
	my $u_arg = @{$args} ? ' Arguments' : '';
	my $usage_message ="
\t\t$wid
\t\tUsage: $0 [Options]$u_arg
";
	unshift(@{$opts}, ':standard') unless grep {$_ eq '-standard'} @{$opts};
	if (@{$opts}) {
		$usage_message .= "\t\tOptions:\n";
		for my $opt_group (@{ $opts }) {
			my @opts;
			if ($opt_group =~ /^\:(.*)/) {
				@opts = @{ $OPTS{$1} };
			}
			else {
				@opts = grep { $_->{long} eq $opt_group } @{ $OPTS{misc} };
			}
			for my $ipt (@{$ipts}) {
				@opts = grep { $_->{long} ne $ipt } @opts;
			}
			for my $opt (@opts) {
				$usage_message .= sprintf(
					"\t\t\t%-20s %-10s %s\n",
					($opt->{short} ? "-$opt->{short}|" : '') . "--$opt->{long}",
					$opt->{arg} || '',
					$opt->{description},
				);
				my $is_repeatable = $opt->{repeatable} ? '@' : '';
				my $optional = $opt->{optional} ? ':' : '=';
				$g_opts{
					(($opt->{short} ? "$opt->{short}|" : '') . $opt->{long}) .
						($opt->{type} ? "$optional$opt->{type}$is_repeatable" : '')
				} = ($opt->{action} || \$u_opts->{convert_opt($opt->{long})});
			}
		}
	}
	else {
		$usage_message .= "\t\tNo Options\n";
	}
	if (@{$args}) {
		$usage_message .= "\t\tArguments:\n";
		for my $arg (@{$args}) {
			$usage_message .= sprintf(
				"\t\t\t%-20s %s%s",
				$arg->{name}, $arg->{description},
				$arg->{optional} ? ' [optional]' : ''
			) . "\n";
		}
	}
	$USAGE_MESSAGE = $usage_message;
	GetOptions(%g_opts) || usage();
	$u_opts;
}


sub parse_start_stop_opts ($;$) {

	my $opts = shift;
	my $type = shift || 'season';

	return($opts->{$type}) if ($opts->{$type});
	my $start = "start_$type";
	my $stop  = "stop_$type";
	my $default_start = $type eq 'season' ? $FIRST_SEASON   : 1;
	my $default_stop  = $type eq 'season' ? $CURRENT_SEASON : 26;
	$opts->{$start} ||= $default_start;
	$opts->{$stop}  ||= $default_stop;
	return ($opts->{$start}..$opts->{$stop});
}

1;

=head1 AUTHOR

More Hockey Stats, C<< <contact at morehockeystats.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<contact at morehockeystats.com>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Sport::Analytics::NHL::Usage>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Sport::Analytics::NHL::Usage

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Sport::Analytics::NHL::Usage>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Sport::Analytics::NHL::Usage>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Sport::Analytics::NHL::Usage>

=item * Search CPAN

L<https://metacpan.org/release/Sport::Analytics::NHL::Usage>

=back
