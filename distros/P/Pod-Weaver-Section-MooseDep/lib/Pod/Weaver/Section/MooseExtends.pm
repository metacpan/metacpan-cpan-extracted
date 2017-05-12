package Pod::Weaver::Section::MooseExtends 0.01;
# ABSTRACT: Add Pod::Weaver section with inherited classes (what I am extending) based on Moose OOP framework
$Pod::Weaver::Section::MooseExtends::VERSION = '0.01';


use strict;
use warnings;

use Class::Inspector;
use Module::Load;
use Moose;
use Module::Metadata;

with 'Pod::Weaver::Role::Section';

use aliased 'Pod::Elemental::Element::Nested';
use aliased 'Pod::Elemental::Element::Pod5::Command';

# This is implicit method of plugin for extending Pod::Weaver, cannot be called directly
sub weave_section {
	my ( $self, $doc, $input ) = @_;

	my $filename = $input->{filename};

	return if $filename !~ m{\.pm$};

	my $info = Module::Metadata->new_from_file( $filename );
	my $module = $info->name();
	
	return unless $module;

	unless ( Class::Inspector->loaded( $module ) ) {
		eval { local @INC = ( 'lib', @INC ); Module::Load::load $module };
		print "$@" if $@;    #warn
	}

	return unless $module->can('meta');

	my @roles = sort
		grep { $_ ne $module } $self->_get_extends($module);

	return unless @roles;

	my @pod = (
	        Command->new( {
			command => 'over',
			content => 4
		} ),
		(
			map {
				Command->new( {
					command => 'item',
					content => "* L<$_>",
				} ),
			} @roles
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
			content  => 'EXTENDS',
			children => \@pod
		} );
}

# Private method for extracting extending classes through meta/superclasses
sub _get_extends {
	my ( $self, $module ) = @_;

	return () unless $module->meta->can( 'superclasses' );

	my @extends = eval { $module->meta->superclasses };
	print "Possibly harmless: $@" if $@;

	return @extends;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Weaver::Section::MooseExtends - Add Pod::Weaver section with inherited classes (what I am extending) based on Moose OOP framework

=head1 VERSION

version 0.01

=head1 SYNOPSIS

In your C<weaver.ini>:

	[MooseExtends]

=head1 DESCRIPTION

This L<Pod::Weaver> section plugin creates a "EXTENDS" section in your POD
which contains a list of your class's parent classes. It accomplishes this
by loading all classes and inspecting it through Moose framework.

It can work with all Moose classes based on filename (also outside of distribution
tree). All classes (*.pm files) in your distribution's lib directory will be loaded.
POD is changed only for files which actually extends some class or Moose base classes
itself.

=head1 SEE ALSO

L<Pod::Weaver::Section::Extends> 
L<Pod::Weaver::Section::MooseConsumes> 
L<Moose>

=head1 AUTHOR

Milan Sorm <sorm@is4u.cz>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Milan Sorm.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
