package Skilletor::Error::Render;
# ABSTRACT: A template cannot be rendered (the reference's RenderError)

use Moo;
use namespace::clean;

extends 'Skilletor::Error';

our $VERSION = '0.008000';

# The reference's class name: Nunjucks words an error thrown inside a template's include as
# `NAME: MESSAGE`, and Text::Nunjucks asks the error for both.
sub name { 'RenderError' }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Skilletor::Error::Render - A template cannot be rendered (the reference's RenderError)

=head1 VERSION

version 0.008000

=head1 DESCRIPTION

Thrown by L<Skilletor::Render/build> where the reference throws its
C<RenderError>: a template that fails to render (C<< <file>: <message> >>, the
message Nunjucks gives) and an include or import that leaves the source root
(C<< template escapes source root: <name> >>). See L<Skilletor::Error> for the
interface.

=head2 name

C<RenderError>, the reference's class name.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests at
L<https://github.com/Getty/skilletor/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
