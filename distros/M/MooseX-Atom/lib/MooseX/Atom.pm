package MooseX::Atom;

# See end of file for docs

use 5.008005;
use strict;
use warnings;
use Moose 1.08 ();

our $VERSION = '0.02';

sub import {
	my $class   = shift;
	my @model   = @{ pop() };
	my $package = caller();

	# Generate the metaobject, and immediately remove all the exported symbols.
	# This is a hack until I can work out how to avoid exporting them at all.
	# NOTE: Yuck!
	eval "package $package; use Moose; no Moose;";
	die $@ if $@;

	# Push the commands to generate the class directly through the meta object.
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
		&{"Moose::$command"}( $meta, @$params );
	}
	foreach my $params ( @with ) {
		Moose::with( $meta, @$params );
	}

	# Immediately make the class immutable
	$meta->make_immutable;

	return 1;
}

1;

__END__

=pod

=head1 NAME

MooseX::Atom - Non-immutable classes are silly. Lets fix that.

=head1 SYNOPSIS

  # Catalyst the official way
  package Foo;
  
  use Moose;
  use namespace::autoclean;
  
  BEGIN {
      extends 'Catalyst::Controller::REST';
      
      with 'My::Something';
  }
  
  __PACKAGE__->meta->make_immutable;
  
  
  
  # Catalyst the (equivalent) atomic way
  package Bar;
  
  use MooseX::Atom [
  	extends => 'Catalyst::Controller::REST',
  	with    => 'My::Something',
  ];

=head1 DESCRIPTION

B<WARNING: THIS MODULE IS PRIMARILY A POLITICAL STATEMENT AT THIS TIME AND MAY
CHANGE WITHOUT NOTICE IN RESPONSE TO FEEDBACK>

L<Moose> is an interesting object system, but it's interface can leave a lot
to be desired.

Classes are built incrementally at post-BEGIN time despite the appearance to
being declared at compile time.

Classes are also polluted by exported symbols by default.

Additionally, the syntax of the workarounds to reverse some of this weirdness
is ugly. C<__PACKAGE__->meta->make_immutable> is possibly one of the worst
official API interactions of all time.

B<MooseX::Atom> attempts to resolve as much of this as possible, in as little
code as possible and with no additional dependencies or dramatic
parser-alterations such as with L<MooseX::Declare>.

Declarations are passed directly in the C<use> line, nothing is left in the
calling class, and the class will be automatically and immediately immutable.

The resulting alternative syntax for L<Moose> may not be ideal, but it
demonstrates the kind of alternative syntactic sugar that would at least be
far nicer than the one we get out of the box.

Equivalent syntactic sugar for roles is provided by L<MooseX::Role::Atom>.

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
