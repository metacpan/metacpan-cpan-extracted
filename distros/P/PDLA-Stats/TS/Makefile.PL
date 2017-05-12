   use PDLA::Core::Dev;
   use ExtUtils::MakeMaker;
   PDLA::Core::Dev->import();
   
   $package = ["ts.pp",TS,PDLA::Stats::TS];
   %hash = pdlpp_stdargs($package);

   WriteMakefile( %hash );
   
   sub MY::postamble {pdlpp_postamble($package)};
