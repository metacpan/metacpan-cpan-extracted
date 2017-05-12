use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'Net::Yadis::Discovery',
    VERSION_FROM      => 'lib/Net/Yadis/Discovery.pm', 
    PREREQ_PM         => {
                            'URI::Fetch' => 0.02,
                            'XML::Simple' => 0,
                            'Module::Pluggable::Fast' => 0,
                         },
    ($] >= 5.005 ?     
      (ABSTRACT_FROM  => 'lib/Net/Yadis/Discovery.pm', 
       AUTHOR         => 'OHTSUKA Ko-hei <nene@kokogiko.net>') : ()),
);
