package ORLite::PDL;

# See POD at the end of the file for documentation

use 5.006;
use strict;
use warnings;
use Carp              ();
use Params::Util 1.00 ();

# Load both the main and statistics PDL packages
use PDL        2.004005;
use PDL::Stats 0.003002;

our $VERSION = '0.02';

sub import {
	my $class  = shift;
	my $params = Params::Util::_HASHLIKE($_[0]) ? $_[0]
		: { package => scalar(caller()) };

	# Verify the caller is an ORLite package
	unless ( Params::Util::_CLASS($params->{package}) ) {
		Carp::croak("Missing or invalid ORLite package name");
	}
	unless ( $params->{package}->can('orlite') ) {
		Carp::croak("$params->{package} does not appear to be an ORLite root class");
	}

	# Add the additional DBI-like root method
	eval <<"END_PERL"; die $@ if $@;
package $params->{package};

sub selectcol_pdl {
	my \$class = shift;
	my \$array = \$class->selectcol_arrayref(\@_);
	ORLite::PDL::pdl( \$array );
}

1;
END_PERL

	return 1;
}

1;

__END__

=pod

=head1 NAME

ORLite::PDL - PDL integration for ORLite

=head1 SYNOPSIS

  package Foo;
  
  # Load database and add statistics package
  use ORLite 'statistics.db';
  use ORLite::PDL;
  
  my $pdl = Foo->selectcol_pdl('select column from table');

=head1 DESCRIPTION

B<Note: This is a very simple initial implementation, more functionality
to come in the future.>

Compressed SQLite database files are a handy format for the distribution of
bulk data, including statistical data.

The L<ORLite> Object-Relational Model provides a convenient way to create
client APIs on top of these databases. However, its numberical analysis
ability is limited to that provided by native SQLite.

The Perl Database Language (L<PDL>) is a high-performance library for
numerical analysis in Perl.

B<ORLite::PDL> provides convenient integration between L<ORLite> and L<PDL>.

=head1 METHODS

=head2 selectcol_pdl

  my $pdl = Foo->selectcol_pdl(
      'select col from table where country = ?', {},
      'Australia',
  );

The C<selectcol_pdl> method is added to the root namespace of your ORLite
module tree.

It takes the same parameters and returns the same results as
C<selectcol_arrayref>, but automatically converts the result to a
L<PDL> "piddle" object.

Returns a L<PDL> object, or throws an exception on error.

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=ORLite-PDL>

For other issues, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<ORLite>, L<ORLite::Mirror>

=head1 COPYRIGHT

Copyright 2010 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
