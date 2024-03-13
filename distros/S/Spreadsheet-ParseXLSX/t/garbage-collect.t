#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Scalar::Util 'weaken';

use Spreadsheet::ParseXLSX;

my $wb = Spreadsheet::ParseXLSX->new->parse('t/data/Test.xlsx');
my $ws1 = $wb->worksheet(0);
my $cell = $ws1->get_cell(0,0);

ok(defined $wb && defined $ws1 && defined $cell, '3 object references');

weaken($wb);
weaken($ws1);
weaken($cell);

ok(!defined $wb, 'workbook freed');   # note explain $wb;
ok(!defined $ws1, 'worksheet freed'); # note Devel::FindRef::track($ws1);
ok(!defined $cell, 'cell freed' );

# Now find out whether the XML::Twig instances get freed.
my @xml_objects;
my $xml_twig_new= \&XML::Twig::new;
sub trace_xml_ctor {
  my $self= &$xml_twig_new;
  push @xml_objects, $self;
  Scalar::Util::weaken($xml_objects[-1]);
  $self;
}
{ no warnings;
  *XML::Twig::new= \&trace_xml_ctor;
}

# Create multiple spreadsheet objects, and let them get freed
for (1..3) {
  Spreadsheet::ParseXLSX->new->parse('t/data/Test.xlsx');
}

TODO: {
  local $TODO = 'Maybe a bug in XML::Twig?';
  # I can't figure out why, but the most recent XML::Twig object remains
  # un-collected until the next XML::Twig gets parsed.  This would indicate
  # that rather than a self-reference, there is a global somewhere that is
  # referring to it, and that global gets overwritten on next construction.
  # I don't see any globals or 'state' variables in this module, so assume
  # it must be XML::Twig or one of that one's deps.
  is( scalar(grep defined, @xml_objects), 0, 'All XML::Twig cleaned up' )
    or note explain(\@xml_objects);
}

done_testing;
