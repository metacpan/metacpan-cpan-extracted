use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'PulseMeter',
    VERSION_FROM => 'lib/Net/PulseMeter.pm', # finds \$VERSION
    AUTHOR       => 'Sergey Averyanov, Ilya Averyanov (averyanov@gmail.com, ilya.averyanov@gmail.com)',
    ABSTRACT     => 'Perl implementation of pulse-meter gem',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
                     'Redis' => 1.951,
                     'Data::Uniqid' => 0.11,
                     'Test::Mock::Redis' => 0.08,
                     'Test::MockTime' => 0.12
                    },
);
