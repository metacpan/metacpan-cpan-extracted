package TUI::Editors;
# ABSTRACT: Editor-related modules for the framework

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000002';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

1

__END__

=head1 NAME

TUI::Editors - Editor-related modules for the framework

=head1 SYNOPSIS

  use TUI::Editors;

=head1 DESCRIPTION

C<TUI::Editors> provides the editor-related view classes used throughout the
L<TUI::Vision> framework.

The module currently serves primarily as a namespace for editor components and
related functionality. Concrete editor implementations are provided by modules
within the C<TUI::Editors::*> hierarchy.

Editor views are responsible for displaying and manipulating text within the
framework's event-driven user interface and are intended to provide behavior
compatible with the original I<Turbo Vision> editor system where practical.

=head1 COMPATIBILITY

The design of the editor subsystem is inspired by Borland I<Turbo Vision>.
Behavior, naming conventions, and APIs may therefore resemble their original
I<Turbo Vision> counterparts where appropriate for the Perl implementation.

=head1 SEE ALSO

L<TUI::Vision>

=head1 AUTHORS

=over

=item * Borland International (original Turbo Vision design)

=item * J. Schneider <brickpool@cpan.org> (Perl implementation and maintenance)

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 1990-1994, 1997 by Borland International

Copyright (c) 2026 the L</AUTHORS> as listed above.

This software is licensed under the MIT license (see the LICENSE file, which is
part of the distribution).
