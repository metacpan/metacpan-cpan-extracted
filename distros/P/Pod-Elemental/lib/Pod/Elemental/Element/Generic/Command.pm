package Pod::Elemental::Element::Generic::Command;
# ABSTRACT: a Pod =command element
$Pod::Elemental::Element::Generic::Command::VERSION = '0.103004';
use Moose;

use namespace::autoclean;

#pod =head1 OVERVIEW
#pod
#pod Generic::Command elements are paragraph elements implementing the
#pod Pod::Elemental::Command role.  They provide the command method by implementing
#pod a read/write command attribute.
#pod
#pod =attr command
#pod
#pod This attribute contains the name of the command, like C<head1> or C<encoding>.
#pod
#pod =cut

has command => (
  is  => 'rw',
  isa => 'Str',
  required => 1,
);

with 'Pod::Elemental::Command';

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Elemental::Element::Generic::Command - a Pod =command element

=head1 VERSION

version 0.103004

=head1 OVERVIEW

Generic::Command elements are paragraph elements implementing the
Pod::Elemental::Command role.  They provide the command method by implementing
a read/write command attribute.

=head1 ATTRIBUTES

=head2 command

This attribute contains the name of the command, like C<head1> or C<encoding>.

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
