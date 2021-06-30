package PDL::Algorithm::Center::Failure;

# ABSTRACT: Exception classes for PDL::Algorithm::Center

use strict;
use warnings;

our $VERSION = '0.11';

use custom::failures::x::alias -suffix => '_failure', qw[
  parameter
  iteration::limit_reached
  iteration::empty
];

1;

__END__

=pod

=for :stopwords Diab Jerius Smithsonian Astrophysical Observatory

=head1 NAME

PDL::Algorithm::Center::Failure - Exception classes for PDL::Algorithm::Center

=head1 VERSION

version 0.11

=head1 SUPPORT

=head2 Bugs

Please report any bugs or feature requests to bug-pdl-algorithm-center@rt.cpan.org  or through the web interface at: https://rt.cpan.org/Public/Dist/Display.html?Name=PDL-Algorithm-Center

=head2 Source

Source is available at

  https://gitlab.com/djerius/pdl-algorithm-center

and may be cloned from

  https://gitlab.com/djerius/pdl-algorithm-center.git

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<PDL::Algorithm::Center|PDL::Algorithm::Center>

=back

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
