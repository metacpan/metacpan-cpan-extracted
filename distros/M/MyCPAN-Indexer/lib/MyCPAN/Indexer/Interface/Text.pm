package MyCPAN::Indexer::Interface::Text;
use strict;
use warnings;

use Log::Log4perl;

use parent qw(MyCPAN::Indexer::Component);
use vars qw($VERSION $logger);
$VERSION = '1.282';

=encoding utf8

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

=item component_type

This is an interface type

=cut

sub component_type { $_[0]->interface_type }

=item do_interface

=cut

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

	my $total = @{ $self->get_note('queue') };
	print "Processing $total distributions\n";
	print "One + = 1 distribution\n";

	my $count = 0;
	my $timer = time;

	while( 1 )
		{
		last if $self->get_note('Finished');

		unless( $count++ % 70 )
			{
			my $elapsed = time - $timer;
			$timer = time;

			print " $elapsed" unless $count < 70;
			printf "\n[%6d/%6d]", $count, $total;
			}

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

		}
	print "\n";

	my $collator = $self->get_coordinator->get_note( 'collator' );
	$collator->() if ref $collator eq ref sub {};
	}

=item skip_tick

=item success_tick

=item error_tick

Return a grapheme to represent what just happened.

=cut

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

Copyright © 2008-2018, brian d foy <bdfoy@cpan.org>. All rights reserved.

You may redistribute this under the terms of the Artistic License 2.0.

=cut

1;
