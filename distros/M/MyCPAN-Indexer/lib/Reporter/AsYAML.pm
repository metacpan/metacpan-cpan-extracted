package MyCPAN::Indexer::Reporter::AsYAML;
use strict;
use warnings;

use base qw(MyCPAN::Indexer::Reporter::Base);
use vars qw($VERSION $logger);
$VERSION = '1.28';

use Carp;
use File::Basename;
use File::Spec::Functions qw(catfile);
use Log::Log4perl;
use YAML;

BEGIN {
	$logger = Log::Log4perl->get_logger( 'Reporter' );
	}

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

sub component_type { $_[0]->reporter_type }

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

		open my($fh), ">", $out_path or $logger->fatal( "Could not open $out_path: $!" );
		print $fh Dump( $info );

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

=item final_words( $Notes )

Right before backpan_indexer.pl is about to finish, it calls this method to
give the reporter a chance to do something at the end. In this case it does
nothing.

=cut

sub final_words { 1 };

=back

=head1 TO DO

=head1 SOURCE AVAILABILITY

This code is in Github:

	git://github.com/briandfoy/mycpan-indexer.git

=head1 AUTHOR

brian d foy, C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2008-2009, brian d foy, All Rights Reserved.

You may redistribute this under the same terms as Perl itself.

=cut

1;
