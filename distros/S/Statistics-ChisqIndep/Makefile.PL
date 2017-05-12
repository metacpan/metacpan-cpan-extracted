use ExtUtils::MakeMaker;

$VERSION  = "0.1";


WriteMakefile(
    'DISTNAME' => "Statistics-ChisqIndep",
    'NAME' => "Statistics::ChisqIndep",
    'AUTHOR' =>'Yun-Fang Juan <yunfangjuan@yahoo.com>', 
    'ABSTRACT' =>"Module to perfrom Pearson's Chi-Square Test",
    'VERSION' => $VERSION,
    'PM' => { 
        'ChisqIndep.pm' 
                => '$(INST_LIBDIR)/ChisqIndep.pm',
    },

   'PREREQ_PM'         => { 
        'Statistics::Distributions' => 1.02,
    },

);


