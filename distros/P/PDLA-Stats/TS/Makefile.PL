   use PDLA::Core::Dev;
   use ExtUtils::MakeMaker;
   PDLA::Core::Dev->import();
   
   $package = ["ts.pd",TS,PDLA::Stats::TS];
   %hash = pdlpp_stdargs($package);

   WriteMakefile( %hash );
   
   sub MY::postamble {pdlpp_postamble($package)};
