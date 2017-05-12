#!perl
use strict;
use warnings;

use Test::More tests => 1;

use Pod::Elemental::Element::Pod5::Command;
use Pod::Elemental::Element::Pod5::Ordinary;
use Pod::Elemental::Element::Nested;

my $nested = Pod::Elemental::Element::Nested->new({
  command  => 'head1',
  content  => "Header 1.\n",
  children => [
    Pod::Elemental::Element::Pod5::Command->new({
      command => 'head2',
      content => "Header 2.1.\n",
    }),
    Pod::Elemental::Element::Pod5::Ordinary->new({
      content => "Ordinary.\n",
    }),
    Pod::Elemental::Element::Pod5::Command->new({
      command => 'head2',
      content => "Header 2.2.\n",
    }),
  ],
});

my $pod_expected = <<'END_FOR';
=head1 Header 1.

=head2 Header 2.1.

Ordinary.

=head2 Header 2.2.

END_FOR

is(
  $nested->as_pod_string,
  $pod_expected,
  "nested element pod-stringifies as expected",
);
