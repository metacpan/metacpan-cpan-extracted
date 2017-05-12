use 5.006;
use ExtUtils::MakeMaker;
WriteMakefile( 'NAME'	   	=> 'PDF::Reuse::OverlayChart',
               'VERSION_FROM'	=> 'OverlayChart.pm', 
               'PREREQ_PM'		=> {PDF::Reuse => 0} );
