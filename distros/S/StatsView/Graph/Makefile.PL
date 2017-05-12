use ExtUtils::MakeMaker;

WriteMakefile(
   'NAME'         => 'StatsView::Graph',
   'VERSION_FROM' => 'Graph.pm',
   'PMLIBDIRS'    => [ 'Graph' ],
);
