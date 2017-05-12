use 5.008;
use strict;
use warnings;

# ABSTRACT: Module collection to parse Matroska files.
package Parse::Matroska;
{
  $Parse::Matroska::VERSION = '0.003';
}


use Parse::Matroska::Reader;

1;

__END__

=pod

=head1 NAME

Parse::Matroska - Module collection to parse Matroska files.

=head1 VERSION

version 0.003

=head1 DESCRIPTION

C<use>s L<Parse::Matroska::Reader>. See the documentation
of the modules mentioned in L</"SEE ALSO"> for more information
in how to use this module.

It's intended for this module to contain high-level interfaces
to the other modules in the distribution.

=head1 SOURCE CODE

L<https://github.com/Kovensky/Parse-Matroska>

=head1 SEE ALSO

L<Parse::Matroska::Reader>, L<Parse::Matroska::Element>,
L<Parse::Matroska::Definitions>.

=head1 AUTHOR

Kovensky <diogomfranco@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Diogo Franco.

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut
