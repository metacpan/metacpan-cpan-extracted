use 5.008003;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME               => 'Net::Pface',
    VERSION_FROM       => 'lib/Net/Pface.pm',
    PREREQ_PM          => {
                             strict         => 0,
                             warnings       => 0,
                             JSON::XS       => 0,
                             utf8           => 0,
                             HTTP::Request  => 0,
                             LWP::UserAgent => 0,
                             Encode         => 0
    },
    CONFIGURE_REQUIRES => {
                             "ExtUtils::MakeMaker" => 0
    },
    ($] >= 5.005 ?
      (ABSTRACT_FROM   => 'lib/Net/Pface.pm',
       AUTHOR          => 'Konstantin Titov <xmolex@cpan.org>') : ()),
);
