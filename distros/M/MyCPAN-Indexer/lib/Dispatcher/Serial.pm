package MyCPAN::Indexer::Dispatcher::Serial;
use strict;
use warnings;

use base qw(MyCPAN::Indexer::Component);
use vars qw($VERSION $logger);
$VERSION = '1.28';

use Log::Log4perl;

BEGIN {
	$logger = Log::Log4perl->get_logger( 'Dispatcher' );
	}

=head1 NAME

MyCPAN::Indexer::Dispatcher::Serial - Pass out work in the same process

=head1 SYNOPSIS

Use this in C<backpan_indexer.pl> by specifying it as the queue class:

	# in backpan_indexer.config
	dispatch_class  MyCPAN::Indexer::Dispatcher::Serial

=head1 DESCRIPTION

This class takes the list of distributions to process and passes them
out to the code that will do the work.

=head2 Methods

=over 4

=item get_dispatcher

Adds the C<dispatcher> key with a code reference.

=cut

sub component_type { $_[0]->dispatcher_type }

sub get_dispatcher
	{
	my( $self ) = @_;

	$self->get_coordinator->set_note( 
		'interface_callback',
		$self->_make_interface_callback,
		)
	}

sub _make_interface_callback
	{
	my( $self ) = @_;
	
	my $Notes = {};

	$Notes->{$_}           = [] foreach qw(PID recent errors );
	
	$Notes->{Total}        = scalar @{ $self->get_note( 'queue' ) };
	$Notes->{Left}         = $Notes->{Total};
	$Notes->{Errors}       = 0;
	$Notes->{Done}         = 0;
	$Notes->{Started}      = scalar localtime;
	$Notes->{Finished}     = 0;

	$Notes->{queue_cursor} = 0;

	foreach my $key ( keys %$Notes )
		{
		$self->set_note( $key, $Notes->{$key} );
		}

	$Notes->{interface_callback} = sub {
		$logger->debug( "Start: Finished: $Notes->{Finished} Left: $Notes->{Left}" );

		unless( $self->get_note('Left') )
			{
			$self->set_note('Finished', 'true' );
			return;
			};

		$self->set_note_unless_defined('_started', time);

		$self->set_note('_elapsed', time - $self->get_note('_started') );
		$self->set_note('Elapsed', _elapsed( $self->get_note('_elapsed') ) );

		my $item = ${ $self->get_note('queue') }[ $self->get_note('queue_cursor') ];
		$self->increment_note( 'queue_cursor' );

		$self->increment_note( 'Done' );
		$self->set_note('Left', $self->get_note('Total') - $self->get_note('Done') );
		$logger->debug( 
			sprintf "Total: %s Done: %s Left: %s Finished: %s",
				map { $self->get_note( $_ ) } qw(Total Done Left Finished)
			);

		no warnings;
		$self->set_note('Rate', sprintf "%.2f / sec ",
			eval { $self->get_note('Done') / $self->get_note('_elapsed') }
			);

		my $info = $self->get_note('child_task')->( $item );

		$info;
		};
		
	}

BEGIN {
my %hash = ( days => 864000, hours => 3600, minutes => 60 );

sub _elapsed
	{
	my $seconds = shift;

	my @v;
	foreach my $key ( qw(days hours minutes) )
		{
		push @v, int( $seconds / $hash{$key} );
		$seconds -= $v[-1] * $hash{$key}
		}

	push @v, $seconds;

	sprintf "%dd %02dh %02dm %02ds", @v;
	}
}

1;

=back

=head1 SEE ALSO

MyCPAN::Indexer, MyCPAN::Indexer::Tutorial

=head1 SOURCE AVAILABILITY

This code is in Github:

	git://github.com/briandfoy/mycpan-indexer.git

=head1 AUTHOR

brian d foy, C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2009, brian d foy, All Rights Reserved.

You may redistribute this under the same terms as Perl itself.

=cut

