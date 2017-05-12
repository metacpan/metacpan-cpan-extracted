use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'TAP::Harness::Multiple',
    VERSION      => '0.07',
    AUTHOR       => 'James E Keenan (jkeenan@cpan.org)',
    ABSTRACT     => 'Run and archive multiple test harnesses in a single harness',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
                     'TAP::Harness::Archive' => 0.14,
                     'Test::Harness' => 3.23,
                     'IO::CaptureOutput' => 0, # for testing only
                     'File::Path' => 2.07,
                    },
    LICENSE     => 'perl',
);
