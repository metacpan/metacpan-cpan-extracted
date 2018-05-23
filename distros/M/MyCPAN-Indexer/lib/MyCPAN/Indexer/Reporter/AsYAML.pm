package MyCPAN::Indexer::Reporter::AsYAML;
use strict;
use warnings;

use parent qw(MyCPAN::Indexer::Reporter::Base);
use vars qw($VERSION $logger);
$VERSION = '1.282';

use Carp;
use File::Basename;
use File::Path qw(make_path);
use File::Spec::Functions qw(catfile);
use Log::Log4perl;
use Clone qw(clone);
use YAML::Syck qw(Dump);

BEGIN {
	$logger = Log::Log4perl->get_logger( 'Reporter' );
	}

=encoding utf8

=head1 NAME

MyCPAN::Indexer::Reporter::AsYAML - Save the result as a YAML file

=head1 SYNOPSIS

Use this in backpan_indexer.pl by specifying it as the reporter class:

	# in backpan_indexer.config
	reporter_class  MyCPAN::Indexer::Reporter::AsYAML

=head1 DESCRIPTION

This class takes the result of examining a distribution and saves it.

=head2 Methods

=over 4

=item get_reporter( $Notes )

C<get_reporter> sets the C<reporter> key in the C<$Notes> hash reference. The
value is a code reference that takes the information collected about a distribution
and dumps it as a YAML file.

See L<MyCPAN::Indexer::Tutorial> for details about what C<get_reporter> expects
and should do.

=cut

sub get_reporter
	{
	#TRACE( sub { get_caller_info } );

	my( $self ) = @_;

	my $reporter = sub {
		my( $info ) = @_;

		unless( defined $info )
			{
			$logger->error( "info is undefined!" );
			return;
			}

		my $out_path = $self->get_report_path( $info );
		my $dir = dirname( $out_path );
		unless( -d $dir )
			{
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
		my $dist = $clone->{dist_info}{dist_basename};

		local $SIG{__WARN__} = sub {
			$logger->warn( "Error writing to YAML output for $dist: @_" );
			};

		foreach my $key ( keys %$clone ) {
			delete $clone->{$key} if $key =~ /^_/;
			}

		print $fh Dump( $clone );
		}
		$logger->error( "$out_path is missing!" ) unless -e $out_path;

		1;
		};

	$self->set_note( 'reporter', $reporter );
	1;
	}

=item get_report_file_extension

Returns the extension for reports from this reporter. Since we're making
YAML files, that's C<yml>.

=cut

sub get_report_file_extension { 'yml' }

=back

=head1 TO DO

=head1 SOURCE AVAILABILITY

This code is in Github:

	git://github.com/briandfoy/mycpan-indexer.git

=head1 AUTHOR

brian d foy, C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright © 2008-2018, brian d foy <bdfoy@cpan.org>. All rights reserved.

You may redistribute this under the terms of the Artistic License 2.0.

=cut

1;
