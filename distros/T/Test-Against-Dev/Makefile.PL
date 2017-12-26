use ExtUtils::MakeMaker;
require 5.14.0;

my $mm_ver = ExtUtils::MakeMaker->VERSION;

WriteMakefile(
    NAME         => 'Test::Against::Dev',
    VERSION_FROM => 'lib/Test/Against/Dev.pm',
    AUTHOR       => 'James E Keenan (jkeenan@cpan.org)',
    ABSTRACT     => 'Test CPAN modules against Perl dev releases',
    MIN_PERL_VERSION => '5.14.0',
    PREREQ_PM    => {
                    # core
                    'Carp'                              => 0,
                    'File::Basename'                    => 0,
                    'File::Fetch'                       => 0,
                    'File::Path'                        => 2.15,
                    'File::Spec'                        => 0,
                    'File::Temp'                        => 0,
                    # non-core
                    'Archive::Tar'                      => 0,
                    'CPAN::cpanminus::reporter::RetainReports' => 0.05,
                    'Data::Dump'                        => 0,
                    'JSON'                              => 0,
                    'Path::Tiny'                        => 0,
                    'Perl::Download::FTP'               => 0.03,
                    'Text::CSV_XS'                      => 0,
    },
    ( $mm_ver < 6.63_03 ? 'BUILD_REQUIRES' : 'TEST_REQUIRES' ) =>  {
                     'Test::Simple'                     => 0.44,
                     'Capture::Tiny'                    => 0,
                     'Test::RequiresInternet'           => 0,
    },
);
