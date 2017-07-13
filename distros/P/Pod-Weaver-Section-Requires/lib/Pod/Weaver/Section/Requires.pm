package Pod::Weaver::Section::Requires;
# ABSTRACT: Add Pod::Weaver section with all used modules from package excluding listed ones

our $VERSION = 0.03;


use strict;
use warnings;

use Class::Inspector;
use Module::Load;
use Moose;
use Module::Extract::Use;

with 'Pod::Weaver::Role::Section';

use aliased 'Pod::Elemental::Element::Nested';
use aliased 'Pod::Elemental::Element::Pod5::Command';

# All attributes are private only
has ignore => (
	is 	=> 'ro',
	isa	=> 'Str',
);

has extra_args => (
	is	=> 'rw',
	isa	=> 'HashRef',
);

sub BUILD {
	my $self = shift;
	my ($args) = @_;
	my $copy = {%$args};
	delete $copy->{$_}
		for map { $_->init_arg } $self->meta->get_all_attributes;
	$self->extra_args($copy);
}

# This is implicit method of plugin for extending Pod::Weaver, cannot be called directly
sub weave_section {
	my ( $self, $doc, $input ) = @_;

	my $filename = $input->{filename};

	return if $filename !~ m{\.pm$};

	my $ignorelist = $self->ignore;
	my %exclude = map { $_ => 1 } split /\s+/, $ignorelist;
	
	my @modules = sort grep { ! exists $exclude{ $_ } } $self->_get_requires( $filename );

	return unless @modules;

	my @pod = (
		Command->new( {
			command => 'over',
			content => 4
		} ),
		(
			map {
				Command->new( {
					command => 'item',
					content => "* L<$_|$_>",
				} ),
			} @modules
		),
		Command->new( {
			command => 'back',
			content => ''
		} )
	);

	push @{ $doc->children },
		Nested->new( {
			type     => 'command',
			command  => 'head1',
			content  => 'REQUIRES',
			children => \@pod
		} );
}

# Private method for extracting used modules
sub _get_requires {
	my ( $self, $module ) = @_;
	
	my $extor = new Module::Extract::Use;
	
	my @modules = $extor->get_modules( $module );
	print "Possibly harmless: $@" if $extor->error;

	return @modules;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Weaver::Section::Requires - Add Pod::Weaver section with all used modules from package excluding listed ones

=head1 VERSION

version 0.03

=head1 SYNOPSIS

In your C<weaver.ini>:

	[Requires]
	ignore = base lib constant namespace::sweep

=head1 DESCRIPTION

This L<Pod::Weaver> section plugin creates a "REQUIRES" section in your POD
which contains a list of the modules used/required by your class. It accomplishes this 
by using L<Module::Extract::Use> on all classes.

All classes (*.pm files) in your distribution's lib directory will be loaded.
List of all used modules are gathered and listed ignored classes (pragmas etc.) are
excluded from this list. POD is changed only for files which actually requires other
modules than excluded.

=head1 SEE ALSO

L<Pod::Weaver::Section::Extends> 

=head1 AUTHOR

Milan Sorm <sorm@is4u.cz>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014-2017 by Milan Sorm.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
