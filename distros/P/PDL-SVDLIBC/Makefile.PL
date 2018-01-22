use PDL::Core::Dev;
use ExtUtils::MakeMaker;

##-- read in user variables
do "./Config.PL";
die "$0: reading 'Config.PL' failed: $@" if ($@);

##-- check for required SVDLIBC source directory
foreach (map {"$cconfig{SVD_SRCDIR}/$_"} qw(svdutil.h svdutil.c svdlib.h svdlib.c las2.c)) {
  if (!-e $_) {
    warn "$0: could not find required SVDLIBC source file '$_', bailing out";
    exit 0; ##-- exit with 0 status to appease cpan-testers (avoid FAIL reports)
  }
}

##-- pdlmaker stuff
PDL::Core::Dev->import();
require "./pdlmaker.plm";

$package = ["SVDLIBC.pd",SVDLIBC,PDL::SVDLIBC];
%hash = pdlmaker_init($package);

$hash{AUTHOR} = 'Bryan Jurish';
$hash{ABSTRACT} = 'PDL interface to Doug Rohde\'s SVD C Library';
$hash{PREREQ_PM} = {
		    PDL=>0,
		    'Test::More'=>0,
		   };
$hash{CONFIGURE_REQUIRES} = {
			     'PDL'=>0,
			     'ExtUtils::MakeMaker'=>0,
			     'Data::Dumper'=>0,
			    };
$hash{DIR} = [];
$hash{VERSION_FROM} = 'SVDLIBC.pd';
$hash{LICENSE} = 'perl';
$hash{clean}{FILES} .= 'las2.c svdlib.c svdutil.c svdutil.h svdlib.h';
$hash{realclean}{FILES} .= '*~ *.tmp README.txt Config.cache';

push(@{$hash{LIBS}},    ' '.$cconfig{SVD_LIBS});
$hash{INC}           .= ' '.$cconfig{SVD_INC};
$hash{LDFLAGS}       .= ' '.$cconfig{SVD_LDFLAGS};
$hash{OPTIMIZE}      .= ' '.$cconfig{SVD_CFLAGS};

##-- include $Config{ccflags} explicitly to avoid errors like:
## t/00_basic.t .. Not a CODE reference at /usr/lib/perl/5.14/DynaLoader.pm line 207.
use Config;
$hash{CCFLAGS}       .= " $Config{ccflags} ".$cconfig{SVD_DEFS};
$hash{OBJECT}        .= ' las2.o svdlib.o svdutil.o';


WriteMakefile(%hash);

sub MY::depend {
  package MY;
  my $inherited = shift->SUPER::depend(@_);
  $inherited .= (
		 "\n\n"
		 ##--
		 ."SVDLIBC.o: svdutil.h svdlib.h\n\n"
		 ."las2.o: las2.c svdutil.h svdlib.h\n\n"
		 ."svdlib.o: svdlib.c svdutil.h svdlib.h\n\n"
		 ."svdutil.o: svdutil.c svdutil.h svdlib.h\n\n"
		);
}

sub MY::special_targets {
  package MY;
  my $inherited = shift->SUPER::special_targets(@_);
  #$inherited =~ s/^(\.SUFFIXES\s*:.*)$/$1 .pod .rpod .pm .man .txt .html;/
  $inherited .= "

##-- SVDLIBC sources
SVDLIBC = $main::cconfig{SVD_SRCDIR}
".join('',
       map {
	 "
$_: \$(SVDLIBC)/$_
\t\$(PERL) hack-int-types.perl < \$(SVDLIBC)/$_ > \$@

##-- readme
readme: README.txt

"
       } qw(las2.c svdlib.c svdlib.h svdutil.c svdutil.h));
}

##-- avoid applying 'processPL' rules to 'Config.PL'
sub MY::processPL { return ''; }
