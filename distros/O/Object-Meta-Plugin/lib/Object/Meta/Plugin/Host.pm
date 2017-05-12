#!/usr/bin/perl
# $Id: Host.pm,v 1.12 2003/11/29 14:35:24 nothingmuch Exp $

package Object::Meta::Plugin::Host;

use strict;
use warnings;

use autouse Carp => qw(croak);
use Tie::RefHash;

our $VERSION = 0.01;
our $AUTOLOAD;

sub new {
	my $pkg = shift;
	my $self = {
		plugins => {}, # plugin ref hash
		methods => {}, # method look up, with an array of plugin refs per method
	};
	
	tie %{ $self->{plugins} }, 'Tie::RefHash';
	
	bless $self, $pkg;
}

sub self { # used when we're not plugged
	return $_[0];
}

sub plugins {
	my $self = shift->self; # in case we're plugged
	return $self->{plugins};
}

sub methods {
	my $self = shift->self; # in case we're plugged
	return $self->{methods};
}

sub plug {
	my $self = shift->self; # in case we're plugged
	my $plugin = shift;
	
	croak "Doesn't look like a plugin" if (grep { not $plugin->can($_) } qw/init/);

	return $self->register($plugin->init(@_) or croak "init() did not return an export list");
}

sub unplug { #
	my $self = shift->self; # in case we're plugged

	foreach my $plugin (@_){
		foreach my $method (keys %{ $self->methods }){
			next unless $plugin->can($method);
			@{ $self->methods->{$method} } = grep { $_ != $plugin } @{ $self->methods->{$method} };
			delete $self->methods->{$method} unless @{ $self->methods->{$method} };
		}
		
		delete $self->plugins->{$plugin};
	}
	# munge the stack
}

sub register { # export list
	my $self = shift->self; # in case we're plugged
	my $x = shift;
	
	# create the stack
	
	croak "That doesn't look like a valid export list" if (!$x or grep { not $x->can($_) } qw/list plugin exists merge unmerge/);
	
	foreach my $method ($x->list()){
		croak "Method $method is reserved for use by the context object" if Object::Meta::Plugin::Host::Context->UNIVERSAL::can($method);
		croak "Can't locate object method \"$method\" via package  \"", (ref $x->plugin()), "\"" unless $x->plugin->can($method);
		
		my $stack = $self->stack($method) || [];
		
		push @{$stack}, $x->plugin();
		
		$self->stack($method, $stack);
	}

	exists $self->plugins->{$x->plugin} ? $self->plugins->{$x->plugin}->merge($x) : $self->plugins->{$x->plugin} = $x; # should return success
}

sub unregister {
	my $self = shift->self;
	
	foreach my $x (@_){
		croak "That doesn't look like a valid export list" if (!$x or grep { not $x->can($_) } qw/list plugin/);
		
		$self->plugins->{$x->plugin}->unmerge($x);
		
		if ($x->list()){
			foreach my $method ($x->list()){
				next unless $self->stack($method);
				
				@{ $self->stack($method) } = grep { $_ != $x->plugin } @{ $self->stack($method) };
				
				delete $self->methods->{$method} unless (@{ $self->stack($method) });
			}
		} else {
			$self->unplug($x->plugin());
		}
	}
}

sub stack { # : lvalue { # grant access to the stack of a certain method.
	my $self = shift->self; # in case we're plugged
	my $method = shift;
	
	@_ ? ($self->methods->{$method} = shift) : $self->methods->{$method};
}

sub can { # provide a subref you can goto
	my $self = shift->self; # in case we're plugged
	my $method = shift;
	return $self->UNIVERSAL::can($method) || ($self->stack($method) && sub { $AUTOLOAD = "::" . $method; goto &AUTOLOAD }) || undef;
}

sub AUTOLOAD { # where the magic happens
	my $super = shift;
	my $self = $super->self; # in case we're plugged

	$AUTOLOAD =~ /.*::(.*?)$/;
	my $method = $1;
	croak "Method $method is reserved for use by the context object" if Object::Meta::Plugin::Host::Context->UNIVERSAL::can($method);
	
	return undef if $method eq 'DESTROY';
	my $stack = $self->stack($method) or croak "Can't locate object method \"$method\" via any plugin in $self";
	Object::Meta::Plugin::Host::Context->new($super, ${ $stack }[ $#$stack ])->$method(@_); # __PACKAGE__::Context ?
}

package Object::Meta::Plugin::Host::Context; # the wrapper object which defines the context of a plugin

use strict;
use warnings;

use autouse Carp => qw(croak);

our $VERSION = 0.01;
our $AUTOLOAD;

sub new {
	my $pkg = shift;
	
	my $self = bless {
		host => shift,
		plugin => shift,
		instance => shift || 0, # a plugin can be plugged into several slots, each of which needs it's own context
	}, $pkg;
	
	$self;
}

sub offset { # get a context with a numerical offset
	my $self = shift;
	my $offset = shift;
	
	Object::Meta::Plugin::Host::Context::Offset->new($self->host,$self->plugin,$offset,$self->{instance});
}

sub prev { # an overlying method - call a context one above
	my $self = shift;
	$self->offset(1);
}

sub next { # an underlying method - call a context one below
	my $self = shift;
	$self->offset(-1);
}

sub super { # the real self: Object::Meta::Plugin::Host
	my $self = shift;
	$self->{host};
}
sub host { goto &super }

sub plugin {
	my $self = shift;
	$self->{plugin};
}
sub self { goto &plugin }

sub can { # try to return the correct method.
	my $self = shift;
	my $method = shift;
	$self->UNIVERSAL::can($method) || $self->plugin->can($method) || $self->host->can($method); # it's one of these, in that order
}

sub AUTOLOAD {
	my $self = shift;
	
	$AUTOLOAD =~ /.*::(.*?)$/;
	my $method = $1;
	return undef if $method eq 'DESTROY';
	
	if (${ $self->super->self->plugins }{$self->plugin}->exists($method)){ # examine the plugin's export list in the host
		### stray from magic - this is as worse as it should get
		unshift @_, $self; # return self to the argument list. Should be O(1). lets hope.
		goto &{ $self->plugin->can($method) or croak ($self->plugin . " can't $method") };
	} else {
		$self->host->$method(@_);
	}
}

package Object::Meta::Plugin::Host::Context::Offset; # used to implement next and previous.

use strict;
use warnings;
use autouse Carp => qw(croak);

our $AUTOLOAD;

sub new {
	my $pkg = shift;
	
	my $self = bless {
		host => shift,
		plugin => shift,
		offset => shift,
		instance => shift || 0,
	}, $pkg;
	
	$self;
}

sub can { $AUTOLOAD = ref $_[0] . "::can"; goto &AUTOLOAD; }; # $$$ not yet tested. I'm pretty sure AUTOLOAD will [not][ be hit after UNIVERSAL::can is found. It doesn't rally matter.
sub AUTOLOAD { # it has to be less ugly than this
	my $self = shift;
	$AUTOLOAD =~ /.*::(.*?)$/;
	my $method = $1;
	return undef if $method eq 'DESTROY';

	my $stack = $self->{host}->self->stack($method) || croak "Can't locate object method \"$method\" via any plugin in ${ $self }{host}";
	
	my %counts;

	my $i;
	my $j = $self->{instance};
	
	for ($i = $#$stack; $i >= 0 or croak "The plugin which requested an offset is not in the stack for the method $method which it called"; $i--){
		${ $stack }[$i] == $self->{plugin} and (-1 == --$j) and last;
		$counts{ ${ $stack }[$i] }++;
	}
	
	my $x = $i;
	$i += $self->{offset};
	for (; $x >= $i; $x--){
		$counts{ ${ $stack }[$x] }++;
	}

	croak "The offset is out of the range of the method stack for $method\n" if ($i > $#$stack or $i < 0);
	
	Object::Meta::Plugin::Host::Context->new($self->{host}, ${ $stack }[$i], $counts{${ $stack }[$i]} -1  )->$method(@_);
}

1; # Keep your mother happy.

__END__

=pod

=head1 NAME

Object::Meta::Plugin::Host - hosts plugins that work like Object::Meta::Plugin. Can serve as a plugin if subclassed, or contains a plugin which can help it to plug.

=head1 SYNOPSIS

	# if you want working examples, read basic.t in the distribution
	# i don't know what kind of a synopsis would be useful for this.

	my $host = new Object::Meta::Plugin::Host;

	eval { $host->method() }; # should die

	$host->plug($plugin); # $plugin defines method
	$host->plug($another); # $another defines method and another

	# $another supplied the following, since it was plugged in later
	$host->method();
	$host->another($argument);

	$host->unplug($another);

	$host->method(); # now $plugin's method is used

=head1 DESCRIPTION

Object::Meta::Plugin::Host is an implementation of a plugin host, as described in L<Object::Meta::Plugin>.

The host is not just simply a merged hash. It is designed to allow various plugins to provide similar capabilities - methods with conflicting namespace. Conflicting namespaces can coexist, and take precedence over one another. A possible scenario is to have various plugins for an image processor, which all define the method "process". They are all installed, ordered as the effect should be taken out, and finally atop them all a plugin which wraps them into a pipeline is set.

When a plugin's method is entered it receives, instead of the host object, a context object, particular to itself. It allows it access to it's host, it's sibling plugins, and so forth explicitly, while implicitly wrapping around the host, and emulating it with reordered priority - the current plugin is first in the list.

Such a model enables a dumb plugin to work quite happily with others, even those which may take it's role. The only rule it needs to keep is that it accesses it's data structures using C<$self->self>, and not C<$self>, because $self is the context object.

A more complex plugin, aware that it may not be peerless, could explicitly ask for the default (host defined) methods it calls, instead of it's own. It can request to call a method on the plugin which succeeds it or precedes it in a certain method's stack. Additionally, by gaining access to the host object a plugin could implement a pipeline of calls quite easily, as described above. All it must do is call C<$self->host->stack($method)> and iterate that omitting itself.

The interface aims to be simple enough to be flexible, trying for the minimum it needs to define to be useful, and creating workarounds for the limitations this minimum imposes.

The implementation is by no means optimized. I doubt it's fast, but I don't really care. It's supposed to create a nice framework for a large application, which needs to be modular.

=head1 METHODS

=head2 Host

=over 4

=item methods

Returns a hash ref, to a hash of methods => array refs. The array refs are the stacks, and they can be accessed individually via the C<stack> method.

=item plug PLUGIN [ LIST ]

Takes a plugin, and calls it's C<init> with the supplied arguments. The return value is then fed to C<register>

=item plugins

Returns a hash ref, to a refhash. The keys are references to the plugins, and the values are export lists.

=item register EXPORTLIST

Takes an export list and integrates it's context into the method tree. The plugin the export list represents will be the topmost.

=item stack METHOD

Returns an array ref to a stack of plugins, for the method.

=item unplug PLUGIN [ PLUGIN ... ]

Takes a reference to a plugin, and sweeps the method tree clean of any of it's occurrences.

=item unregister EXPORTLIST [ EXPORTLIST ... ]

Takes an export list, and unmerges it from the currently active one. If it's empty, calls C<unplug>. If something remains, it cleans out the stacks manually.

=back

=head2 Context

=over 4

=item self

=item plugin

Grants access to the actual plugin object which was passed via the export list. Use for internal storage space.

=item super

=item host

Grants access to the host object. Use C<$self->super->method> if you want to override the precedence of the current plugin.

=item next

=item prev

=item offset INTEGER

Generates a new context, having to do with a plugin n steps away from this, to a certain direction. C<next> and C<prev> call C<offset> with -1 and 1 respectively. The offset object they return, has an autoloader which will search to see where the current plugin's instance is in the stack of a certain method, and then move a specified offset from that, and use the plugin in that slot.

=back

=head1 CAVEATS

=over 4

=item The C<can> method (e.g. C<UNIVERSAL::can>) is depended on. Without it everything will break. If you try to plug something nonstandard into a host, and export something C<UNIVERSAL::can> won't say is there, implement C<can> yourself.

=back

=head1 BUGS

Just you wait. See C<TODO> for what I have in stock!

=head1 TODO

=over 4

=item *

A better scheme for persistent data is needed, than C<$self->self> or C<$self->plugin>. It wreaks of lameness, and I fear it will be a psychological show stopper.

=item *

Offset contexting AUTOLOADER needs to diet.

=back

=head1 COPYRIGHT & LICENSE

	Copyright 2003 Yuval Kogman. All rights reserved.
	This program is free software; you can redistribute it
	and/or modify it under the same terms as Perl itself.

=head1 AUTHOR

Yuval Kogman <nothingmuch@woobling.org>

=head1 SEE ALSO

L<Class::Classless>, L<Class::Prototyped>, L<Class::SelfMethods>, L<Class::Object>, and possibly L<Pipeline> & L<Class::Dynamic>.

=cut
