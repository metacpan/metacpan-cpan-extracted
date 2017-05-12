require 5.008_001;
use ExtUtils::MakeMaker;

WriteMakefile( 
   'DISTNAME' => 'S-SymObj',
   'NAME' => 'SymObj',
   'VERSION_FROM' => 'lib/SymObj.pm',
   (
   ABSTRACT => 'Easy creation of symbol-tables and objects',
   AUTHOR => 'Steffen (Daode) Nurpmeso <steffen@sdaoden.eu>',
   LICENSE => 'ISC',
   )
);

# s-it-mode
