# This file uses the "Perlish" coding style
# please read http://perl.4pro.net/perlish_coding_style.html

; use 5.006_001
; use ExtUtils::MakeMaker

; my $pm = 'lib/Template/Magic.pm'

; WriteMakefile
   ( NAME           => 'Template::Magic'
   , VERSION_FROM   => $pm
   , ( $] ge '5.005' )
     ? ( AUTHOR          => 'Domizio Demichelis - perl.4pro.net'
       , ABSTRACT_FROM   => $pm
       )
     : ()
   , PREREQ_PM      => { 'Class::constr'    => 2.1
                       , 'Class::props'     => 2.1
                       , 'Object::props'    => 2.1
                       , 'Class::Util'      => 2.1
                       , 'IO::Util'         => 1.46
                       , 'File::Spec'       => 0
                       }
   )


; 1

