package Sport::Analytics::NHL::LocalConfig;

use strict;
use warnings FATAL => 'all';

use parent 'Exporter';

=head1 NAME

Sport::Analytics::NHL::LocalConfig - local configuration settings

=head1 SYNOPSYS

Local configuration settings

Provides local settings such as the location of the Mongo DB or the data storage, and the current season/stage setting.

This list shall expand as the release grows.

    use Sport::Analytics::NHL::LocalConfig;
    print "The data is stored in $LOCAL_CONFIG{DATA_DIR}\n";

=cut

use Carp;

our %LOCAL_CONFIG = (
	CURRENT_SEASON => 2018,
	CURRENT_STAGE  => 2,
	IS_AUTHOR      => 0,
	MONGO_DB       => '',
	MONGO_HOST     => '127.0.0.1',
	MONGO_PORT     => 27017,
	SQLNAME        => 'hockey',
	SQLUSER        => 'root',
	BASE_DIR       => '/tmp/hockey',
	MERGED_FILE    => 'merged.storable',
	NORMALIZED_FILE => 'normalized.storable',
	NORMALIZED_JSON => 'normalized.json',
	SUMMARIZED_FILE => 'SUMMARIZED',
	DEFAULT_PLAYERFILE_EXPIRATION => 0.5,
	ROTOFILE_EXPIRATION => 1,
	SQL_COMMIT_RATE => 5000,
	REDIRECT_STDERR => 0,
	TWITTER_ACCESS_TOKEN          => '',
	TWITTER_ACCESS_TOKEN_SECRET   => '',
);

$ENV{HOCKEYDB_SQLNAME} = $LOCAL_CONFIG{SQLNAME};
$ENV{HOCKEYDB_SQLUSER} = $LOCAL_CONFIG{SQLUSER};

our @EXPORT = qw(%LOCAL_CONFIG);

$LOCAL_CONFIG{REPORTS_DIR}    = $LOCAL_CONFIG{BASE_DIR} . '/reports';
$LOCAL_CONFIG{HTML_DIR}       = $LOCAL_CONFIG{BASE_DIR} . '/html';
$LOCAL_CONFIG{TWITTER_DIR}    = $LOCAL_CONFIG{BASE_DIR} . '/twitter';
$LOCAL_CONFIG{DATA_DIR}       = $LOCAL_CONFIG{BASE_DIR} . '/data';
$LOCAL_CONFIG{LOG_DIR}        = $LOCAL_CONFIG{BASE_DIR} . '/logs';

$LOCAL_CONFIG{SCRAPED_GAMES}  = $LOCAL_CONFIG{DATA_DIR} . '/scraped-games';

$LOCAL_CONFIG{WEB_LOG}         = $LOCAL_CONFIG{LOG_DIR} . 'web.log';
$LOCAL_CONFIG{API_LOG}         = $LOCAL_CONFIG{LOG_DIR} . 'api.log';
$LOCAL_CONFIG{MAIN_LOG}        = $LOCAL_CONFIG{LOG_DIR} . 'main.log';
$LOCAL_CONFIG{ERROR_WEB_LOG}   = $LOCAL_CONFIG{LOG_DIR} . 'weberr.log';
$LOCAL_CONFIG{STDERR_LOG}      = $LOCAL_CONFIG{LOG_DIR} . 'stderr.log';
$LOCAL_CONFIG{REDIRECT_STDERR} = 0;

1;

=head1 AUTHOR

More Hockey Stats, C<< <contact at morehockeystats.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<contact at morehockeystats.com>, or through the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Sport::Analytics::NHL::LocalConfig>.  I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Sport::Analytics::NHL::LocalConfig


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Sport::Analytics::NHL::LocalConfig>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Sport::Analytics::NHL::LocalConfig>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Sport::Analytics::NHL::LocalConfig>

=item * Search CPAN

L<https://metacpan.org/release/Sport::Analytics::NHL::LocalConfig>

=back

