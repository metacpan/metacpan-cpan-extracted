use 5.008007;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Physics::Psychrometry',
    VERSION_FROM      => 'lib/Physics/Psychrometry.pm', # finds $VERSION
    PREREQ_PM         => {},
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Physics/Psychrometry.pm',
       AUTHOR         => 'Mike McCauley <mikem@airspayce.com>') : ()),
);
