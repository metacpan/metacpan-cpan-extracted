use Inline::MakeMaker;

print $^O, "\n";

if ($^O eq 'linux') {
  warn <<'EOFTEXT';
This module is a wrapper around the libogg and libvorbis libraries. These
libraries (along with their development tools - which are also required)
should be available as prebuilt packages for your Linux installation.
For example, if you're using Ubuntu, you can install them with the command:

  $ sudo apt-get install libinline-perl libogg-dev libvorbis-dev

Otherwise, you can get them from https://xiph.org/.

If your build fails with messages about missing libraries (or missing C
header files) then this is probably the reason). Please install the missing
libraries and try again.

EOFTEXT
} else {
  warn <<'EOFTEXT';
This module is a wrapper around the libogg and libvorbis libraries. You
will need to install these libraries (along with their development tools)
before you can successfully build and install this module. The libraries
are available from https://xiph.org/.

If your build fails with messages about missing libraries (or missing C
header files) then this is probably the reason). Please install the missing
libraries and try again.

If you would like to help the maintainer of this module to support this module
on your operating system, then please contact him at dave@perlhacks.com.

In order to continue attempting to build this module, please set the
environment variable PERL_BUILD_OGG_VORBIS_HEADER to 1 and rerun this command.

EOFTEXT

  exit unless $ENV{PERL_BUILD_OGG_VORBIS_HEADER};
}

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
          url  => 'https://github.com/davorg-cpan/Ogg-Vorbis-Header.git',
          web  => 'https://github.com/davorg-cpan/Ogg-Vorbis-Header',
        },
        bugtracker => {
          web  => 'https://github.com/davorg-cpan/Ogg-Vorbis-Header/issues',
        },
      },
    },
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/Ogg/Vorbis/Header.pm', # retrieve abstract from module
       AUTHOR     => 'Dan Pemstein <dan@lcws.org>') : ()),
);
