use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'ResourcePool::Resource::Net::LDAPapi',
    VERSION_FROM      => 'lib/ResourcePool/Resource/Net/LDAPapi.pm', # finds $VERSION
    PREREQ_PM         => {
        'ResourcePool' => '1.0000'
        ,'Net::LDAPapi' => '1.42'
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/ResourcePool/Resource/Net/LDAPapi.pm', # retrieve abstract from module
       AUTHOR         => 'Phillip O\'Donnell <podonnell@cpan.org>') : ()),
);
