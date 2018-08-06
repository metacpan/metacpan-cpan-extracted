package Sport::Analytics::NHL::Usage;

use v5.10.1;
use strict;
use warnings FATAL => 'all';

use Getopt::Long qw(:config no_ignore_case bundling);

use Sport::Analytics::NHL::Config;
use Sport::Analytics::NHL::LocalConfig;
use Sport::Analytics::NHL;

use parent 'Exporter';

our @EXPORT = qw(gopts);

=head1 NAME

Sport::Analytics::NHL::Usage - an internal utility module standardizing the usage of our applications.

=head1 FUNCTIONS

=over 2

=item C<convert_opt>

=item C<usage>

=item C<gopts>

this is the main wrapper for GetOptions to keep things coherent.

=back

=cut

our $USAGE_MESSAGE = '';
our $def_db = $MONGO_DB || 'hockey';

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
	],
	season   => [
		{
			short       => 's', long => 'start-season', arg => 'SEASON', type => 'i',
			description => "Start at season SEASON (default $CURRENT_SEASON)",
		},
		{
			short       => 'S', long => 'stop-season',  arg => 'SEASON', type => 'i',
			description => "Stop at season SEASON (default $CURRENT_SEASON)",
		},
		{
			short       => 'T', long => 'stage', arg => 'STAGE', type => 'i',
			description => "Scrape stage STAGE ($REGULAR: REGULAR, $PLAYOFF: PLAYOFF, default: $CURRENT_STAGE",
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
	misc     => [
		{
			short       => 'f', long => 'force',
			description => 'override/overwrite existing data',
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
			short       => 'E', long => 'data-dir', arg => 'DIR', type => 's',
			description => "Data directory root (default $DATA_DIR)",
		}
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

sub gopts ($$$) {

	my $wid  = shift;
	my $opts = shift;
	my $args = shift;

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
			for my $opt (@opts) {
				$usage_message .= sprintf(
					"\t\t\t%-20s %-10s %s\n",
					($opt->{short} ? "-$opt->{short}|" : '') . "--$opt->{long}",
					$opt->{arg} || '',
					$opt->{description},
				);
				my $is_repeatable = $opt->{repeatable} ? '@' : '';
				$g_opts{
					(($opt->{short} ? "$opt->{short}|" : '') . $opt->{long}) .
						($opt->{type} ? "=$opt->{type}$is_repeatable" : '')
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
			);
		}
	}
	$USAGE_MESSAGE = $usage_message;
	GetOptions(%g_opts) || usage();
	$u_opts;
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
