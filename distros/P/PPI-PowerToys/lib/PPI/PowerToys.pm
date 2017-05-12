package PPI::PowerToys;

use 5.006;
use strict;

use vars qw{$VERSION};
BEGIN {
        $VERSION = '0.14';
}

1;

__END__

=pod

=head1 NAME

PPI::PowerToys - A handy collection of small PPI-based utilities

=head1 DESCRIPTION

The PPI PowerToys are a small collection of utilities for working
with Perl files, modules and distributions.

To kick off the collection, he's added a very simple and raw version
of one of his own little tools.

=head2 ppi_version

  > ppi_version show
  > ppi_version change 0.01 0.02

B<ppi_version> is a utility for working with version numbers in
groups of modules.

The C<ppi_version show> command will scan through your distribution
(starting in the current directory and working down) and locate all
the versions for the various Perl files in the distribution.

It scans through all files inside the current directory with one-only
instance of the line.

  $VERSION = '0.01';

The C<ppi_version change> command scans through your distribution
(starting in the current directory and working down) and locate all
cases where the C<$VERSION> is the first param, replacing it (safely)
with the second params.

=head1 TO DO

- Add extra commands to ppi_version

- Include more useful utilities

- Any improvements to the current utilities are also very welcome.

=head1 SUPPORT

Bugs and patches should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=PPI-PowerToys>

For other issues, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2006 - 2009 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
