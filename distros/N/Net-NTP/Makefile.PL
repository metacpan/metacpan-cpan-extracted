use 5.008;
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'         => 'Net::NTP',
    'VERSION_FROM' => 'lib/Net/NTP.pm',
    'PREREQ_PM'    => {'Time::HiRes' => 0},
    (   $] >= 5.005
        ?
          ( ABSTRACT_FROM => 'lib/Net/NTP.pm', # retrieve abstract from module
            AUTHOR        => 'Ask Bjørn Hansen <ask@develooper.com>'
          )
        : ()
    ),
);

sub MY::postamble {
  qq[
testcover :
\t cover -delete && \\
   HARNESS_PERL_SWITCHES=-MDevel::Cover \$(MAKE) test && \\
   cover
]

}

