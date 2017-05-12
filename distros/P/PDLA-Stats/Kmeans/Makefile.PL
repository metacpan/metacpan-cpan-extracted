   use PDLA::Core::Dev;
   use ExtUtils::MakeMaker;
   PDLA::Core::Dev->import();
   
   $package = ["kmeans.pp",Kmeans,PDLA::Stats::Kmeans];
   %hash = pdlpp_stdargs($package);
   
   WriteMakefile( %hash );
   
   sub MY::postamble {pdlpp_postamble($package)};
