package aze;

use 5.006;
use strict;
use warnings;
use Term::Maze;
our $VERSION = '0.04';

sub import {
  my ( $class, $cols, $rows ) = @_;
  $cols //= 40;
  $rows //= 40;
  Term::Maze->run( $cols, $rows );
}

1;

__END__

=head1 NAME

aze - Mazes in the terminal

=head1 VERSION

Version 0.04

=cut

=head1 SYNOPSIS

	perl -Maze

...

	perl -Maze=40,20

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-term-maze at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Term-Maze>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	 perldoc Term::Maze

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Term-Maze>

=item * Search CPAN

L<https://metacpan.org/release/Term-Maze>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2025 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

1; # End of Term::Maze
