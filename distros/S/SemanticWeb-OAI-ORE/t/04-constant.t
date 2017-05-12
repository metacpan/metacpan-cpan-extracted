#!perl

use strict;

use Test::More;
use SemanticWeb::OAI::ORE::Constant qw(:all);
plan(tests=>5);

foreach my $t ( 
    [ '', '', 'nothing to nothing' ],
    [ 'a', 'a' ],
    [ 'dc:title', 'http://purl.org/dc/elements/1.1/title' ],
    [ 'dc:junk', 'http://purl.org/dc/elements/1.1/junk' ],
    [ 'http://purl.org/dc/elements/1.1/title', 'http://purl.org/dc/elements/1.1/title' ],
    ) {
  my ($in,$out,$comment)=@$t;
  $comment||="$in -> $out";
  is( expand_qname($in), $out, "expand_qname: $comment");
}
