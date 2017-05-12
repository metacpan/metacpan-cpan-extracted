use strict;
use warnings;

use Test::More;

use lib 't/lib';
use TestGlob qw($Alpha);

$TestGlob::Alpha = 1;

is($TestGlob::Alpha, 1, '$TestGlob was just assigned to');

is($Alpha, 1, '...so $Alpha is set');

$Alpha = 2;
is($TestGlob::Alpha, 2, 'we updated $Alpha so $TestGlob::A is updated');

{
  local $Alpha = 3;
  is($Alpha, 3, 'updated local $Alpha');
  is($TestGlob::Alpha, 3, 'updated local $Alpha so $TestGlob::A is updated');
}

is($Alpha, 2, 'localization over ($Alpha)');
is($TestGlob::Alpha, 2, 'localization over ($TestGlob::Alpha)');

{
  package Renamed;
  use TestGlob q($Alpha) => { -as => 'Ctx' };

  main::is($Renamed::Ctx, 2, 'imported $Alpha as Ctx');
  main::is($Ctx, 2, 'imported $Alpha as Ctx');
}

{
  package Captured;
  my $Ctx;
  use TestGlob q($Alpha) => { -as => \$Ctx };

  main::is($$Ctx, 2, 'imported *Alpha into $Ctx');

  $$Ctx = 3;

  main::is($TestGlob::Alpha, 3, 'still globby');
}

done_testing;
