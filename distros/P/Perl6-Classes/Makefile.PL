use ExtUtils::MakeMaker;

WriteMakefile(
        ($] ge '5.006001') ?
        (
            AUTHOR => 'Luke Palmer (fibonaci@babylonia.flatirons.org)',
            ABSTRACT => 'First-class, concise classes in Perl 5',
        ) : (),
        clean => { FILES => 'blib/* Makefile Perl6-Classes-*' },
        dist  => { COMPRESS => 'gzip', SUFFIX => 'gz' },
        DISTNAME  => 'Perl6-Classes',
        NAME      => 'Perl6::Classes',
        PM        => { 'Classes.pm' => '$(INST_LIBDIR)/Classes.pm' },
        PREREQ_PM => { 'Filter::Simple' => 0, 'Text::Balanced' => 0, 'Test::Simple' => 0 },
        VERSION   => '0.22'
);
