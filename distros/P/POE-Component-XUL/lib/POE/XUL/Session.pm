package POE::XUL::Session;

use strict;
use warnings;
use Carp;
use POE::XUL::ChangeManager;
use POE::XUL::EventManager;
use XUL::Node::Application;
use Time::HiRes;

#use XUL::Node::ChangeManager;
#use XUL::Node::EventManager;

# public ----------------------------------------------------------------------

sub new {
	my $class = shift;
	my $self = bless {
		change_manager	=> POE::XUL::ChangeManager->new,
		event_manager	=> POE::XUL::EventManager->new,
#		change_manager	=> XUL::Node::ChangeManager->new,
#		event_manager	=> XUL::Node::EventManager->new,
		start_time		=> Time::HiRes::time(),
		@_,
	}, $class;
	$self->change_manager->event_manager($self->event_manager);
	return $self;
}

sub handle_boot {
	my ($self, $request) = @_;
	# look for a custom POE callback for this request
	if (exists($self->{apps}->{$request->{name}})) {
		return $self->run_and_flush($self->{apps}->{$request->{name}},$request,$self);
	}
#	return '' if ($self->{opts}->{disable_others});
	return $self->run_and_flush
		(XUL::Node::Application->get_constructor($request->{name}));
}

sub handle_event {
	my ($self, $request) = @_;
	my $event = $self->make_event($request);
	return $self->run_and_flush(sub { $self->fire_event($event,$request,$self) },@_);
}

sub destroy {
	my $self = shift;
	$self->{change_manager}->destroy;
}

# private ---------------------------------------------------------------------

# these used to pop instead of @_
sub run_and_flush  { shift->change_manager->run_and_flush(@_) }
sub fire_event     { shift->event_manager->fire_event(@_) }
sub make_event     { shift->event_manager->make_event(@_) }
sub change_manager { shift->{change_manager} }
sub event_manager  { shift->{event_manager} }

1;
