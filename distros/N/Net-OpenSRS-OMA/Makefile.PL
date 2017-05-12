use 5.008008;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'Net::OpenSRS::OMA',
    VERSION_FROM      => 'lib/Net/OpenSRS/OMA.pm', # finds $VERSION
    PREREQ_PM         => {
      JSON => 2.0,
      'LWP::UserAgent' => 2.0,
      'LWP::Protocol::https' => 0
    }, 
    ABSTRACT_FROM     => 'lib/Net/OpenSRS/OMA.pm', # retrieve abstract from module
    AUTHOR            => 'Richard Platel <rplatel@opensrs.org>', 
    LICENSE           => 'perl',
);
