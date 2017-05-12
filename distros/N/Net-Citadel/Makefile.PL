use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Net::Citadel',
    VERSION_FROM      => 'lib/Net/Citadel.pm', # finds $VERSION
    ABSTRACT_FROM     => 'lib/Net/Citadel.pm', # retrieve abstract from module
    AUTHOR            => 'Robert Barta <rho@devc.at>, Robert James Clay <jame@rocasa.us>',
    LICENSE           => 'perl',
    MIN_PERL_VERSION  => '5.6.0',
    PREREQ_PM         => {
           'Readonly' => '0',
    },
    BUILD_REQUIRES    => {
       'Config::YAML' => '1.42',
         'Test::More' => '0',
          'Test::Pod' => '0',
    },
    META_MERGE        => {
            resources => {
                repository  =>  'https://github.com/jame/Net-Citadel',
            },
    },
    dist              => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', ZIPFLAGS => '-or9',},
    clean             => { FILES => 'Net-Citadel-*' },
);

package MY;

sub depend {
    return <<MAKE

inject:
	mcpani --add --module Net::Citadel --authorid JAME --modversion \$(VERSION) --file Net-Citadel-\$(VERSION).tar.gz
	sudo mcpani --inject

debian:
	(cd /usr/local/share/packages; rm -rf Net-Cita* ; dh-make-perl --cpan-mirror file:/usr/local/share/minicpan --build --cpan Net::Citadel --notest)


upload:
	cpan-upload-http Net-Citadel-\$(VERSION).tar.gz

MAKE
}
