#!perl
use strict;
use warnings;

# PURPOSE:
# show that we can have a "foo" region inside another "foo" region

use Test::More tests => 1;
use Test::Deep;
use Test::Differences;

use Pod::Eventual::Simple;
use Pod::Elemental::Objectifier;
use Pod::Elemental::Transformer::Pod5;
use Pod::Elemental::Document;

my $string = do {
  local $/;
  open my $fh, '<', 't/eg/nested-begin.pod';
  <$fh>;
};

my @events   = grep { $_->{type} ne 'nonpod' } @{ Pod::Eventual::Simple->read_file('t/eg/nested-begin.pod') };
my $elements = Pod::Elemental::Objectifier->objectify_events(\@events);

my $document = Pod::Elemental::Document->new({
  children => $elements
});

Pod::Elemental::Transformer::Pod5->transform_node($document);

eq_or_diff($document->as_pod_string, $string, 'we got what we expected');

