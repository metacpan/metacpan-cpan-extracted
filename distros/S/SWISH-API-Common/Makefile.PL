######################################################################
# Makefile.PL for SWISH::API::Common
# 2005, Mike Schilli <cpan@perlmeister.com>
######################################################################
use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'         => 'SWISH::API::Common',
    'VERSION_FROM' => 'lib/SWISH/API/Common.pm', # finds $VERSION
    'PREREQ_PM'    => {
                        Sysadm::Install => 0,
                        Log::Log4perl   => 0,
                        SWISH::API      => 0,
                        File::Path      => 0,
                        File::Find      => 0,
                        File::Basename  => 0,
                        File::Temp      => 0,
                        File::Copy      => 0,
                        LWP::Simple     => 0,
                      }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/SWISH/API/Common.pm',
       AUTHOR     => 'Mike Schilli <cpan@perlmeister.com>') : ()),
);

my $version = `swish-e -V`;

if($version !~ /SWISH/) {
        print <<EOT;

     !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
     This module requires SWISH-E, available from 
         http://swish-e.org/download/index.html
     Please download and install it prior to installing this module.
     Steps:
         tar zxfv swish-e-2.4.x.tar.gz
         cd swish-e-2.4.x
         ./configure
         make
         make install
         cd perl
         export LD_RUN_PATH=/usr/local/lib
         perl Makefile.PL
         make install
     !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
EOT
     my $build = ExtUtils::MakeMaker::prompt(
         "Do you want me to download/build it for you ([y]/n)?", "y");
     if($build =~ /y/) {
         if($< != 0) {
             print "You need to be root to do that.\n";
             exit 0;
         }
         require File::Temp;
         require File::Copy;
         require LWP::Simple;
         my $dir = File::Temp::tempdir(CLEANUP => 1);
         #print "*** Temporary directory: $dir\n";
         chdir $dir or die "Cannot chdir to $dir";
         my $distro = "swish-e-2.4.3.tar.gz";
         (my $distrodir = $distro) =~ s/\.tar\.gz$//g;
         print "Downloading $distro ...\n";
#File::Copy::copy("/tmp/$distro", "$dir/$distro");
         LWP::Simple::getstore(
                 "http://swish-e.org/distribution/$distro", $distro);
         print "Done. Unpacking ...\n";
         system("tar zxf $distro");
         print "Done. Building ...\n";
         system("cd $distrodir; ./configure; make; LD_LIBRARY_PATH=/usr/local/lib make install;");
         system("cd $distrodir; cd perl; " .
                "LD_LIBRARY_PATH=/usr/local/lib LD_RUN_PATH=/usr/local/lib perl Makefile.PL; make install");
         print "Done.\n";
             # Step out of 
         chdir "/";
    }

    exit 0;
}
