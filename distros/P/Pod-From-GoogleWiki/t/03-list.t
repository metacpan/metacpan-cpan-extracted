#!/usr/bin/perl

use Test::More tests => 2;
use Pod::From::GoogleWiki;

my $wiki = <<'WIKI';
  * A list
  * Of bulleted items
    # This is a numbered sublist
    # Which is done by indenting further
  * And back to the main bulleted list
WIKI
my $pod = <<'POD';

  * A list
  * Of bulleted items
    # This is a numbered sublist
    # Which is done by indenting further
  * And back to the main bulleted list

POD

my $pfg = Pod::From::GoogleWiki->new();
my $ret_pod = $pfg->wiki2pod($wiki);
is($ret_pod, $pod, 'b/i OK');

$wiki = <<'WIKI';
 * This is also a list
 * With a single leading space
 * Notice that it is rendered
  # At the same levels
  # As the above lists.
 * Despite the different indentation levels.
WIKI
$pod = <<'POD';

 * This is also a list
 * With a single leading space
 * Notice that it is rendered
  # At the same levels
  # As the above lists.
 * Despite the different indentation levels.

POD
$ret_pod = $pfg->wiki2pod($wiki);
is($ret_pod, $pod, 'code OK');
