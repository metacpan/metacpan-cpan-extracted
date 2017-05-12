use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.


BEGIN {

local $^W = 0;     
  eval { require MARC::Base; }; 
   local $^W = 1;     
   if ($@) {
   if (!chdir("MARC")){ 	  
     print qq(\n------------------
     Net::Z3950::AscyncZ requires MARC::Base: 
     I couldn't change directory to ./MARC;
     please untar ./MARC/MARC.tar and install it yourself \n----------\n\n);	      
   }
   else {
     system("tar -xf MARC.tar");
     system("pwd");
     chdir("../"); 
     system("pwd");	  
     if (!open(MANIFEST, ">> MANIFEST")) {
          warn "can't add MARC module to Manifest; ",
      " please untar and install MARC/MARC.tar yourself\n";
     }
     else {     
        my $old_fh = select(MANIFEST); 
        $| = 1;
        print MANIFEST "MARC/MANIFEST\nMARC/Base.pm\nMARC/HTML.pm\nMARC/META.pm\n",
                    "MARC/Makefile.PL\nMARC/test.pl\nMARC/README.txt\n";       
       close MANIFEST;
       select $old_fh;
     }     
   }
  }
}





WriteMakefile(
    'NAME'		=> 'Net::Z3950::AsyncZ',
    'VERSION_FROM'	=> 'AsyncZ.pm', # finds $VERSION
    'PREREQ_PM'		=> {
                              MARC::Record =>1.15,                             
			      Net::Z3950 => 0.31,	
			      Event => 0.86,
			      IPC::ShareLite => 0.09		
                           }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'doc/AsyncZ.pod', 
       AUTHOR     => 'Myron Turner <turnermm@shaw.ca>') : ()),
);







