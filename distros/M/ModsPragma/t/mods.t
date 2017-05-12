# $Id: mods.t 1.7 Fri, 12 Sep 1997 23:21:20 -0400 jesse $ -*- Perl -*-

use strict;

# Sort of sneaky.
use mods q{			# Leading & trailing w.s.
  $sample,			# Extra comment
  $sample2;
  {$VERSION=17}
  Test::Helper
};

test {
  comm 'Testing version';
  import mods 0.003;
  comm 'Dividing 5/2';
  my $foo=5/2;
  ok $foo==2;
  no integer;
  ok $VERSION > 0;
  comm 'Using $sample';
  $sample=5;
  ok $sample==5;
};
