use ExtUtils::MakeMaker;

$VERSION  = "1.1";


WriteMakefile(
    'DISTNAME' => "Statistics-TTest",
    'NAME' => "Statistics::TTest",
    'AUTHOR' =>'Yun-Fang Juan <yunfangjuan@yahoo.com>', 
    'ABSTRACT' =>"Module to perfrom T-Test",
    'VERSION' => $VERSION,
    'PM' => { 
        'PointEstimation.pm' 
                => '$(INST_LIBDIR)/PointEstimation.pm',
        'TTest.pm' 
                => '$(INST_LIBDIR)/TTest.pm',
    },

   'PREREQ_PM'         => { 
        'Statistics::Descriptive' => 2.6, 
        'Statistics::Distributions' => 0.07,
    },
  

);


