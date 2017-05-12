use 5.010000;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Net::SMS::ViaNett',
    VERSION_FROM      => 'lib/Net/SMS/ViaNett.pm', 
    PREREQ_PM         => {
      "LWP"             => 0,
      "Scalar::Util"    => 0,
      "XML::Simple"     => 0,
      "Data::URIEncode" => 0,
      "Test::Deep"      => 0
    }, 
    AUTHOR            => 'Venkatakrishnan Ganesh <venkatg@cpan.org>' 
);
