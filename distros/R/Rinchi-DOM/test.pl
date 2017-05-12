use strict;
use Rinchi::DOM;
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

my $rd = new Rinchi::DOM;

my $fpp = new Rinchi::Fortran::Preprocessor;

my $document = $rd->process_to_DOM($fpp, 'test_src/bisect.f90',\@args);

$document->printToFile ('bisect.f90.xml');

