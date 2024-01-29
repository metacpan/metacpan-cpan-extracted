use 5.010_001;
use ExtUtils::MakeMaker;


# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Net::Clacks',
    VERSION_FROM      => 'lib/Net/Clacks.pm', # finds $VERSION
    MIN_PERL_VERSION  => '5.36.0',
    PREREQ_PM         => {
        "Array::Contains" => 2.7,
        "XML::Simple" => 0,
        "IO::Select" => 0,
        "IO::Socket::IP" => 0,
        "IO::Socket::SSL" => 0,
        "Time::HiRes" => 0,
        "Carp" => 0,
        "English" => 0,
        "Errno" => 0,
        "Readonly" => 0,
        "Sys::Hostname" => 0,
        "Time::HiRes" => 0,
        "YAML::Syck" => 0,
        "File::Copy" => 0,
        "Scalar::Util" => 0,
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Net/Clacks.pm', # retrieve abstract from module
       AUTHOR         => 'Rene Schickbauer <cavac@cpan.org>') : ()),
);
