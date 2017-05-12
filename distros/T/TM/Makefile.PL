use 5.010;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	      NAME           => 'TM',
	      VERSION_FROM   => 'lib/TM.pm', # finds $VERSION
	      ABSTRACT_FROM  => 'lib/TM.pm',
	      AUTHOR         => 'Robert Barta <drrho@cpan.org>',
	      EXE_FILES      => [ 'bin/tm' ],
              NOECHO         => '@',
              PREREQ_PM      => { # do a 'make dependencies' to get an update
		  'BerkeleyDB'        => '0.26',
		  "Config::General"   => 2.26,
		  "Class::Trait"      => 0.22,
		  "Log::Log4perl"     => 0.50,
		  'LWP::Simple'       => 1.41,
		  "MLDBM"             => 2.01,
		  "MLDBM::Sync"       => 0.30,
		  "Parse::RecDescent" => undef,
		  "Parse::Yapp::Driver"    => 1.05,
		  "Pod::Usage"        => 1.16,
		  "Term::ReadLine"    => 1.01,
		  "Test::More"        => 0.47,
		  "Test::Deep"        => 0.093,
		  "Test::Pod"         => 1.00,
		  "URI"               => 1.35,
		  "XML::LibXML"       => 1.58,
		  "XML::Simple"       => 2.13,
		  "IO::String"        => 1.08,
		  'XML::Writer'       => 0.602,
		  'YAML::Syck'        => undef,
		  'Regexp::Common'    => undef,
		  'Text::CSV'         => undef,
		  'Cache::Memcached'  => undef,
	      },
              NORECURS       => 1,
);

package MY;

sub depend {
    return <<MAKE

cparser: lib/TM/AsTMa/Fact2.pm lib/TM/AsTMa/Fact.pm lib/TM/LTM/CParser.pm lib/TM/CTM/CParser.pm

lib/TM/AsTMa/Fact.pm: yapp/astma-fact.yp yapp/YappTemplate.pm
	yapp -m TM::AsTMa::Fact -t yapp/YappTemplate.pm -o lib/TM/AsTMa/Fact.pm yapp/astma-fact.yp

lib/TM/AsTMa/Fact2.pm: yapp/astma2-fact.yp yapp/YappTemplate.pm
	yapp -m TM::AsTMa::Fact2 -t yapp/YappTemplate.pm -o lib/TM/AsTMa/Fact2.pm yapp/astma2-fact.yp

lib/TM/AsTMa/PathCParser.pm: lib/TM/AsTMa/Path.pm
	perl -Ilib -MTM::AsTMa::Path -e 'print \$\$TM::AsTMa::Path::ap_grammar' > /tmp/grammar
	perl -MParse::RecDescent - /tmp/grammar TM::AsTMa::PathCParser
	rm /tmp/grammar
	mv PathCParser.pm lib/TM/AsTMa/

lib/TM/LTM/CParser.pm: lib/TM/LTM/Parser.pm
	perl -Ilib -MTM::LTM::Parser -e 'print \$\$TM::LTM::Parser::ltm_grammar' > /tmp/grammar
	perl -MParse::RecDescent - /tmp/grammar TM::LTM::CParser
	rm /tmp/grammar
	mv CParser.pm lib/TM/LTM/

lib/TM/CTM/CParser.pm: lib/TM/CTM/Parser.pm lib/TM/Literal.pm
	perl -Ilib -MTM::CTM::Parser -e 'print \$\$TM::CTM::Parser::ctm_grammar' >  /tmp/grammar
	perl -Ilib -MTM::Literal     -e 'print \$\$TM::Literal::grammar'         >> /tmp/grammar
	perl -MParse::RecDescent - /tmp/grammar TM::CTM::CParser
	rm /tmp/grammar
	mv CParser.pm lib/TM/CTM/

axespod:
	perl -Ilib support/mkaxespod.pl \$(VERSION) > lib/TM/Axes.pm

coveragepod:
	cover -test
#	HARNESS_PERL_SWITCHES=-MDevel::Cover make disttest
	cover > /tmp/coverage.txt
	perl -Ilib support/mkcoveragepod.pl \$(VERSION) > lib/TM/Coverage.pm

dependencies:
	scandeps.pl `grep .pm MANIFEST` `grep bin/ MANIFEST`| grep -v undef
# 	egrep -e '(^use | use ).*;' `find t -iname '*.t'; find lib -iname '*.pm'; find bin -iname '*'` | perl -ne '/^.+?:\\s*use ([A-Za-z0-9:]+)/; print "\$\$1\\n"' | egrep -v '(base|Carp|POSIX|vars|strict|constant|warnings|Class::Struct|Fcntl|Data::Dumper|Storable|lib|UNIVERSAL|Digest::MD5|IO::File|File::Temp|File::stat|Getopt::Long)' | egrep -v '^TM' | grep -v '^XTM' | sort -u | perl -ne 's/;//; chomp; next unless \$\$_; print "\\"\$\$_\\"    => "; eval "use \$\$_; print (\\\$\$\$\${_}::VERSION || \\"undef\\")"; print ",\\n"'

manifesto:
	find lib/ -iname '*.pm' | sort
	find t    -iname '*.t'  | sort

upload:
	cpan-upload TM-\$(VERSION).tar.gz

#inject:
#	mcpani --add --module TM --authorid DRRHO --modversion \$(VERSION) --file TM-\$(VERSION).tar.gz
#	sudo mcpani --inject
#	echo "reload index" | cpan

DEBVERSION=1

debian:
	export DEB_BUILD_OPTIONS=nocheck
	dh-make-perl --build --version=\$(VERSION)-\$(DEBVERSION) TM-\$(VERSION)

inject: debian
	scp libtm-perl_\$(VERSION)-\$(DEBVERSION)_all.deb packages:packages/
	ssh packages reprepro -b /var/www/packages/data includedeb testing packages/libtm-perl_\$(VERSION)-\$(DEBVERSION)_all.deb

#debian:
#	(cd ; cd packages; rm -rf TM* ; dh-make-perl --cpan-mirror file:/usr/local/share/minicpan --build --cpan TM --notest --core-ok)

MAKE
}

sub UML {
    return <<MAKE

UML:
	autodia.pl -F -H -d ~/projects/tm_base/TM-1.22/lib/ -r -Z

MAKE
}

sub upload {
    return <<MAKE

MAKE
}
