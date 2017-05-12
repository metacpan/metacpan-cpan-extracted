use ExtUtils::MakeMaker;

WriteMakefile (
  'NAME'         => 'POE::Component::Daemon::Win32',
  'VERSION_FROM' => 'Win32.pm',
  'PREREQ_PM'    => {
    Win32::Daemon      => '20020606',
    Win32::TieRegistry => '0.24',
    POE                => '0.22'
  },
  ($] >= 5.005 ? (
    ABSTRACT_FROM => 'Win32.pm',
    AUTHOR        => 'Peter Guzis <pguzis@cpan.org>'
  ) : ())
);
