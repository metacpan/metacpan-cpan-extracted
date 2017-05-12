use 5.008000;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'Net::VKontakte::Standalone',
    VERSION_FROM      => 'lib/Net/VKontakte/Standalone.pm', # finds $VERSION
    PREREQ_PM         => {
        "WWW::Mechanize" => 0,
	"JSON" => 0,
	"URI" => 0,
	"Carp" => 0,
    },
    ($] >= 5.005 ?
      (ABSTRACT_FROM  => 'lib/Net/VKontakte/Standalone.pm', # retrieve abstract from module
       AUTHOR         => 'Krylov Ivan <krylov.r00t@gmail.com>') : ()),
);
