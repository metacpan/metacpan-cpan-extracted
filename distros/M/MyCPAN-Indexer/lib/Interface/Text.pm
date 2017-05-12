package MyCPAN::Indexer::Interface::Text;
use strict;
use warnings;

use Log::Log4perl;

use base qw(MyCPAN::Indexer::Component);
use vars qw($VERSION $logger);
$VERSION = '1.28';

=head1 NAME

MyCPAN::Indexer::Interface::Text - Present the run info as plain text

=head1 SYNOPSIS

Use this in backpan_indexer.pl by specifying it as the interface class:

	# in backpan_indexer.config
	interface_class  MyCPAN::Indexer::Interface::Text

=head1 DESCRIPTION

This class presents the information as the indexer runs, using plain text.

=head2 Methods

=over 4

=item do_interface( $Notes )


=cut

BEGIN {
	$logger = Log::Log4perl->get_logger( 'Interface' );
	}

sub component_type { $_[0]->interface_type }

sub do_interface
	{
	my( $self ) = @_;
	$logger->debug( "Calling do_interface" );

	my $config = $self->get_config;
	
	my $i = $config->indexer_class;
	eval "require $i; 1";
	
	print join( " ", 
		$config->indexer_class, 
		$config->indexer_class->VERSION 
		),
		"\n";

	print 'Processing ' . @{ $self->get_note('queue') } . " distributions\n";
	print "One * = 1 distribution\n";

	my $count = 0;
	while( 1 )
		{
		last if $self->get_note('Finished');

		local $| = 1;

		my $info = $self->get_note('interface_callback')->();

		my $method = do {
			if( not defined $info or ref $info ne ref {} ) { 'error_tick' }
			elsif( $info->{'completed'} ) { 'success_tick' }
			elsif( $info->{'skipped'} )   { 'skip_tick' }
			elsif( grep { exists $info->{$_} } qw( error fatal_error ) ) { 'error_tick' }
			else { 'error_tick' }
			};

		# if we fork, how does the interface class know what happened?
		$method = 'success_tick';

		print $self->$method();
		print "\n" unless ++$count % 70;

		}

	print "\n";
	}

sub skip_tick    { '.' }

sub success_tick { '+' }

sub error_tick   { '!' }


=back


=head1 SEE ALSO

MyCPAN::Indexer

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
