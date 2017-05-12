#!/usr/bin/perl
# $Id: Plugin.pm,v 1.9 2003/11/29 14:48:37 nothingmuch Exp $

#$$$
# to do:
# circular reference crap. make sure all references which should be weak are weakened.

package Object::Meta::Plugin; # base class for a plugin

use strict;
use warnings;

use autouse Carp => qw(croak);

our $VERSION = 0.01;

sub init { # defined.
	my $self = shift;
	croak "init must be defined by sublclass";
}

1; # Keep your mother happy.

__END__

=pod

=head1 NAME

Object::Meta::Plugin - a classless compound object implementation or a base class for an element of thereof.

=head1 SYNOPSIS

	# Read on please. Examples are in Object::Meta::Plugin::Host.

=head1 DESCRIPTION

=head2 Distribution

The Object::Meta::Plugin distribution is an implementation of a classless object system, which bases itself on plugins. An object implemented with it is a meta object, because it is modifiable during runtime, attaching and detaching pieces of itself, which we will call plugins. The overlying object will inherit, in a way, from the underlying objects.

=head2 Class

The Object::Meta::Plugin class is a very slim base class which defines the mandatory methods needed for a plugin to be considered a plugin. It is extended by the L<Object::Meta::Plugin::Useful> variants, which are a group of useful plugin base classes, that you can use to easily construct plugins that work, and not just sit there.

Due to the somewhat lacking nature of the class Object::Meta::Plugin, I will devote the rest of this document to general information regarding the distribution, returning to the class as needed.

=head1 CONCEPT

The basic concept is that you have an object. The object is quite empty and dull, and defines some methods using it's own real class - amongst them are C<plug>, and C<unplug>. These methods are used to connect a plugin to the host, and disconnect it from the host:

	$host->plug($plugin);

	# ...

	$host->unplug($plugin);

When an object is plugged into the host it's C<init> method is called, with the arguments that were passed to C<plug> just after the plugin object itself. What init needs to do is tell the host what to import into it. It does this by means of an export list object. The definition of such an object can be found in L<Object::Meta::Plugin::ExportList>.

In fact, C<plug> does nothing of it's own right. It simply passes the return value from C<init> to C<register>. You could use some sort of handle object to plug into the host - the actual reference which will be accounted for, is that which is returned by the export list object's method C<plugin>.

The host object will use the C<register> method to register the plugin's methods in it's indices. Plugins will thus stack atop one another, similar to the way classes subclass other classes.

Subsequently, a method not defined by the host's class (or ancestors, but not in my implementation) will be called. The host's AUTOLOAD subroutine will then take action. If the method which was not found is exported by any of the plugged plugins a C<croak> will be uttered. Otherwise, the host will create what is known as a context object. The context provides a more comfortable environment for the plugin, while maintaining a relationship to the host, external of the plugin itself. It also enables some additional whiz bang, like having the methods C<next> and C<prev> work even if multiple copies of the same plugin are attached at various points in the host.

It should be noted that the host implementation was designed so that it could be plugged into another host, provided a plugin of some sort will provide the basic definition of a plugin.

=head1 METHODS

=over 4

=item init

This is the one sole method needed to consider an object to be a plugin. Ofcourse, it must also return a proper value. In this implementation it simply croaks. You need to use an L<Object::Meta::Plugin::Useful> variant if you don't want to write it all yourself.

=back

=head1 CAVEATS

=over 4

=item *

The way to access your plugin's data structures, and thus gain data store, is $self->self. That's a silly way. I need to find some easier method of accessing the guts of the plugin. Perhaps with tied hashes, but that sounds very dirty.

=item *

There's a huge dependancy on every plugin implementing C<can> if C<UNIVERSAL::can> won't work for it. Just do it.

=back

=head1 COPYRIGHT & LICENSE

	Copyright 2003 Yuval Kogman. All rights reserved.
	This program is free software; you can redistribute it
	and/or modify it under the same terms as Perl itself.

=head1 AUTHOR

Yuval Kogman <nothingmuch@woobling.org>

=head1 SEE ALSO

L<Object::Meta::Plugin::Host>, L<Object::Meta::Plugin::Useful>, L<Object::Meta::Plugin::ExportList>, L<Class::Classless>, L<Class::Prototyped>, L<Class::SelfMethods>, L<Class::Object>, and possibly L<Pipeline> & L<Class::Dynamic>.

=cut
