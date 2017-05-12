package MooseX::FSM;

use Moose ();
use Carp qw(carp croak cluck confess);
use MooseX::FSM::State;

use Moose::Exporter


=head1 NAME

MooseX::FSM - The great new MooseX::FSM!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

MooseX::FSM is a moosish Finite State Machine

Perhaps a little code snippet.

    use MooseX::FSM;

    my $fsm = MooseX::FSM->new( );


	state_table = { start        => { enter => init, input => scan_dirs, exit => finish, transition => { add_dir => 'process_dir' } },
					process_dir  => { enter => new_dir, input => do_dir,  exit => done_dir, transition => { add_file => 'process_file', processed_all_files => start },
					process_file => { enter => new_file, input => do_file, exit => done_file, transition => { processed_file => process_dir }
	...

	has 'start' (
		is			=> 'ro',
		isa			=> 'MooseX::FSM::State',
		metaclass	=> 'state',
		enter		=> 'init',
		input		=> [ scan_dirs , add_dir => 'process_dir' ],
		transition	=> report_dir,
	)

	New syntax sugar coming soon
	state 'start' (
		enter => 
	)

=head1 EXPORT

A list of  that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 FUNCTIONS

=head2 function1

=head2 init_meta
the init_meta function is used internaly by Moose to setup the base class which MooseX::FSM provides
=cut

Moose::Exporter->setup_import_methods ( also => 'Moose');

sub init_meta {
	shift;
	my %options = @_;
	my $meta = Moose->init_meta(%options);

	Moose::Util::MetaRole::apply_base_class_roles (
		for_class	=> $options{for_class},
		roles 		=> [ 'MooseX::FSM::Role::Object'],
	);
	return $meta;
}

1;

package MooseX::FSM::Role::Object;

use Moose::Role;
use Carp;

#after BUILDALL => sub  {
#	my $self = shift;
#
#	if ($self->start_state) {
##		$meta->get_attribute('start_state');
#
#		$self->transition_to_state($self->start_state);
#		
#	} else {
#
#		carp __PACKAGE__ . " needs to have a 'start_state' state";
#	}
#	
#};

has 'state_table' => (
	is			=> 'ro',
);

has 'current_state' => (
	is		=> 'rw',
	trigger => \&transition_to_state,
);

has 'start_state' => (
	is		=> 'ro',
	required	=> 1,
);


=head2 debug
a simple debug method to log any messages apprioriately
=cut
sub debug {
	my ($self, $message) = @_;
#	if ($self->is_debugging) {
#		print $message;
#	}
}

sub error {
	my ($self, $message, @rest) = @_;
	carp "error: $message";
}

sub start {
	my $self = shift;
	$self->debug ("going to transition into the start state\n");
#	$self->transition_to_state($self->start_state());
	$self->current_state($self->start_state());
}

sub transition_to_state {
	my ($self, $state, @rest)  = @_;
	$self->debug( "transition to state $state\n");
#	my $meta = $self->meta;

	my @keep_funcs = qw( current_state transition_to_state debug meta state_table error ); 
	my $keep_re = join "|", @keep_funcs;
	$keep_re = qr/$keep_re/;
	my $meta = $self->meta();

	foreach my $method ($meta->get_all_methods) {
		next if ($method =~ $keep_re);
		$self->debug("\t -> removing " . $method->package_name() . "::". $method->name() . "\n");
		$meta->remove_method($method->name);
	}

	$self->debug("done remove methods\n");

	if (my $state_attr =$meta->get_attribute($state)) {
#		 $meta->get_attribute($state);
		# call exit on current_state
#		if ($self->current_state() && $self->current_state()->has_exit() ) {
#			$self->current_state()->exit();
#		}
		# call transition if exists

		# compose new class
		my $input = $state_attr->input(); # :->get_value($self);
		my $transitions = $state_attr->transitions();
		if ($input && ref ($input) eq 'HASH') {
			while ( my ($key, $sub) = each %$input) {
#				$self->debug_print_methods($state_attr);
				$self->debug("adding method : " . $key . ": ". $sub .   "\n");
#				my $method = Moose::Meta::Method->wrap($sub,{ name=>$key, package_name => ref $self}); 
				
				$meta->add_method($key,$sub); 
#				$meta->add_method($method);
				if (my $new_state =  $transitions->{$key}) { 
					$self->debug("\tsetting transition for input $key to $new_state\n");
					# TODO cache transtion sub routines
					$meta->add_after_method_modifier($key, sub { my $self = shift; return if ($self->current_state() eq $new_state); $self->current_state($new_state); });
				}
			}

		}
		# call enter on new state
		my $enter = $state_attr->enter();
		&$enter($self);
		$self->debug ("setting up new meta object\n");

	}
	else {
		$self->error("could not transition to '$state' as it doesn't exist");
	}
		#my $start_state = $meta->get_attribute($start_state_attribute);
	return $meta; #$self->meta($meta);
}


sub debug_print_attrs {
	my $self = shift;
	my $meta = $self->meta();

	foreach my $attr ($meta->get_all_attributes() ) {
		$self->debug("\t -> attribute -> " . $attr->name() . "\n");
	}
}

sub debug_print_methods {
	my $self = shift;
	my $obj = shift;
	my $meta;
	if ($obj ) {
		$meta = $obj->meta();
	} else {
		$meta =  $self->meta();
	}

	foreach my $method ($meta->get_all_methods() ) {
		$self->debug ("\t -> method -> " . $method->name() . "\n");
	}
}
1;
=head1 AUTHOR

Gordon Irving, C<< <goraxe at goraxe dot me dotty uk> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-moosex-fsm at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=moosex-fsm>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc MooseX::FSM


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=moosex-fsm>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/moosex-fsm>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/moosex-fsm>

=item * Search CPAN

L<http://search.cpan.org/dist/moosex-fsm>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Gordon Irving, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut
no Moose;
1; # End of MooseX::FSM
