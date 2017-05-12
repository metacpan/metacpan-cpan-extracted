use ExtUtils::MakeMaker;

WriteMakefile(
   'NAME'         => 'StatsView::Oracle',
   'VERSION_FROM' => 'Oracle.pm',
   'PMLIBDIRS'    => [ 'Oracle' ],
);
