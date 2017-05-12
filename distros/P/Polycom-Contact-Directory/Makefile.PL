use 5.008008;
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME                  => 'Polycom::Contact::Directory',
    VERSION_FROM          => 'lib/Polycom/Contact/Directory.pm', # finds $VERSION
    PREREQ_PM             => {
        'Class::Accessor' => 0,
        'Encode'          => 0,
        'IO::File'        => 0,
        'List::MoreUtils' => 0,
        'Test::More'      => 0,
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM      => 'lib/Polycom/Contact/Directory.pm', # retrieve abstract from module
       AUTHOR             => 'Zachary Blair <zblair@cpan.org>') : ()),
);
