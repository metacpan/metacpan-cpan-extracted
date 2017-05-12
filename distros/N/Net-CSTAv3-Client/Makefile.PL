use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Net::CSTAv3::Client',
    VERSION_FROM      => 'lib/Net/CSTAv3/Client.pm', # finds $VERSION
    PREREQ_PM         => {
		'Carp' => 0,
		'Convert::ASN1::asn1c' => 0.04,
		'ExtUtils::MakeMaker' => 0,
		'Test::More' => 0,
	},
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Net/CSTAv3/Client.pm', # retrieve abstract from module
       AUTHOR         => 'Timo Schneider <timos@informatik.tu-chemnitz.de>',
       LICENSE        => 'perl') : ()),
);
