#!perl -T

use strict;
use warnings;

use Config qw<%Config>;

use Test::More tests => 4;

BEGIN {
 require XSLoader;
 my $xsloader_load_orig = \&XSLoader::load;
 no warnings 'redefine';
 *XSLoader::load = sub {
  die if $_[0] eq 'Scalar::Vec::Util';
  goto $xsloader_load_orig;
 };
}

use Scalar::Vec::Util qw<vfill vcopy veq SVU_PP>;

is SVU_PP, 1, 'using pure perl subroutines';
for (qw<vfill vcopy veq>) {
 no strict 'refs';
 is *{$_}{CODE}, *{'Scalar::Vec::Util::'.$_}{CODE}, $_ .' is ' . $_ . '_pp';
}
