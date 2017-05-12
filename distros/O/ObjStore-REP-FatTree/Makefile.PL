#!./perl -w
use strict;
use ExtUtils::MakeMaker;
use ObjStore::MakeMaker qw(add_os_args os_schema_rule);

my $v = '02';
sub MY::postamble {
    os_schema_rule("REP-FatTree-$v.sch").
	'
dex2tv.c dex2tv.h dex2tvpriv.h dex2tvpub.h :: dex2tv.tmpl
	tvgen.pl -p dex2

dex3tv.c dex3tv.h dex3tvpriv.h dex3tvpub.h :: dex3tv.tmpl
	tvgen.pl -p dex3

tvcommon.c avtv.c avtv.h avtvpriv.h avtvpub.h :: avtv.tmpl
	tvgen.pl -p av

av2tv.c av2tv.h av2tvpriv.h av2tvpub.h :: av2tv.tmpl
	tvgen.pl -p av2

FatTree.h :: dex2tv.h dex3tv.h avtv.h av2tv.h

REP-FatTree-'.$v.'.c :: FatTree.h

clean ::
	-rm -f avtv*[ch] av2tv*[ch] dex2tv*[ch] dex3tv*[ch] tvcommon.*
'
}

my @opt = (
	   PREREQ_PM => {
			 ObjStore => '1.52',
			 'Tree::Fat' => '1.1',
			 Test => '1.03'
			},
	   NAME => 'ObjStore::REP::FatTree',
	   VERSION_FROM => 'FatTree.pm',
	   OBJECT => join(' ',
			  qw[FatTree.o dex2tv.o dex3tv.o avtv.o av2tv.o
			     tvcommon.o], "REP-FatTree-$v.o")
	  );

WriteMakefile(add_os_args(@opt));
