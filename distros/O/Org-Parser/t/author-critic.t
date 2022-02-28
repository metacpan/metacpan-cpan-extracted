#!perl

BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}


use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Perl::Critic::Subset 3.001.006

use Test::Perl::Critic (-profile => "") x!! -e "";

my $filenames = ['lib/Org/Document.pm','lib/Org/Element.pm','lib/Org/Element/Block.pm','lib/Org/Element/BlockRole.pm','lib/Org/Element/Comment.pm','lib/Org/Element/Drawer.pm','lib/Org/Element/FixedWidthSection.pm','lib/Org/Element/Footnote.pm','lib/Org/Element/Headline.pm','lib/Org/Element/InlineRole.pm','lib/Org/Element/Link.pm','lib/Org/Element/List.pm','lib/Org/Element/ListItem.pm','lib/Org/Element/RadioTarget.pm','lib/Org/Element/Role.pm','lib/Org/Element/Setting.pm','lib/Org/Element/Table.pm','lib/Org/Element/TableCell.pm','lib/Org/Element/TableHLine.pm','lib/Org/Element/TableRow.pm','lib/Org/Element/Target.pm','lib/Org/Element/Text.pm','lib/Org/Element/TimeRange.pm','lib/Org/Element/Timestamp.pm','lib/Org/Parser.pm'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
