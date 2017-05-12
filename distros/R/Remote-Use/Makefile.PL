use strict;
use warnings;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

# Configuration variables: Change them if you change machine

# Values in nereida

# Directory where to publish file.

my $PUBLIC_PLACE = "/home/$ENV{USER}/public_html/perlexamples/";
my $PUBLIC_DOC = "/home/$ENV{USER}/public_html/Remote_Use/";

# Run 'make test' in those machines via SSH
my $MACHINES = 'orion beowulf';

# Where the remote.pl program is:
my $REMOTETEST = 'remotetest.pl';


# To print: see goal pdf
my @FILES = (
	'TODO',
  'lib/Remote/Use.pm',
#   'lib/Remote/Which.pm',
    'script/pminstalled.pl',
qw{
t/03reqprime.t
t/04confighaspm.t
t/05usinganexecutable.t
t/06usevsrequire.t
t/07lwput1.t
t/08reqprimenopackage.t
t/09configtutuhaspm.t
t/lwpmirrorconfig
t/rsyncconfig
t/t_rsyncconfig
t/wgetconfigpm.pm
t/wgetwithbinconfig
t/tutu/wgetconfigpm.pm
t/.orion.via.web
},
#t/.orion.installed.modules
#'examples/hello.pl'
#'examples/lwpmirrorconfig'
#'examples/lwput1.pl'
#'examples/lwput2.pl'
#'examples/main.pm'
#'examples/prime2.pl',
#'examples/prime3.pl'
#'examples/primeex.pl'
#'examples/prime.pl'
#'examples/reqprime.pl'
#'examples/requirelwput1.pl'
#'examples/requirersyncsynopsis2.pl'
#'examples/requireut1config.pl'
#'examples/rsyncconfig',
#'examples/rsyncconfig2'
#'examples/rsyncconfig3'
#'examples/rsyncconfigadded'
#'examples/rsyncsynopsis2.pl'
#'examples/rsyncsynopsis.pl'
#'examples/rsyncut1.pl'
#'examples/rsyncut2.pl'
#'examples/salida'
#'examples/synopsis2.pl'
#'examples/synopsis.pl'
#'examples/t1.pl'
#'examples/t2.pl'
#'examples/t3.pl'
#'examples/temp.pl'
#'examples/ut1config.pl'
#'examples/ut1.pl'
#'examples/ut1rsync.pl'
#'examples/ut1wget.pl'
#'examples/ut2.pl'
#'examples/ut3.pl'
#'examples/ut4.pl'
#'examples/ut5.pl'
#'examples/wgetconfig',
	);

# END configuration variables

WriteMakefile(
    NAME              => 'Remote::Use',
    VERSION_FROM      => 'lib/Remote/Use.pm', # finds $VERSION
    PREREQ_PM         => { 'File::Find' => '0',
                           'File::Path' => '0', 
                           'File::Spec' => '0', 
                           'File::Basename' => '0', 
                           'Getopt::Long' => '0', 
                         },
    EXE_FILES         => [ 'script/pminstalled.pl' ],
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Remote/Use.pod', # retrieve abstract from module
       AUTHOR         => 'Casiano Rodriguez Leon 2 <casiano@ull.es>') : ()),
);

sub MY::postamble {
  # To check tests in remote machines. See goal remotetest
	my @machines = qw{orion beowulf};

  $_ = targets();
  s/<<PUBLIC_PLACE>>/$PUBLIC_PLACE/ge;
  s/<<MACHINES>>/$MACHINES/ge;
  s/<<PUBLIC_DOC>>/$PUBLIC_DOC/ge;
  my $files = "@FILES";
  s/<<FILES>>/$files/ge;

  return $_;
}

sub targets {
  return <<'EOT';
doc:tt2/Use.tt2
	cd tt2; tpage  Use.tt2 > ../lib/Remote/Use.pod
	cd tt2; tpage  Tutorial.tt2 > ../lib/Remote/Use/Tutorial.pod
	cd tt2; tpage  pminstalled.tt2 > ../script/pminstalled.pod

pdf: <<FILES>>
	atopdf <<FILES>> -o /tmp/remoteuse.pdf

publicdist: publish rmdist dist
	chmod a+r Remote-Use-*.tar.gz
	cp Remote-Use-*.tar.gz <<PUBLIC_PLACE>>Remote-Use.tar.gz
	cp Remote-Use-*.tar.gz /tmp/
	chmod a+r /tmp/Remote-Use-*.tar.gz

rmdist:
	rm -fR Remote-Use-*.tar.gz
	rm -fR /tmp/Remote-Use-*.tar.gz

xdvi: doc
	pod2latex -full -prefile preamblegen.tex lib/Remote/Use.pod
	latex Use
	latex Use
	makeindex Use; latex Use.tex 
	pod2latex -full -prefile preamblegen.tex lib/Remote/Use/Tutorial.pod
	latex Tutorial
	latex Tutorial
	makeindex Tutorial; latex Tutorial.tex 
	pod2latex -full -prefile preamblegen.tex script/pminstalled.pod
	latex pminstalled
	latex pminstalled
	makeindex pminstalled; latex pminstalled

html: doc
	mpod2html -nowarnings -noverbose -nonavigation -nobanner -noidx -notoc lib/Remote/Use.pod
	mpod2html -nowarnings -noverbose -nonavigation -nobanner -noidx -notoc lib/Remote/Use/Tutorial.pod
	mpod2html -nowarnings -noverbose -nonavigation -nobanner -noidx -notoc script/pminstalled.pod

publish: doc html xdvi
	cp *.html <<PUBLIC_DOC>>
	cp *.dvi <<PUBLIC_DOC>>

cleancache:
	t/erase

devtest: cleancache test

remotetest:
	scripts/remotetest.pl \${DISTVNAME}.tar.gz @machines

coverage:
	cover -delete
	make HARNESS_PERL_SWITCHES=-MDevel::Cover test
	cover
limpia: clean
	rm -f *.aux *.dvi *.idx *.ilg *.ind *.log *.tex *.toc
EOT
}

