use strict;
use warnings;
use ExtUtils::MakeMaker;
WriteMakefile(
        NAME => 'PDLA::Filter',
        VERSION_FROM => '../../lib/PDLA/Rest.pm',
        PM => {
         map {($_ => '$(INST_LIBDIR)/Filter/'.$_)}
         grep {
            !defined $PDLA::Config{WITH_SLATEC} ||
            $PDLA::Config{WITH_SLATEC}==1 ||
            !($_ eq 'LinPred.pm')
         } <*.pm>
        },
    (eval ($ExtUtils::MakeMaker::VERSION) >= 6.57_02 ? ('NO_MYMETA' => 1) : ()),
       );
