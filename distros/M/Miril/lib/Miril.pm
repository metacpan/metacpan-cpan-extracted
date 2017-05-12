package Miril;

use warnings;
use strict;
use autodie;

use Try::Tiny;
use Exception::Class;
use Carp;
use Module::Load;
use Ref::List qw(list);
use Miril::Warning;
use Miril::Exception;
use Miril::Config;
use Miril::Util;

our $VERSION = '0.008';

### ACCESSORS ###

use Object::Tiny qw(
	store
	tmpl
	cfg
	filter
	util
);


### CONSTRUCTOR ###

sub new {
	my $class = shift;
	my $self = bless {}, $class;
	my $miril_dir = shift;
	my $site = shift;

	
	# load configuration
	try {
		my $cfg = Miril::Config->new($miril_dir, $site);
		$self->{cfg} = $cfg;
	} catch {
		Miril::Exception->throw( 
			errorvar => $_,
			message  => 'Could not open configuration file',
		);
	};
	return unless $self->cfg;

	my $cfg = $self->cfg;

	# load store
	try {
		my $store_name = "Miril::Store::" . $cfg->store;
		load $store_name;
		my $store = $store_name->new($self);
		$self->{store} = $store;
	} catch {
		Miril::Exception->throw(
			errorvar => $_,
			message  => 'Could not load store',
		);
	};
	return unless $self->store;

	# load temlate
	try {
		my $tmpl_name = "Miril::Template::" . $cfg->template;
		load $tmpl_name;
		$self->{tmpl} = $tmpl_name->new($self);
	} catch {
		Miril::Exception->throw(
			errorvar => $_,
			message  => 'Could not load template',
		);
	};

	# load filter
	try {
		my $filter_name = "Miril::Filter::" . $cfg->filter;
		load $filter_name;
		$self->{filter} = $filter_name->new($cfg);
	} catch {
		Miril::Exception->throw(
			errorvar => $_,
			message  => 'Could not load filter',
		);
	};

	# load utils
	$self->{util} = Miril::Util->new($cfg);
	
	return $self;
}

### PUBLIC METHODS ###

sub warnings 
{
	my $self = shift;
	return list $self->{warnings};
}

sub push_warning 
{
	my $self = shift;
	my %params = @_;

	my $warning = Miril::Warning->new(
		message  => $params{'message'},
		errorvar => $params{'errorvar'},
	);

	my @warnings_stack = $self->warnings;
	push @warnings_stack, $warning;
	$self->{warnings} = \@warnings_stack;
}

1;

=head1 NAME

Miril - A Static Content Management System

=head1 VERSION

Version 0.008

=head1 WARNING

This is alfa-quality software, use with great care!

=head1 DESCRPTION

Miril is a lightweight static content management system written in perl and based on CGI::Application. It is designed to be easy to deploy and easy to use. Documentation is currently lacking, read L<Miril::Manual> to get started. 

=head1 AUTHOR

Peter Shangov, C<< <pshangov at yahoo.com> >>

=head1 COPYRIGHT & LICENSE

Copyright 2009 Peter Shangov.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

