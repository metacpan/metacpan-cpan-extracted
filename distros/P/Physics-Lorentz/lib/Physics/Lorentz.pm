package Physics::Lorentz;

use 5.006;
use strict;
use warnings;
use Physics::Lorentz::Vector;
use Physics::Lorentz::Transformation;

our $VERSION = '0.01';


1;
__END__

=head1 NAME

Physics::Lorentz - Package for 4-vectors and transformations

=head1 SYNOPSIS

  use Physics::Lorentz;
  my $rotation = Physics::Lorentz::Transformation->rotation_euler(
    $alpha, $beta, $gamma
  );
  my $vector = Physics::Lorentz::Vector->new([$t, $x, $y, $z]);
  my $rotated = $rotation->apply($vector);
  # or: $rotated = $rotation * $vector;
  
  ...

=head1 DESCRIPTION

This package mainly just loads L<Physics::Lorentz::Transformation> and
L<Physics::Lorentz::Vector>. The whole of the C<Physics::Lorentz> distribution
is intended to help with dealing with 4-vectors and (Poincare) transformations
in the associated vector space.

Vectors and transformations are implemented as PDL objects internally.

=head2 EXPORT

None.

=head1 SEE ALSO

L<PDL>, L<Physics::Lorentz::Vector>, L<Physics::Lorentz::Transformation>

=head1 AUTHOR

Steffen Müller, E<lt>smueller@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Steffen Müller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
