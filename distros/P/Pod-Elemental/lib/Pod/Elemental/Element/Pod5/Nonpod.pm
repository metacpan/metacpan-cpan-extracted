package Pod::Elemental::Element::Pod5::Nonpod;
# ABSTRACT: a non-pod element in a Pod document
$Pod::Elemental::Element::Pod5::Nonpod::VERSION = '0.103004';
use Moose;
with 'Pod::Elemental::Flat';
with 'Pod::Elemental::Autoblank';

#pod =head1 OVERVIEW
#pod
#pod A Pod5::Nonpod element represents a hunk of non-Pod content found in a Pod
#pod document tree.  It is equivalent to a
#pod L<Generic::Nonpod|Pod::Elemental::Element::Generic::Nonpod> element, with the
#pod following differences:
#pod
#pod =over 4
#pod
#pod =item * it includes L<Pod::Elemental::Autoblank>
#pod
#pod =item * when producing a pod string, it wraps the non-pod content in =cut/=pod
#pod
#pod =back
#pod
#pod =cut

use namespace::autoclean;

sub as_pod_string {
  my ($self) = @_;
  return sprintf "=cut\n%s=pod\n", $self->content;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Elemental::Element::Pod5::Nonpod - a non-pod element in a Pod document

=head1 VERSION

version 0.103004

=head1 OVERVIEW

A Pod5::Nonpod element represents a hunk of non-Pod content found in a Pod
document tree.  It is equivalent to a
L<Generic::Nonpod|Pod::Elemental::Element::Generic::Nonpod> element, with the
following differences:

=over 4

=item * it includes L<Pod::Elemental::Autoblank>

=item * when producing a pod string, it wraps the non-pod content in =cut/=pod

=back

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
