package MyCPAN::Indexer::BackPANstats;
use strict;

use warnings;
no warnings;

use subs qw(get_caller_info);
use vars qw($VERSION $logger);
use parent qw(MyCPAN::Indexer MyCPAN::Indexer::Component MyCPAN::Indexer::Reporter::Base);

$VERSION = '1.282';

=encoding utf8

=head1 NAME

MyCPAN::Indexer::BackPANstats - Collect various stats about BackPAN activity

=head1 SYNOPSIS

	use MyCPAN::Indexer;

=head1 DESCRIPTION

This module implements the indexer_class and reporter_class components
to allow C<backpan_indexer.pl> to collect stats on BackPAN.

It runs through the indexing and prints a report at the end of the run.

=cut

use Carp qw(croak);
use Cwd qw(cwd);

use Log::Log4perl;

BEGIN {
	$logger = Log::Log4perl->get_logger( __PACKAGE__ );
	}

__PACKAGE__->run( @ARGV ) unless caller;

=head2 Indexer class

=over 4

=item get_indexer()

A stand in for run_components later on.

=cut

sub get_indexer
	{
	my( $self ) = @_;

	1;
	}

sub class { __PACKAGE__ }

=item setup_run_info

Like C<setup_run_info> in C<MyCPAN::Indexer>, but it remembers fewer
things. The test census really just cares about statements in the test
files, so the details about the run aren't as interesting.

=cut

sub setup_run_info { 1 }

=item examine_dist_steps

Given a distribution, unpack it, look at it, and report the findings.
It does everything except the looking right now, so it merely croaks.
Most of this needs to move out of run and into this method.

=cut

sub examine_dist_steps
	{
	my @methods = (
		#    method         error message           fatal
		[ 'collect_info',  "Could not get info!",    1 ],
		);
	}

=item check_dist_size

We don't care about 0 byte dists, so we always return true so setup_dist_info
doesn't bail out.

=cut

sub check_dist_size { 1 }

=item collect_info

Given a distribution, unpack it, look at it, and report the findings.
It does everything except the looking right now, so it merely croaks.
Most of this needs to move out of run and into this method.

=cut

use CPAN::DistnameInfo;
sub collect_info {
	my $self = shift;
	my $d = CPAN::DistnameInfo->new( $self->{dist_info}{dist_file} );
	$self->set_dist_info( 'dist_name', $d->dist );
	$self->set_dist_info( 'dist_version', $d->version );
	$self->set_dist_info( 'maturity', $d->maturity );

	my @gmtime = gmtime( $self->dist_info( 'dist_date' ) );
	my( $year, $month, $day ) = @gmtime[ 5,4,3 ];
	$year += 1900;
	$month += 1;

	$self->set_dist_info(
		'yyyymmdd_gmt',
		sprintf '%4d%02d%02d', $year, $month, $day
		);

	$self->set_dist_info(
		'calendar_quarter',
		sprintf "%4dQ%d", $year, int( ($month - 1 ) / 3 ) + 1
		);

	1;
	}


=back

=head2 Reporter class

=over 4

=item get_reporter( $Notes )

C<get_reporter> sets the C<reporter> key in the C<$Notes> hash
reference. The value is a code reference that takes the information
collected about a distribution and counts the modules used in the test
files.

See L<MyCPAN::Indexer::Tutorial> for details about what
C<get_reporter> expects and should do.

$VAR1 = {
          'dist_date' => 1207928766,
          'dist_basename' => 'cpan-script-1.54.tar.gz',
          'maturity' => 'released',
          'dist_file' => '/Volumes/iPod/BackPAN/authors/id/B/BD/BDFOY/cpan-script-1.54.tar.gz',
          'dist_size' => 6281,
          'dist_author' => 'BDFOY',
          'dist_name' => 'cpan-script',
          'dist_md5' => '8053fa43edcdce9a90f78f878cbf6caf',
          'dist_version' => '1.54'
        };
=cut

sub check_for_previous_successful_result { 1 }
sub check_for_previous_error_result      { 0 }
sub final_words                          { sub { 1 } }

sub get_reporter {
	my $self = shift;
	require JSON::XS;
	use File::Basename qw(dirname);
	use File::Path qw(make_path);
use Clone qw(clone);
use Data::Structure::Util qw(unbless);

	my $jsonner = JSON::XS->new->pretty;

	my $reporter = sub {
		my( $info ) = @_;

		unless( defined $info ) {
			$logger->error( "info is undefined!" );
			return;
			}

		my $out_path = $self->get_report_path( $info );
		my $dir = dirname( $out_path );
		unless( -d $dir ) {
			make_path( $dir ) or
				$logger->fatal( "Could not create directory $dir: $!" );
			}

		open my($fh), ">:utf8", $out_path or
			$logger->fatal( "Could not open $out_path: $!" );

		{
		# now that indexer is a component, it has references to all the other
		# objects, making for a big dump. We don't want the keys starting
		# with _
		# Storable doesn't work because it can't handle the CODE refs
		my $clone = clone( $info ); # hack until we get an info class
		unbless( $clone );
		delete $clone->{run_info};
		my $dist = $clone->{dist_info}{dist_basename};

		local $SIG{__WARN__} = sub {
			$logger->warn( "Error writing to YAML output for $dist: @_" );
			};

		foreach my $key ( keys %$clone ) {
			delete $clone->{$key} if $key =~ /^_/;
			}

		print { $fh } $jsonner->encode( $clone );
		}

		$logger->error( "$out_path is missing!" ) unless -e $out_path;

		1;
		};

	$self->set_note( 'reporter', $reporter );
	}

sub get_report_file_extension { 'json' }

=back

=head1 TO DO

=over 4

=item Count the lines in the files

=item Code stats? Lines of code, lines of pod, lines of comments

=back

=head1 SOURCE AVAILABILITY

This code is in Github:

	git://github.com/briandfoy/mycpan-indexer.git

=head1 AUTHOR

brian d foy, C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright © 2010-2018, brian d foy <bdfoy@cpan.org>. All rights reserved.

You may redistribute this under the terms of the Artistic License 2.0.

=cut

1;
