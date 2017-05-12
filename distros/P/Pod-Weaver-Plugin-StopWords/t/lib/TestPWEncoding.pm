# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
package TestPWEncoding;

# a tiny version of Pod::Weaver::Plugin::Encoding

use Moose;
with 'Pod::Weaver::Role::Finalizer';

use Pod::Elemental::Element::Pod5::Command;

sub finalize_document {
  my ($self, $document) = @_;

  # Short-circuit if there already is an encoding directive.
  return
    if grep {
      eval {
        $_->isa('Pod::Elemental::Element::Pod5::Command') &&
        $_->command eq 'encoding'
      }
    } @{ $document->children };

  unshift @{ $document->children },
    Pod::Elemental::Element::Pod5::Command->new({
      command => 'encoding',
      content => 'UTF-8',
    });
}

__PACKAGE__->meta->make_immutable;

1;
