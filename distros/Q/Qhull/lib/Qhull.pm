package Qhull;

# ABSTRACT: a really awesome library

use v5.26;
use strict;
use warnings;

our $VERSION = '0.01';

sub import {
    my ( undef, @args ) = @_;
    # for now, just have PP version;
    require Qhull::PP;
    Qhull::PP->import( { into => scalar caller() }, @args );
}

1;

#
# This file is part of Qhull
#
# This software is Copyright (c) 2024 by Smithsonian Astrophysical Observatory.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#

__END__

=pod

=for :stopwords Diab Jerius Smithsonian Astrophysical Observatory qhull

=head1 NAME

Qhull - a really awesome library

=head1 VERSION

version 0.01

=head1 SYNOPSIS

   use Qhull 'qhull';

   # generate a convex hull and return the ordered
   # indices of the points in the convex hull
   my \@indices = qhull( $x, $y );

=head1 DESCRIPTION

This is an B<alpha> quality interface to the L<qhull|https://qhull.org> library and executables.

At present this module punts to L<Qhull::PP>, which is a wrapper
around B<qhull> executable, not the library.

At present see L<Qhull::PP> for a discussion of the arguments to L<qhull>.

=head2 Future API

B<qhull> has an interesting manner of setting up options, used by both
the executable and the library entry point.  It may be impossible to
get this to look Perlish, especially as the B<qhull> manual page is
required to properly use its facilities.

The final interface, which will be the same for the library and the
executable wrapper is still in flux.

=head1 SUPPORT

=head2 Bugs

Please report any bugs or feature requests to bug-qhull@rt.cpan.org  or through the web interface at: L<https://rt.cpan.org/Public/Dist/Display.html?Name=Qhull>

=head2 Source

Source is available at

  https://gitlab.com/djerius/p5-qhull

and may be cloned from

  https://gitlab.com/djerius/p5-qhull.git

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2024 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
