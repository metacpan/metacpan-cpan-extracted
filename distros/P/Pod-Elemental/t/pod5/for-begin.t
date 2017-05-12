#!perl
use strict;
use warnings;

use Test::More tests => 10;

use Pod::Elemental;
use Pod::Elemental::Transformer::Pod5;
use Pod::Elemental::Element::Pod5::Region;
use Pod::Elemental::Element::Pod5::Ordinary;

### =begin with content (no children)
my $begin_content = Pod::Elemental::Element::Pod5::Region->new({
  format_name => 'test',
  is_pod      => 1,
  content     => "This is a test.\n",
});

my $begin_content_expected = <<'END_FOR';
=begin :test This is a test.

=end :test

END_FOR

is(
  $begin_content->as_pod_string,
  $begin_content_expected,
  "Region with content is =begin/=end",
);

### =begin with children (no content)
my $begin_children = Pod::Elemental::Element::Pod5::Region->new({
  format_name => 'test',
  is_pod      => 1,
  content     => "\n",
  children    => [
    Pod::Elemental::Element::Pod5::Ordinary->new({
      content => "Ordinary paragraph 1.\n",
    }),
    Pod::Elemental::Element::Pod5::Ordinary->new({
      content => "Ordinary paragraph 2.\n",
    }),
  ],
});

my $begin_children_expected = <<'END_FOR';
=begin :test

Ordinary paragraph 1.

Ordinary paragraph 2.

=end :test

END_FOR

is(
  $begin_children->as_pod_string,
  $begin_children_expected,
  "Region with 2 children is =begin/=end",
);

### =begin nonpod with data para with newlines
my $input_pod = <<'END_POD';
=begin foo

Data 1

Data 1

=end foo

END_POD

my $begin_2data = Pod::Elemental->read_string($input_pod);
Pod::Elemental::Transformer::Pod5->transform_node($begin_2data);

my $begin_2data_expected = <<'END_BEGIN';
=begin foo

Data 1

Data 1

=end foo

END_BEGIN

is(
  $begin_2data->children->[0]->as_pod_string,
  $begin_2data_expected,
  "1 data para w/newlines",
);

### =begin with children and content
my $begin_both = Pod::Elemental::Element::Pod5::Region->new({
  format_name => 'test',
  is_pod      => 1,
  content     => "This is a test.\n",
  children    => [
    Pod::Elemental::Element::Pod5::Ordinary->new({
      content => "Ordinary paragraph.\n",
    }),
  ],
});

my $begin_both_expected = <<'END_FOR';
=begin :test This is a test.

Ordinary paragraph.

=end :test

END_FOR

is(
  $begin_both->as_pod_string,
  $begin_both_expected,
  "Region with content & children is =begin/=end",
);

### a region with para with blanks should become =begin, not =for
{
  my $begin_with_content_blanks = Pod::Elemental::Element::Pod5::Region->new({
    format_name => 'test',
    is_pod      => 0,
    content     => "\n",
    children    => [
      Pod::Elemental::Element::Pod5::Data->new({
        content => "Ordinary\n \n paragraph.",
      }),
    ],
  });

  my $expected = <<'END_FOR';
=begin test

Ordinary
 
 paragraph.

=end test

END_FOR

  is(
    $begin_with_content_blanks->as_pod_string,
    $expected,
    "region with 1 child that has blanks is =begin",
  );
}

### =for
my $for = Pod::Elemental::Element::Pod5::Region->new({
  format_name => 'test',
  is_pod      => 1,
  content     => "\n",
  children    => [
    Pod::Elemental::Element::Pod5::Ordinary->new({
      content => "Ordinary paragraph.\n",
    }),
  ],
});

my $for_expected = <<'END_FOR';
=for :test Ordinary paragraph.

END_FOR

is(
  $for->as_pod_string,
  $for_expected,
  "Region with 1 child and no content is =for",
);

### parse a non-pod =for
my $for_np_pod = <<'END_POD';
=pod

=for foo This is the content.

=cut
END_POD

my $for_np = Pod::Elemental->read_string($for_np_pod);
Pod::Elemental::Transformer::Pod5->new->transform_node($for_np);

my $for_np_elem = $for_np->children->[0];

ok(
  $for_np_elem->isa('Pod::Elemental::Element::Pod5::Region'),
  "a =for (non-pod) element becomes a region",
);

ok(
  $for_np_elem->children->[0]->isa('Pod::Elemental::Element::Pod5::Data'),
  "...and its content became a data paragraph",
);

my $for_pl_pod = <<'END_POD';
=pod

=for :foo This is the content.

=cut
END_POD

### parse a podlike =for
my $for_pl = Pod::Elemental->read_string($for_pl_pod);
Pod::Elemental::Transformer::Pod5->new->transform_node($for_pl);

my $for_pl_elem = $for_pl->children->[0];

ok(
  $for_pl_elem->isa('Pod::Elemental::Element::Pod5::Region'),
  "a =for (pod-like) element becomes a region",
);

ok(
  $for_pl_elem->children->[0]->isa('Pod::Elemental::Element::Pod5::Ordinary'),
  "...and its content became an ordinary paragraph",
);
