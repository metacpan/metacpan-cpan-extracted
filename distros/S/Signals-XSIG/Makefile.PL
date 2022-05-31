use strict;
use warnings;
use ExtUtils::MakeMaker;
use Config;

if ($Config{"PERL_VERSION"} == 8) {
    print <<'__END_WARNING__;';

*******************************************
*     !!!!!!!!!! WARNING !!!!!!!!!!!!!!   *
* In Perl v5.8, the construction          *
*                                         *
*      $tied_hash{$key} = *value          *
*                                         *
* causes a fatal error. This module works *
* by making  %SIG  into  a tied hash,  so *
* code  that uses the  somewhat  esoteric *
* assignment                              *
*                                         *
*      $SIG{signal} = *function;          *
*                                         *
* will not work with this module.         *
*                                         *
* If  this  would  be an  issue,  try  to *
* rewrite this assignment as              *
*                                         *
*      $SIG{signal} = \&function;         *
*                                         *
* to make  your program  compatible  with *
* Signals::XSIG  and perl v5.8.           *
*******************************************

__END_WARNING__;
}

my $MM_VERSION = eval $ExtUtils::MakeMaker::VERSION;
my %META_MERGE = (
    'no_index' => {
	'package' => [
	    'Signals::XSIG::Meta',
	    'Signals::XSIG::Meta56',
	    ],
    }
    );

WriteMakefile(
    NAME                => 'Signals::XSIG',
    AUTHOR              => q{Marty O'Brien <mob@cpan.org>},
    VERSION_FROM        => 'lib/Signals/XSIG.pm',
    ABSTRACT_FROM       => 'lib/Signals/XSIG.pm',
    ($MM_VERSION >= 6.3002 ? ('LICENSE'=> 'perl') : ()),
    ($MM_VERSION >= 6.46 ? ('META_MERGE' => \%META_MERGE) : ()),
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Signals-XSIG-*'
			   . ' *.stackdump default-data/*'
                           . ' control* experimental* out*' },
);
