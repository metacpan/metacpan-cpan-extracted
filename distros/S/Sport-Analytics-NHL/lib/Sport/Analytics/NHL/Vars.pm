package Sport::Analytics::NHL::Vars;

use strict;
use warnings;

use parent 'Exporter';
use Sport::Analytics::NHL::LocalConfig;

our @local_config_variables = qw(
	API_LOG BASE_DIR CURRENT_SEASON CURRENT_STAGE DATA_DIR
	DEFAULT_PLAYERFILE_EXPIRATION ROTOFILE_EXPIRATION ERROR_WEB_LOG
	HTML_DIR IS_AUTHOR LOG_DIR MAIN_LOG MERGED_FILE MONGO_DB
	MONGO_HOST MONGO_PORT NORMALIZED_FILE NORMALIZED_JSON
	REDIRECT_STDERR REPORTS_DIR	SCRAPED_GAMES SQL_COMMIT_RATE
	STDERR_LOG SQLNAME SQLUSER SUMMARIZED_FILE
	TWITTER_ACCESS_TOKEN TWITTER_ACCESS_TOKEN_SECRET TWITTER_DIR WEB_LOG
);
my @LOCAL_CONFIG;
our $DB;
our $CACHES = {};
our $SQL;
my @DIRS = ();
no strict 'refs';
for my $lcv (@local_config_variables) {
	my $var = '$'.$lcv;
	eval 
		qq{our $var; $var= "$LOCAL_CONFIG{$lcv}";};
	push(@LOCAL_CONFIG, $var);
	push(@DIRS, $var) if $var =~ /dir$/i;
}
our $WEB_STAGES; our $WEB_STAGES_TOTAL; our @SEASON_START_STOP;
our @GLOBALS = qw($DB $CACHES $SQL);
our @WEB    = qw($WEB_STAGES $WEB_STAGES_TOTAL @SEASON_START_STOP);

our @EXPORT_OK = (qw(
	@local_config_variables
), @LOCAL_CONFIG, @GLOBALS, @WEB);

our @BASIC  = qw($CURRENT_SEASON $CURRENT_STAGE);
our @SCRAPE = (@BASIC, @DIRS, qw($DEFAULT_PLAYERFILE_EXPIRATION $ROTOFILE_EXPIRATION));
our @TEST   = (@BASIC, qw($IS_AUTHOR));

our %EXPORT_TAGS = (
	local_config => [ @LOCAL_CONFIG, qw(@local_config_variables) ],
	globals      => [ @GLOBALS   ],
	scrape       => [ @SCRAPE    ],
	test         => [ @TEST ],
	all          => [ @EXPORT_OK ],
	mongo        => [ qw($MONGO_DB $MONGO_HOST $MONGO_PORT) ],
	basic        => [ @BASIC ],
	web          => [ @WEB   ],
);
1;

=head1 NAME

Sport::Analytics::NHL::Vars - Global variables for a variety of use.

=head1 SYNOPSYS

This module maintains and exports the global variables and the variables defined in Sport::Analytics::NHL::LocalConfig

    use Sport::Analytics::NHL::Vars;

    $CACHES = {};

Only variables are defined in this module, and they can be accessed by tags:

=over 2

=item :local_config

LocalConfig.pm variables

=item :globals

$DB, $SQL - Mongo and MySQL handles, $CACHES - global caching system

=item :basic

$CURRENT_SEASON, $CURRENT_STAGE

=item :scrape

:basic, $DEFAULT_PLAYERFILE_EXPIRATION - when the playerfile json is considered stale and needs to be re-scraped

=item :test

:basic, $IS_AUTHOR - you shouldn't set this one to 1 unless you know what you're doing.

=item :mongo

$MONGO_DB, $MONGO_HOST, $MONGO_PORT

=item :all

All of the above

=back

=cut

=head1 GLOBAL VARIABLES

 The behaviour of the tests is controlled by several global variables:
 * $PLAYER_IDS - hashref of all player ids encountered.

=head1 AUTHOR

More Hockey Stats, C<< <contact at morehockeystats.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<contact at morehockeystats.com>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Sport::Analytics::NHL::Vars>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Sport::Analytics::NHL::Vars

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Sport::Analytics::NHL::Vars>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Sport::Analytics::NHL::Vars>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Sport::Analytics::NHL::Vars>

=item * Search CPAN

L<https://metacpan.org/release/Sport::Analytics::NHL::Vars>

=back
