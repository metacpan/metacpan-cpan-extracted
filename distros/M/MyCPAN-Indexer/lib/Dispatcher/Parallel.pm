package MyCPAN::Indexer::Dispatcher::Parallel;
use strict;
use warnings;

use base qw(MyCPAN::Indexer::Component);
use vars qw($VERSION $logger);
$VERSION = '1.28';

use Log::Log4perl;

BEGIN {
	# override since Tk overrides exit and this needs the real exit
	no warnings 'redefine';
	use Parallel::ForkManager;

	sub Parallel::ForkManager::finish { my ($s, $x) = @_;
	  if ( $s->{in_child} ) {
		CORE::exit ($x || 0);
	  }
	  if ($s->{max_proc} == 0) { # max_proc == 0
		$s->on_finish($$, $x ,$s->{processes}->{$$}, 0, 0);
		delete $s->{processes}->{$$};
	  }
	  return 0;
	}
}

BEGIN {
	$logger = Log::Log4perl->get_logger( 'Dispatcher' );
	}

=head1 NAME

MyCPAN::Indexer::Dispatcher::Parallel - Pass out work to sub-processes

=head1 SYNOPSIS

Use this in C<backpan_indexer.pl> by specifying it as the queue class:

	# in backpan_indexer.config
	dispatch_class  MyCPAN::Indexer::Dispatcher::Parallel

=head1 DESCRIPTION

This class takes the list of distributions to process and passes them
out to the code that will do the work.

=head2 Methods

=over 4

=item get_dispatcher

Takes the C<$Notes> hash and adds the C<dispatcher> key with a code
reference. This module uses C<Parallel::ForkManager> to run
jobs in parallel, and looks at the

It also sets up keys for PID, whose value is an anonymous array
of process IDs. That array matches up with the one in the key
C<recent> which keeps track of the distributions it's processing.
It adds:

	dispatcher => sub { ... },
	PID        => [],
	recent     => [],

=cut

sub component_type { $_[0]->dispatcher_type }

sub get_dispatcher
	{
	my( $self ) = @_;

	$self->set_note( 'Threads',            $self->get_config->parallel_jobs );
	$self->set_note( 'dispatcher',         $self->_make_forker );
	$self->set_note( 'interface_callback', $self->_make_interface_callback );
	}

sub _make_forker
	{
	my( $self ) = @_;

	Parallel::ForkManager->new(
		$self->get_config->parallel_jobs || 1 
		);
	}

sub _make_interface_callback
	{
	my( $self ) = @_;

	foreach my $key ( qw(PID recent errors ) )
		{
		$self->set_note( $key, [] );
		}
	
	$self->set_note( 'Total',    scalar @{ $self->get_note( 'queue' ) } );
	$self->set_note( 'Left',     $self->get_note('Total') );
	$self->set_note( 'Errors',   0 );
	$self->set_note( 'Done',     0 );
	$self->set_note( 'Started',  scalar localtime );
	$self->set_note( 'Finished', 0 );

	$self->set_note( 'queue_cursor', 0 );

	my $interface_callback = sub {
		$self->_remove_old_processes;

		$logger->debug( sprintf
			"Finished: %s Left: %s", 
			map { $self->get_note( $_ ) } qw(Finished Left)
			);

		unless( $self->get_note( 'Left' ) )
			{
			$logger->debug( "Waiting on all children [" . time . "]" );
			$self->get_note( 'dispatcher' )->wait_all_children;
			$self->set_note( 'Finished', 1 );
			return;
			};

		$self->set_note_unless_defined( '_started', time );

		$self->set_note( 
			'_elapsed', 
			time - $self->get_note( '_started' )
			);
			
		$self->set_note( 
			'Elapsed',
			_elapsed( $self->get_note( '_elapsed' ) )
			);

		my $item = $self->get_note_list_element( 
			'queue',  
			$self->increment_note( 'queue_cursor' ) 
			);

		my $info;
		
		if( my $pid = $self->get_note( 'dispatcher' )->start )
			{ #parent
			$self->unshift_onto_note( 'PID',    $pid );
			$self->unshift_onto_note( 'recent', $item );
			
			$self->increment_note( 'Done' );

			$self->set_note( 
				'Left', 
				$self->get_note( 'Total' ) - $self->get_note( 'Done' )
				);

			$logger->debug( 
				sprintf "Total: %s Done: %s Left: %s Finished: %s",
				map { $self->get_note( $_ ) } qw( Total Done Left Finished )
				);
				
			no warnings;
			$self->set_note( 
				'Rate', 
				eval { $self->get_note( 'Done' ) / $self->get_note( '_elapsed' ) }
				);

			}
		else
			{ # child
			$info = $self->get_note( 'child_task' )->( $item );
			$self->get_note( 'dispatcher' )->finish;
			$logger->error( "The child is still running!" );
			}
		
		$info;
		};
		
	$self->set_note( 'interface_callback', $interface_callback );
	}

sub _remove_old_processes
	{
	my( $self ) = @_;

	my $pid = $self->get_note( 'PID' );
	
	my @delete_indices = grep
		{ ! kill 0, $pid->[$_] }
		0 .. $#$pid;

	my $recent = $self->get_note( 'recent' );
	
	foreach my $index ( reverse @delete_indices )
		{
		splice @$recent, $index, 1;
		splice @$pid, $index, 1;
		}
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

Copyright (c) 2008-2009, brian d foy, All Rights Reserved.

You may redistribute this under the same terms as Perl itself.

=cut
