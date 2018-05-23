package MyCPAN::Indexer::Coordinator;
use strict;
use warnings;

use vars qw($VERSION $logger);
$VERSION = '1.282';

use Carp;
use File::Basename;
use File::Spec::Functions qw(catfile);
use Log::Log4perl;
use YAML;

BEGIN {
	$logger = Log::Log4perl->get_logger( 'Reporter' );
	}

=encoding utf8

=head1 NAME

MyCPAN::Indexer::Coordinator - Provide a way for the various components to communicate

=head1 SYNOPSIS

	my $componentA   = MyCPAN::Indexer::ComponentA->new;
	my $componentB   = MyCPAN::Indexer::ComponentB->new;

	my $coordinator = MyCPAN::Indexer::Coordinator->new;

	# each component gets a reference
	$componentA->set_coordinator( $coordinator );
	$componentB->set_coordinator( $coordinator );

	# the coordinator knows about all of the components
	$coordinator->set_component( 'A', $componentA );
	$coordinator->set_component( 'B', $componentB );

	$componentA->set_note( 'cat', 'Buster' );

	my $cat = $componentB->get_note( 'cat' );

	# Any component can find any other component
	$componentB->get_coordinator->get_component( 'A' )->method_in_A;

=head1 DESCRIPTION

The coordinator keeps track of the components in C<MyCPAN::Indexer>. It acts
as a central point where all comunication can flow so everything can talk to
everything with only 2N connections.

It automatically sets up a notes object to act as a scratchpad. Every component
can read from and write to the notes object.

=cut

=head2 Methods

=over 4

=item new

Create a new Coordinator object.

=cut

sub new
	{
	my( $class ) = @_;

	require MyCPAN::Indexer::Notes;

	my $self = bless {
		notes    => MyCPAN::Indexer::Notes->new,
		info     => {},
		config   => '',
		}, $class;

	}

=item get_component( NAME )

Retrieve the component named NAME.

=cut

sub get_component { $_[0]->{components}{$_[1]}         }

=item set_component( NAME, REFERENCE )

Set the component with name NAME to REFERENCE. So far there are no restrictions
on reference, but it should be a subclass of C<MyCPAN::Indexer::Component> or at
least something that acts like that class.

=cut

sub set_component { $_[0]->{components}{$_[1]} = $_[2] }

=back

=head2 Dispatch to notes

As a convenience, these methods dispatch to the notes object:

	get_note
	set_note
	get_config
	set_config
	increment_note
	decrement_note
	push_onto_note
	unshift_onto_note
	get_note_list_element
	set_note_unless_defined

=cut

BEGIN {
sub get_notes { $_[0]->{notes}                             }

my @methods_to_dispatch_to_notes = qw(
	get_note
	set_note
	increment_note
	decrement_note
	push_onto_note
	unshift_onto_note
	get_note_list_element
	set_note_unless_defined
	);


foreach my $method ( @methods_to_dispatch_to_notes )
	{
	no strict 'refs';
	*{$method} = sub {
		my $self = shift;
		$self->get_notes->$method( @_ );
		}
	}

}

=head2 Organic methods

These methods are defined in this class and work to interact with some
of the things the coordinator is tracking.

=over 4

=item get_config

=item set_config( CONFIG )

Get or set the configuration objects.

=cut

sub get_config { $_[0]->{config}         }
sub set_config { $_[0]->{config} = $_[1] }

=item get_info

=item set_info( INFO_OBJ )

Get or set the info object. This is the thing that records the data
collected during the index.

=cut

sub get_info   { $_[0]->{info}           }
sub set_info   { $_[0]->{info}   = $_[1] }

BEGIN {
	my @components = (
	[qw( queue       get_queue     )],
	[qw( dispatcher  get_dispatcher)],
	[qw( worker      get_task      )],
	[qw( indexer     run           )],
	[qw( reporter    get_reporter  )],
	[qw( interface   do_interface  )],
	[qw( application activate      )],
	[qw( collator    get_collator  )],
	);

	foreach my $tuple ( @components )
		{
		my( $component, $required_method ) = @$tuple;

		no strict 'refs';
		*{"get_${component}"} = sub { $_[0]->get_component( $component ) };
		*{"set_${component}"} = sub {
			die "$component must implement $required_method"
				unless eval { $_[1]->can( $required_method ) };
			$_[0]->set_component( $component, $_[1] );
			};
		}
	}

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
