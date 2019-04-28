use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
	'NAME' => 'PDLA::Fit',
	VERSION_FROM => '../../lib/PDLA/Rest.pm',
	DIR =>  [ qw/Gaussian/ ],
	PM => { map {($_ => '$(INST_LIBDIR)/Fit/'.$_)}
        grep {
            !defined $PDLA::Config{WITH_SLATEC} ||
            $PDLA::Config{WITH_SLATEC}==1 ||
            !($_ eq 'Linfit.pm' || $_ eq 'LM.pm')
        } <*.pm> },
        (eval ($ExtUtils::MakeMaker::VERSION) >= 6.57_02 ? ('NO_MYMETA' => 1) : ()),
);
