package MooseX::FSM::State;

use Moose::Role;

has enter => (
	is		=> 'rw',
	isa		=> 'CodeRef',
	lazy	=> 1,
	default => sub {
			sub {
					my $self = shift; 
					$self->debug( "default enter called"); 
			}; 
		},
);


has exit => (
	is		=> 'rw',
	isa		=> 'CodeRef',
	lazy	=> 1,
	default => sub { sub { my $self = shift; $self->debug( "default exit called"); }; },
);

has input => (
	is		=> 'rw',
	isa		=> 'HashRef',
	lazy	=> 1,
	default	=> sub { {}; },
);
=head2 transitions
transitions define how to move from one state to another.  Its composed of a hashref with the input function and the name of the state to transition to once that function has been called
=cut
has transitions => (
	is		 => 'ro',
	isa		 => 'HashRef',
	default  => sub { {}; },
	required => 1,
);
1;

package Moose::Meta::Attribute::Custom::Trait::State;
sub register_implementation {'MooseX::FSM::State'}

1;
