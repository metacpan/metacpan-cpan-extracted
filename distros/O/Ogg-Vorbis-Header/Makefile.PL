use Inline::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'         => 'Ogg::Vorbis::Header',
    'VERSION_FROM' => 'lib/Ogg/Vorbis/Header.pm', # finds $VERSION
    'LICENSE'      => 'gpl_2',
    'PREREQ_PM'    => {
       Inline::C   => 0,
    }, # e.g., Module::Name => 1.1
    'CONFIGURE_REQUIRES' => {
       Inline::MakeMaker => 0,
    },
    META_MERGE => {
       'meta-spec' => { version => 2 },
       dynamic_config => 0,
      resources => {
        repository => {
          type => 'git',
          url  => 'https://github.com/davorg/Ogg-Vorbis-Header.git',
          web  => 'https://github.com/davorg/Ogg-Vorbis-Header',
        },
        bugtracker => {
          web  => 'https://github.com/davorg/Ogg-Vorbis-Header/issues',
        },
      },
    },
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/Ogg/Vorbis/Header.pm', # retrieve abstract from module
       AUTHOR     => 'Dan Pemstein <dan@lcws.org>') : ()),
);
