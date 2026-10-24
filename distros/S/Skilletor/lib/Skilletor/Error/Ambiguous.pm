package Skilletor::Error::Ambiguous;
# ABSTRACT: A lookup that would have to hide one of two items: a rule both scopes declare

use Moo;
use namespace::clean;

extends 'Skilletor::Error';

our $VERSION = '0.001';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Skilletor::Error::Ambiguous - A lookup that would have to hide one of two items: a rule both scopes declare

=head1 VERSION

version 0.001

=head1 DESCRIPTION

Thrown by L<Skilletor/resolve_rule> and L<Skilletor/resolve_item> when the user
and the project scope both declare a rule of the name and no C<scope> narrows
the lookup: Claude Code loads both, neither overrides the other, so a single
answer would hide one. L<Skilletor/resolve_rules> and L<Skilletor/resolve_items>
give both. See L<Skilletor::Error> for the interface.

=head1 SUPPORT

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
