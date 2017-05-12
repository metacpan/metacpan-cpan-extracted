use ExtUtils::MakeMaker;
eval "use Devel::Required";
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Net::Whois::RegistryFusion',
    VERSION_FROM      => 'lib/Net/Whois/RegistryFusion.pm', # finds $VERSION
    PREREQ_PM         => {
            'Module::Signature'   => undef,
            'Test::Signature'     => undef,
            'Test::More'          => undef,
            'LWP::Simple'         => undef,
            'File::Slurp'         => undef,
            'File::stat'          => undef,
            'IO::LockedFile'      => undef,
            'Date::Format'        => undef,
            'Error'               => undef,
            'Set::Array'          => undef,
        },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Net/Whois/RegistryFusion.pm', # retrieve abstract from module
       AUTHOR         => 'Ilia <ilia@lobsanov.com>') : ()),
);
