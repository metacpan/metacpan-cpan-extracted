#!perl
use strict;
use warnings;

use Test::More;

use Pod::Elemental;
use Pod::Elemental::Transformer::Pod5;
use Pod::Elemental::Element::Pod5::Region;
use Pod::Elemental::Element::Pod5::Ordinary;

my $for_pl_pod = <<'END_POD';

This is not a Pod paragraph.

=cut
END_POD

### parse a podlike =for
my $for_pl = Pod::Elemental->read_string($for_pl_pod);
Pod::Elemental::Transformer::Pod5->new->transform_node($for_pl);

my $para = $for_pl->children->[0];
isa_ok($para, 'Pod::Elemental::Element::Pod5::Nonpod');

done_testing;
