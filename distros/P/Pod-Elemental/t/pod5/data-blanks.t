#!/usr/bin/env perl
use strict;
use warnings;
use Pod::Elemental;
use Pod::Elemental::Transformer::Pod5;

use Test::More;

my $string = <<'END_POD';

=begin foo

=over 4

=item * foo

bar

=item * bar

baz

=back

=end foo

END_POD

my $document = Pod::Elemental->read_string($string);

Pod::Elemental::Transformer::Pod5->new->transform_node($document);

like(
  $document->as_pod_string,
  qr{^=item \* bar\n\nbaz\n\n=back}m,
  "we do not drop newlines in data paragraphs",
);

done_testing;
