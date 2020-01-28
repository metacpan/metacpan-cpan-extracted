package Pod::Elemental::Node;
# ABSTRACT: a thing with Pod::Elemental::Nodes as children
$Pod::Elemental::Node::VERSION = '0.103005';
use Moose::Role;

use namespace::autoclean;

use MooseX::Types;
use MooseX::Types::Moose qw(ArrayRef);

requires 'as_pod_string';
requires 'as_debug_string';

#pod =head1 OVERVIEW
#pod
#pod Classes that include Pod::Elemental::Node represent collections of child
#pod Pod::Elemental::Paragraphs.  This includes Pod documents, Pod5 regions, and
#pod nested Pod elements produced by the Gatherer transformer.
#pod
#pod =attr children
#pod
#pod This attribute is an arrayref of
#pod L<Pod::Elemental::Node|Pod::Elemental::Node>-performing objects, and represents
#pod elements contained by an object.
#pod
#pod =cut

has children => (
  is   => 'rw',
  isa  => ArrayRef[ role_type('Pod::Elemental::Paragraph') ],
  required   => 1,
  default    => sub { [] },
);

around as_debug_string => sub {
  my ($orig, $self) = @_;

  my $str = $self->$orig;

  my @children = map { $_->as_debug_string } @{ $self->children };
  s/^/  /sgm for @children;

  $str = join "\n", $str, @children;

  return $str;
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Elemental::Node - a thing with Pod::Elemental::Nodes as children

=head1 VERSION

version 0.103005

=head1 OVERVIEW

Classes that include Pod::Elemental::Node represent collections of child
Pod::Elemental::Paragraphs.  This includes Pod documents, Pod5 regions, and
nested Pod elements produced by the Gatherer transformer.

=head1 ATTRIBUTES

=head2 children

This attribute is an arrayref of
L<Pod::Elemental::Node|Pod::Elemental::Node>-performing objects, and represents
elements contained by an object.

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
