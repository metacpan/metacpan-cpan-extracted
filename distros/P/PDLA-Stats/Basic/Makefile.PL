use ExtUtils::MakeMaker;
use PDLA::Core::Dev;
if (defined(&PDLA::indx)) {
        print STDERR "*** PDLA with 64bit support detected. ***\n*** Please note that PDLA::Stats does not currently have 64bit support. ***\n";
}

eval q{
        $package = ["stats_basic.pp",Basic,PDLA::Stats::Basic];
        %hash = pdlpp_stdargs($package);

        WriteMakefile( %hash );

        sub MY::postamble {pdlpp_postamble($package)};
};
