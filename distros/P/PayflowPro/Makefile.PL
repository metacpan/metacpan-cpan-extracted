# $Id: Makefile.PL 4706 2016-01-18 16:33:43Z khera $
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME => 'PayflowPro',
    PREREQ_PM => {
	'LWP' => 0,
    },
    VERSION_FROM => 'PayflowPro.pm',
    AUTHOR => 'Vivek Khera <vivek@khera.org>',
    ABSTRACT => 'Pure Perl PayflowPro payment gateway interface',
    LICENSE => 'perl',
);

sub MY::postamble {
  return <<'MAKE_FRAG';
all :: README ca-bundle.crt

README: PayflowPro.pm
	pod2text PayflowPro.pm > README

ca-bundle.crt: mk-ca-bundle.pl
	perl mk-ca-bundle.pl > ca-bundle.crt
	rm -f certdata.txt

MAKE_FRAG
}
