package Scrapar::XMLQuery;

use strict;
use warnings;
use XML::XPath;
use XML::XPath::XMLParser;

sub xml_query {
  my $content = shift;
  my $query = shift || return;

  my $xp = XML::XPath->new(xml => $content);
  my $nodeset = $xp->find($query);

  return wantarray ? $nodeset->get_nodelist : [ $nodeset->get_nodelist ];
}

1;
