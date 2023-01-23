use 5.010;
use strict;
use warnings;
use utf8;

package Neo4j::Driver::Events;
# ABSTRACT: Event manager for Neo4j::Driver plug-ins
$Neo4j::Driver::Events::VERSION = '0.34';

# This package is not part of the public Neo4j::Driver API.
# (except as far as documented in Plugin.pm)


use Carp qw(croak);
our @CARP_NOT = qw(Neo4j::Driver);


sub new {
	# uncoverable pod
	my ($class) = @_;
	
	return bless {}, $class;
}


sub add_event_handler {
	# uncoverable pod (see Deprecations.pod)
	warnings::warnif deprecated => __PACKAGE__ . "->add_event_handler() is deprecated";
	shift->add_handler(@_);
}


sub add_handler {
	# uncoverable pod (see Plugin.pm)
	my ($self, $event, $handler, @extra) = @_;
	
	croak "Too many arguments for method 'add_handler'" if @extra;
	croak "Event handler must be a subroutine reference" unless ref $handler eq 'CODE';
	croak "Event name must be defined" unless defined $event;
	
	push @{$self->{handlers}->{$event}}, $handler;
}


sub trigger_event {
	# uncoverable pod (see Deprecations.pod)
	warnings::warnif deprecated => __PACKAGE__ . "->trigger_event() is deprecated";
	shift->trigger(@_);
}


sub trigger {
	# uncoverable pod (see Plugin.pm)
	my ($self, $event, @params) = @_;
	
	my $default_handler = $self->{default_handlers}->{$event};
	my $handlers = $self->{handlers}->{$event}
		or return $default_handler ? $default_handler->() : ();
	
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
	
	croak "Can't locate object method new() via package $plugin (perhaps you forgot to load \"$plugin\"?)" unless $plugin->can('new');
	croak "Package $plugin is not a Neo4j::Driver::Plugin" unless $plugin->DOES('Neo4j::Driver::Plugin');
	croak "Method register() not implemented by package $plugin (is this a Neo4j::Driver plug-in?)" unless $plugin->can('register');
	warnings::warnif deprecated => "Neo4j::Driver->plugin() with module name is deprecated" if ref $plugin eq '';
	
	$plugin = $plugin->new if ref $plugin eq '';
	$plugin->register($self);
}


1;
