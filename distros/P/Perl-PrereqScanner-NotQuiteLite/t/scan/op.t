use strict;
use warnings;
use t::scan::Util;

test(<<'TEST'); # MSERGEANT/XML-QL-0.07/QL.pm
    if ( ( ! $cm->{done} ) && ( $expat->context < $cm->{fail} ) ) {
      $cm->{done} = 1;
      $cm->{reason} = "out of context on $element";
    }
TEST

done_testing;
