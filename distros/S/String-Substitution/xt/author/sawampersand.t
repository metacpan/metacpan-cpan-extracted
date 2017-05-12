# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
use strict;
use warnings;
use Test::More tests => 1;
use String::Substitution ();

# test that $& is not seen in the module

SKIP: {
  my $mod = 'Devel::SawAmpersand';
  eval "require $mod; ${mod}->import('sawampersand'); 1";
  skip "$mod required to test if \$& was found", 1
    if $@;
  ok( !sawampersand(), 'Ampersand not seen');
}
