use strict;
use warnings;

use Test::More;

use Pod::Elemental;
use Pod::Elemental::Transformer::Pod5;
use Pod::Elemental::Transformer::WikiDoc;

my $str = do { local $/; <DATA> };

my $doc = Pod::Elemental->read_string($str);

Pod::Elemental::Transformer::Pod5->new->transform_node($doc);
Pod::Elemental::Transformer::WikiDoc->new->transform_node($doc);

isa_ok(
  $doc->children->[0],
  'Pod::Elemental::Element::Pod5::Command',
  '0th elem',
);

isa_ok(
  $doc->children->[1],
  'Pod::Elemental::Element::Pod5::Command',
  '1th elem',
);

is($doc->children->[1]->command, 'over', '=for para became =over etc');

isa_ok(
  $doc->children->[9],
  'Pod::Elemental::Element::Pod5::Ordinary',
  '9th elem (after =for)',
);

isa_ok(
  $doc->children->[10],
  'Pod::Elemental::Element::Pod5::Command',
  '10th elem (== Reasons)',
);

is($doc->children->[10]->command, 'head2', 'wikidoc == becomes head2');

done_testing;

__DATA__
=pod

=head1 Welcome to Pod!

=for wikidoc
* this
* is
* awesome

Right??

=begin wikidoc

== Reasons to use WikiDoc:

* lists
* more lists
* seriously, they're easy

Also...

0 well, mostly lists
0 yeah, I know, it's silly
0 but they're great

=end wikidoc

The end!
