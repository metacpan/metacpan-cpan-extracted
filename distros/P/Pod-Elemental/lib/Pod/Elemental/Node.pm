package Pod::Elemental::Node 0.103006;
# ABSTRACT: a thing with Pod::Elemental::Nodes as children

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

version 0.103006

=head1 OVERVIEW

Classes that include Pod::Elemental::Node represent collections of child
Pod::Elemental::Paragraphs.  This includes Pod documents, Pod5 regions, and
nested Pod elements produced by the Gatherer transformer.

=head1 PERL VERSION

This library should run on perls released even a long time ago.  It should work
on any version of perl released in the last five years.

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

=head1 ATTRIBUTES

=head2 children

This attribute is an arrayref of
L<Pod::Elemental::Node|Pod::Elemental::Node>-performing objects, and represents
elements contained by an object.

=head1 AUTHOR

Ricardo SIGNES <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
