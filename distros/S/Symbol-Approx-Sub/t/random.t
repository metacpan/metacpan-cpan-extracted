use strict;
use warnings;

use Test::More;

use Symbol::Approx::Sub
  xform  => undef, # undef - use no transformer
  choose => undef, # undef - use default chooser
  match  => \&match_sas;

sub sas_1 { 'sas1' }

sub sas_2 { 'sas2' }

like(sas(), qr/^sas/, 'sas() calls sas_1() or sas_2()');

done_testing;

sub match_sas {
  my ($sub, @subs) = @_;
  return grep { $subs[$_] =~ /^sas_/ } 0 .. $#subs;
}
