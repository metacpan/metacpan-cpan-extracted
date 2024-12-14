use v5.12;
use warnings;

package Neo4j::Driver::Events 1.02;
# ABSTRACT: Event manager for Neo4j::Driver plug-ins


# This package is not part of the public Neo4j::Driver API.
# (except as far as documented in Plugin.pm)


use Carp qw(croak);
our @CARP_NOT = qw(
	Neo4j::Driver::Result::Bolt
	Neo4j::Driver::Result::Jolt
	Neo4j::Driver::Result::JSON
	Neo4j::Driver::Result::Text
);

use Scalar::Util qw(weaken);


our $STACK_TRACE = 0;  # die with stack trace on error; for debugging only


sub new {
	# uncoverable pod
	my ($class) = @_;
	
	my $self = bless {}, $class;
	$self->_init_default_handlers;
	return $self;
}


# Set up the default handlers for generic events when creating the manager.
sub _init_default_handlers {
	my ($self) = @_;
	
	$self->{default_handlers}->{error} = sub {
		# Unlike regular handlers, default handlers don't receive a callback.
		my ($error) = @_;
		
		die $error->trace if $STACK_TRACE;
		
		# Join all errors into a multi-line string for backwards compatibility with pre-0.36.
		my @errors;
		do { push @errors, $error } while $error = $error->related;
		@errors = map { $_->as_string } @errors;
		croak join "\n", @errors;
	};
	weaken $self;
}


sub add_handler {
	# uncoverable pod (see Plugin.pm)
	my ($self, $event, $handler, @extra) = @_;
	
	croak "Too many arguments for method 'add_handler'" if @extra;
	croak "Event handler must be a subroutine reference" unless ref $handler eq 'CODE';
	croak "Event name must be defined" unless defined $event;
	
	push @{$self->{handlers}->{$event}}, $handler;
}


sub trigger {
	# uncoverable pod (see Plugin.pm)
	my ($self, $event, @params) = @_;
	
	my $default_handler = $self->{default_handlers}->{$event};
	my $handlers = $self->{handlers}->{$event}
		or return $default_handler ? $default_handler->(@params) : ();
	
	my $callback = $default_handler // sub {};
	for my $handler ( reverse @$handlers ) {
		my $continue = $callback;
		$callback = sub { $handler->($continue, @params) };
	}
	return $callback->();
	
	# Right now, ALL events get a continuation callback.
	# But this will almost certainly change eventually.
}


# Tell a new plugin to register itself using this manager.
sub _register_plugin {
	my ($self, $plugin) = @_;
	
	croak sprintf "Package %s is not a Neo4j::Driver::Plugin", $plugin unless $plugin->DOES('Neo4j::Driver::Plugin');
	croak sprintf "Method register() not implemented by package %s (is this a Neo4j::Driver plug-in?)", $plugin unless $plugin->can('register');
	croak "Neo4j::Driver->plugin() requires a plug-in object" unless ref $plugin ne '';
	
	$plugin->register($self);
}


1;
