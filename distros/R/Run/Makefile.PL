use ExtUtils::MakeMaker;
WriteMakefile(
    NAME             => 'Run',
    VERSION_FROM     => 'Run.pm',
    ABSTRACT_FROM    => 'Run.pm',
    AUTHOR           => 'Ilya Zakharevich <ilyaz@cpan.org>',
    LICENSE          => 'perl_5',
    MIN_PERL_VERSION => '5.010001',    # //; TAP::Parser in t/as-win32.t
    PREREQ_PM        => { 'POSIX' => 0, 'Fcntl' => 0, 'IO::File' => 0,
                          ($^O eq 'MSWin32' ? ('Win32API::File' => 0) : ()) },
    TEST_REQUIRES    => { 'Test::More' => '0.88', 'TAP::Parser' => 0 },
    META_MERGE       => { 'meta-spec' => { version => 2 },
                          resources => { repository => { type => 'git',
                              url => 'https://github.com/ilyaz-ai/run.git',
                              web => 'https://github.com/ilyaz-ai/run' } } },
);
