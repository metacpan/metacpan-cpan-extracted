use Inline::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Ogg::Vorbis::Header',
    'VERSION_FROM'	=> 'Header.pm', # finds $VERSION
    'PREREQ_PM'		=> {
       Inline::C         => 0,
    }, # e.g., Module::Name => 1.1
    'CONFIGURE_REQUIRES'    => {
       Inline::MakeMaker => 0,
    },
    META_MERGE => {
       'meta-spec' => { version => 2 },
       dynamic_config => 0,
    },
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Header.pm', # retrieve abstract from module
       AUTHOR     => 'Dan Pemstein <dan@lcws.org>') : ()),
);
