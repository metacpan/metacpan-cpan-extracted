package MooseX::Role::Atom;

use 5.008005;
use strict;
use warnings;
use Moose::Role 1.08 ();

our $VERSION = '0.02';

sub import {
	my $class = shift;
	my @model = @{ pop() };
	my $package = caller();

	# Generate the metaobject, and immediately remove all the exported symbols.
	# This is a hack until I can work out how to avoid exporting them at all.
	# NOTE: Yuck!
	eval "package $package; use Moose::Role; no Moose::Role;";
	die $@ if $@;

	# Push the commands to generate the role directly through the meta object.
	my $meta = $package->meta;
	my @with = ();
	while ( @model ) {
		my $command = shift @model;
		my $params  = shift @model;
		$params = [ $params ] unless ref $params eq 'ARRAY';
		if ( $command eq 'with' ) {
			push @with, $params;
			next;
		}
		no strict 'refs';
		&{"Moose::Role::$command"}( $meta, @$params );
	}
	foreach my $params ( @with ) {
		Moose::with( $meta, @$params );
	}

	# Immediately make the role immutable
	$meta->make_immutable;

	return 1;
}

1;

=pod

=head1 NAME

MooseX::Role::Atom - Non-immutable roles are silly. Lets fix that.

=head1 SYNOPSIS

  # A basic role the official way
  package Foo;
  
  use Moose::Role;
  use namespace::autoclean;
  
  requires 'icecream';
  
  has 'something' => (
      is => 'ro',
      isa => 'Str',
  );
  
  __PACKAGE__->meta->make_immutable;
  
  
  
  # A basic role the atomic way
  package Bar;
  
  use MooseX::Role::Atom [
  	requires => 'icecream',
  	has      => [
	    something => (
		is  => 'ro',
		isa => 'Str',
	    ),
  	],
  ];

=head1 DESCRIPTION

B<WARNING: THIS MODULE IS PRIMARILY A POLITICAL STATEMENT AT THIS TIME AND MAY
CHANGE WITHOUT NOTICE IN RESPONSE TO FEEDBACK>

See the description for L<MooseX::Atom>.

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MooseX-Atom>

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<Moose>

=head1 COPYRIGHT

Copyright 2010 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
