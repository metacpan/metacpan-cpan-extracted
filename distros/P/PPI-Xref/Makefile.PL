use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => "PPI::Xref",
    VERSION_FROM      => "lib/PPI/Xref.pm",
    MIN_PERL_VERSION  => "5.014",
    LICENSE           => "perl_5",
    PREREQ_PM         => {
                           "PPI" => 0,
                           "Sereal::Decoder" => 0,
                           "Sereal::Encoder" => 0,
                           "List::Util" => '1.33',  # any()
                         },
    TEST_REQUIRES     => { "Test::More" => 0 },
    EXE_FILES         => [ qw[
                              util/ppixref
                              util/ppixref-cache-update
                              util/ppixref-cachefile-dump
                              ] ],
);
