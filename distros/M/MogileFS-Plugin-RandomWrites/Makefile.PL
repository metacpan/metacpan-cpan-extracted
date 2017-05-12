use 5.010001;
use ExtUtils::MakeMaker;
use FindBin;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'MogileFS::Plugin::RandomWrites',
    VERSION_FROM      => 'lib/MogileFS/Plugin/RandomWrites.pm', # finds $VERSION
    PREREQ_PM         => {
        'MogileFS::Server' => '2.67',
        'List::Util'       => 0,
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/MogileFS/Plugin/RandomWrites.pm', # retrieve abstract from module
       AUTHOR         => 'Dave Lambley <davel@state51.co.uk>') : ()),
);

# Requires Pod::Markdown
system("pod2markdown < $FindBin::Bin/lib/MogileFS/Plugin/RandomWrites.pm > $FindBin::Bin/README.md");
