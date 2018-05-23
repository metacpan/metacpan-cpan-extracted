package MyCPAN::Indexer::Interface::ShowDist;
use strict;
use warnings;

use Log::Log4perl;

use parent qw(MyCPAN::Indexer::Component);
use vars qw($VERSION $logger);
$VERSION = '1.282';

=encoding utf8

=head1 NAME

MyCPAN::Indexer::Interface::ShowDist - Show dists as MyCPAN processes them

=head1 SYNOPSIS

Use this in backpan_indexer.pl by specifying it as the interface class:

	# in backpan_indexer.config
	interface_class  MyCPAN::Indexer::Interface::ShowDist

=head1 DESCRIPTION

This class presents the information as the indexer runs, using plain text.

=head2 Methods

=over 4

=cut

BEGIN {
	$logger = Log::Log4perl->get_logger( 'Interface' );
	}

=item component_type

This is an interface type

=cut

sub component_type { $_[0]->interface_type }

=item do_interface()


=cut

sub do_interface
	{
	my( $self ) = @_;
	$logger->debug( "Calling do_interface" );

	my $config = $self->get_config;

	my $indexer = $self->get_coordinator->get_component( 'indexer' );

	print join( " ",
		$config->indexer_class,
		$indexer->VERSION
		),
		"\n";

	my $total = @{ $self->get_note('queue') };
	my $width = eval { int( log($total)/log(10) + 1 ) } || 5;
	print "Processing $total distributions\n";

	my $count = 0;
	while( 1 )
		{
		last if $self->get_note('Finished');

		local $| = 1;

		my $info = $self->get_note('interface_callback')->();
		my $status = do {
			   if( exists $info->{skipped} )             { 'skipped' }
			elsif( exists $info->{skip_error} )          { 'previous error (skipped)' }
			elsif( exists $info->{run_info}{error} )     { $self->get_error($info) }
			elsif( exists $info->{run_info}{completed} ) { 'completed' }
			else                                         { 'unknown'   }
			};

		printf "[%*d/%d] %s ---> %s\n", $width, ++$count, $total,
			$info->{dist_info}{dist_basename} || '(unknown dist???)',
			$status;
		}

	my $collator = $self->get_coordinator->get_note( 'collator' );
	$collator->();
	}

BEGIN {
my @patterns = (
	qr/Malformed UTF-8/p,
	qr/No child process/p,
	qr/Alarm rang/p,
	);

=item get_error

Returns the error message that most likely was the big problem.

=cut

sub get_error
	{
	my( $self, $info ) = @_;

	my $r = $info->{run_info};

	my @errors = map { $r->{$_} || () } qw(error fatal_error);

	foreach my $pattern ( @patterns )
		{
		return ${^MATCH} if $errors[0] =~ m/$pattern/p;
		}

	}
}

=back

=head1 SEE ALSO

MyCPAN::Indexer

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
