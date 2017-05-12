use strict;
use Rinchi::Fortran::Preprocessor;

my @args = (
  'test.pl',
  '-I/usr/include',
  "-C",
  '-Ucym',
#  '-DLeft:Chwith',
#  '-DRight:De',

#  '-Udeu',
#  '-DLeft:Linke',
#  '-DRight:Rechte',

#  '-Ueng',

#  '-Uina',
#  '-DLeft:Sinistra',
#  '-DRight:Dextra',

#  '-Uita',#  '-DLeft:Sinistra',
#  '-DRight:Destra',

#  '-Ulat',
#  '-DLeft:Sinister',
#  '-DRight:Dexter',

#  '-Upor',
#  '-DLeft:Esquerda',
#  '-DRight:Dereita',
#  '-DLeft:Izquierda',
#  '-DRight:Derecha',
#  '-Uspa',
#  '--debug',
);

my $fpp = new Rinchi::Fortran::Preprocessor;
$fpp->new_source("test_src/bisect.f90",\@args);

