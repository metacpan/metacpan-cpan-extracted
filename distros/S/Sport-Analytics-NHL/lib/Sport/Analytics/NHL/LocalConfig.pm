package Sport::Analytics::NHL::LocalConfig;

use strict;
use warnings FATAL => 'all';

use parent 'Exporter';

use Sport::Analytics::NHL::Config;

=head1 NAME

Sport::Analytics::NHL::LocalConfig - local configuration settings

=head1 SYNOPSYS

Local configuration settings

Provides local settings such as the location of the Mongo DB or the data storage, and the current season/stage setting.

This list shall expand as the release grows.

    use Sport::Analytics::NHL::LocalConfig;
    print "The data is stored in $DATA_DIR\n";

=cut


our $CURRENT_SEASON = 2018;
our $CURRENT_STAGE  = $REGULAR;

our $IS_AUTHOR = 0;

# UNCOMMENT AND CONFIGURE FOR MONGO USAGE

our $MONGO_DB = undef;
#our $MONGO_DB   = 'hockeytest';
#our $MONGO_HOST = '127.0.0.1';
#our $MONGO_PORT = 27017;

our $DATA_DIR = '/misc/nhl';

our @EXPORT = qw(
	$MONGO_DB $MONGO_HOST $MONGO_PORT
	$CURRENT_SEASON $CURRENT_STAGE $DATA_DIR
	$IS_AUTHOR
	$MERGED_FILE $NORMALIZED_FILE $SUMMARIZED_FILE $NORMALIZED_JSON
	$DEFAULT_PLAYERFILE_EXPIRATION
);

our $MERGED_FILE     = 'merged.storable';
our $NORMALIZED_FILE = 'normalized.storable';
our $NORMALIZED_JSON = 'normalized.json';
our $SUMMARIZED_FILE = 'SUMMARIZED';

our $DEFAULT_PLAYERFILE_EXPIRATION = 57600;

1;

=head1 AUTHOR

More Hockey Stats, C<< <contact at morehockeystats.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<contact at morehockeystats.com>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Sport::Analytics::NHL::LocalConfig>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


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

