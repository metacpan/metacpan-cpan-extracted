use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	      NAME              => 'TM::Easy',
	      VERSION_FROM      => 'lib/TM/Easy.pm', # finds $VERSION
              PREREQ_PM      => { # do a 'make dependencies' to get an update
		  'TM'            => '1.44',
		  "Test::More"    => 0.47,
	      },
	      ABSTRACT_FROM  => 'lib/TM/Easy.pm', # retrieve abstract from module
	      AUTHOR         => 'Robert Barta <rho@devc.at>');

package MY;

sub depend {
    return <<MAKE

dependencies:
	scandeps.pl `grep .pm MANIFEST` `grep bin/ MANIFEST`| grep -v undef

manifesto:
	find lib/ -iname '*.pm' | sort
	find t    -iname '*.t'  | sort

upload:
	cpan-upload TM-Easy-\$(VERSION).tar.gz

debian:
	dh-make-perl --build TM-Easy-\$(VERSION)/

MAKE
}
