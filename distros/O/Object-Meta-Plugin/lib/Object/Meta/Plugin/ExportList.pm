#!/usr/bin/perl
# $Id: ExportList.pm,v 1.1 2003/11/29 14:35:24 nothingmuch Exp $

package Object::Meta::Plugin::ExportList; # an object representing the skin of a plugin - what can be plugged and unseamed at the top level.

use strict;
use warnings;

# this is a simple string based Object::Meta::Plugin::Export list. That is, all the methods are strings, and not code refs,
# which gives a somewhat more controlled environment.

# you could laxen these limits by writing your own ExportList, which will use code refs, and thus allow a plugin to nibble methods from other classes without base classing.
# you'd also have to subclass Object::Meta::Plugin::Host to handle coderefs. Perhaps a dualvalue system could be useful.

our $VERSION = 0.01;

sub new {
	my $pkg = shift;
	my $plugin = shift;
	
	my @methods = @_;
	
	if (@_){	
		my %list = map { $_, undef } $plugin->exports(); # used to cross out what's not exported	
		bless [ $plugin, [ grep { exists $list{$_} } @methods ] ], $pkg; # filter the method list to be only what works
	} else {
		bless [ $plugin, [ $plugin->exports() ] ], $pkg; # everythin unless otherwise stated
	}
}

sub plugin {
	my $self = shift;
	$self->[0];
}

sub exists { # $$$
	my $self = shift;

	if (wantarray){ # return a grepped list
		my @methods = @_;
	} else { # return a true or false
		my $method = shift;
	}
}

sub list { # list all under plugin
	my $self = shift;
	
	return @{ $self->[1] };
}

sub merge { # or another exoprt list into this one
	my $self = shift;
	my $x = shift;
	
	my %uniq;
	@{ $self->[1] } = grep { not $uniq{$_}++ } @{ $self->[1] }, $x->list();

	$self;
}

sub unmerge { # and (not|complement) another export list into this one
	my $self = shift;
	my $x = shift;
	
	my %seen = map { $_, undef } $x->list();
	@{ $self->[1] } = grep { not exists $seen{$_} } @{ $self->[1] };
}

1; # Keep your mother happy.

__END__

=pod

=head1 NAME

Object::Meta::Plugin::ExportList - an implementation of a very simple, string only export list.

=head1 SYNOPSIS

	# the proper way

	my $plugin = GoodPlugin->new();
	$host->plug($plugin);

	package GoodPlugin;

	# ...

	sub exports {
		qw/some methods/;
	}

	sub init {
		my $self = shift;
		return Object::Meta::Plugin::ExportList->new($self};
	}

	# or if you prefer.... *drum roll*
	# the naughty way

	my $plugin = BadPlugin->new();	# doesn't need to be a plugin per se, since
									# it's not verified by plug(). All it needs
									# is to have a working can(). the export
									# list is responsible for the rest.
									# in short, this way init() needn't be defined.

	my $export = Object::Meta::Plugin::ExportList->new($plugin, qw/foo bar/);

	$host->register($export);

=head1 DESCRIPTION

An export list is an object a plugin hands over to a host, stating what it is going to give it. This is a very basic implementation, providing only the bare minimum methods needed to register a plugin. Unregistering one requires even less.

=head1 METHODS

=over 4

=item new PLUGIN [ METHODS ... ]

Creates a new export list object. When passed only a plugin, and no method names as additional arguments, 

=item plugin

Returns the reference to the plugin object it represents.

=item exists METHOD

Returns truth if the method stated is exported.

=item list METHOD

Returns a list of exported method names.

=item merge EXPORTLIST

Performs an OR with the methods of the argued export list.

=item unmerge EXPORTLIST

Performs an AND of the COMPLEMENT of the argued export list.

=back

=head1 CAVEATS

=over 4

=item *

Relies on the plugin implementation to provide a non-mandatory extension - the C<exports> method. This method is available in all the L<Object::Meta::Plugin::Useful> variants, and since L<Object::Meta::Plugin> is not usable on it's own this is probably ok.

=back

=head1 BUGS

Not that I know of, for the while being at least.

=head1 COPYRIGHT & LICENSE

	Copyright 2003 Yuval Kogman. All rights reserved.
	This program is free software; you can redistribute it
	and/or modify it under the same terms as Perl itself.

=head1 AUTHOR

Yuval Kogman <nothingmuch@woobling.org>

=head1 SEE ALSO

L<Object::Meta::Plugin>, L<Object::Meta::Plugin::Useful>, L<Object::Meta::Plugin::Host>

=cut
