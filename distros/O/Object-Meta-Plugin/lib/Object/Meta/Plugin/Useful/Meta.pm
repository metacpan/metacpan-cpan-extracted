#!/usr/bin/perl
# $Id: Meta.pm,v 1.2 2003/11/29 14:48:37 nothingmuch Exp $

package Object::Meta::Plugin::Useful::Meta; # a plugin base class which subclasses Object::Meta::Plugin::Host - a meta plugin

use strict;
use warnings;

use base qw/Object::Meta::Plugin::Host Object::Meta::Plugin::Useful/;

sub new {
	my $pkg = shift;
	
	my $self = $pkg->SUPER::new(); # host;
	
	$self->{exported} = undef;
	$self->{exports} = [];
	
	$self;
}

sub exports {
	keys %{ $_[0]->methods };
}


1; # Keep your mother happy.

__END__

=pod

=head1 NAME

Object::Meta::Plugin::Useful::Meta - a subclass of Object::Meta::Plugin::Useful and Object::Meta::Plugin::Host, base class for hosts which are plugins.

=head1 SYNOPSIS

	my $host = Object::Meta::Plugin::Host->new();
	my $plugin = Object::Meta::Plugin::Useful::Meta::new();

	$plugin->plug(MyPlug->new());	# of course, there's no point if
									# this isn't more interesting

	$host->plugin($plugin);

=head1 DESCRIPTION

This is an L<Object::Meta::Plugin::Host> and more. It provides the necessary methods to treat a host as a plugin. It is not the most elegant solution, see C<CAVEATS>.

=head1 CAVEATS

=over 4

=item *

Somewhat defies the purpose of plugging things in. It is possible (and even tested for) to plug a plugin into a host, and have that plugin provide plugin capabilities. Such an implementation would look like this:


	package SuperPlugin;

	use strict;
	use warnings;

	use base 'Object::Meta::Plugin::Useful::Generic';

	sub new {
		my $pkg = shift;
		my $self = $pkg->SUPER::new(@_);
		$self->export(/init exports/);
	};

	sub init {
		my $self = shift;

		if ($self->can("super")){ # if we're part of a context, we're called from a host
			unshift @_, $self->super; &init; # switch self, and rerun
		} else {
			$self->SUPER::init(@_); # goto the superclass (Object::Meta::Plugin::Useful::Generic) init.
		}
	}

	sub exports { # if $self->can(super) return self->super->methods, whatever. Otherwise, export self as a plugin.
		my $self = shift;

		if ($self->can("super")){ # plugged in
			keys %{ $self->super->methods }; # return the method names for the host
		} else {
			$self->SUPER::exports(@_); # Object::Meta::Plugin::Useful::Generic::exports
		}
	}

=back

=head1 COPYRIGHT & LICENSE

	Copyright 2003 Yuval Kogman. All rights reserved.
	This program is free software; you can redistribute it
	and/or modify it under the same terms as Perl itself.

=head1 AUTHOR

Yuval Kogman <nothingmuch@woobling.org>

=head1 SEE ALSO

L<Object::Meta::Plugin>, L<Object::Meta::Plugin::Useful>, L<Object::Meta::Plugin::Useful::Generic>, L<Object::Meta::Plugin::Useful::Greedy>.

=cut
