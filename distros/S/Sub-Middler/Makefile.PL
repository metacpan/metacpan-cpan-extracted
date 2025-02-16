use 5.024000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Sub::Middler',
    VERSION_FROM      => 'lib/Sub/Middler.pm', 
    PREREQ_PM         => {

        "Export::These"=>0
    
      }, # e.g., Module::Name => 1.1
    ABSTRACT_FROM     => 'lib/Sub/Middler.pm', # retrieve abstract from module
    AUTHOR            => 'Ruben Westerberg <drclaw@mac.com>',
    LICENSE           => 'mit',
    META_ADD => {
        "meta-spec" => {
          version => 2
        },
        resources=> {
          repository =>{
            type => "git",
            url => "git://github.com/drclaw1394/perl-sub-middler.git",
            web => "https://github.com/drclaw1394/perl-sub-middler",
          }
        }
      }

);
