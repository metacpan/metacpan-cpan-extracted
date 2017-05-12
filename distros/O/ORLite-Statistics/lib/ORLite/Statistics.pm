package ORLite::Statistics;

=pod

=head1 NAME

ORLite::Statistics - Statistics enhancement package for ORLite

=head1 DESCRIPTION

This is an enhancement module for ORLite table classes, designed to provide
easy integration with the L<Statistics::Base> module.

=head1 METHODS

=cut

use 5.008;
use strict;
use warnings;
use Exporter                 ();
use ORLite              1.25 ();
use Statistics::Basic 1.6600;

our $VERSION   = '0.03';
our @ISA       = 'Exporter';
our @EXPORT    = 'vector';
our @EXPORT_OK = 'vector';

=pod

=head2 vector

  my $ages = MyModule::TableName->vector('age');

Generates a L<Statistics::Basic::Vector> for a particular method.

=cut

sub vector {
	my $class  = shift;
	my $method = shift;

	# Generate the vector
	my @vector = ();
	$class->iterate( @_, sub {
		push @vector, $_->$method();
	} );

	Statistics::Basic::vector(\@vector);
}

1;

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=ORLite-Statistics>

For other issues, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<ORLite>, L<ORLite::Mirror>

=head1 COPYRIGHT

Copyright 2009 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
