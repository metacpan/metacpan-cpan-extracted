


# = HISTORY SECTION =====================================================================

# This is a test PerlPoint import filter, for the test language LANG.

# ---------------------------------------------------------------------------------------
# version | date     | author   | changes
# ---------------------------------------------------------------------------------------
# 0.01    |19.04.2006| JSTENZEL | new.
# ---------------------------------------------------------------------------------------

# check perl version
require 5.00503;

# = PACKAGE SECTION ======================================================================

# declare package
package PerlPoint::Import::LANG;

# declare package version
$VERSION=0.01;


# = PRAGMA SECTION =======================================================================

# set pragmata
use strict;


# = LIBRARY SECTION ======================================================================

# declare the filter function (very similar to the second LANG filter in this test set)
sub importFilter
 {
  # flag variable
  my $paragraphStart=1;

  # we know that we get the lines in an array, so ...
  foreach (@main::_ifilterText)
   {
    # recognize empty lines which start new paragraphs
    $paragraphStart=1, next unless /\S/;

    # translate headlines
    $paragraphStart and s/^(\*+)\s*/'=' x length($1)/e and (($paragraphStart=0), next);

    # translate bullet points
    $paragraphStart and s/^-(\s+)/*$1/ and (($paragraphStart=0), next);
   }

  # supply result (add leading newlines to let the parser detect a *new*
  # paragraph and therefore recognize the special paragraph menaing of the
  # dot added by Pod::PerlPoint to the first paragraph)
  join('', "\n\n", @main::_ifilterText);
 }


# flag successful loading
1;



