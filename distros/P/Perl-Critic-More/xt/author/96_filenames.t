#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More;

use Test::Portability::Files;

if (Test::Portability::Files->VERSION eq '0.05') {
   # Workaround for bug in v0.05: options() is broken -- can't turn off tests
   #    http://rt.cpan.org//Ticket/Display.html?id=21631
   # HACK: filter out too-long filenames in advance
   no warnings;
   *Test::Portability::Files::maniread = sub {
      my %manifest = %{ExtUtils::Manifest::maniread()};
      my @long_keys = grep {0 < scalar grep {31 < length() && 39 > length()} File::Spec->splitdir($_)} keys %manifest;
      delete $manifest{$_} for @long_keys;
      return \%manifest;
   };
} else {
    options(test_amiga_length => 0, test_mac_length => 0);
}
run_tests();

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
