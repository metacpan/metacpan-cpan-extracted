use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'News::NNTP',
    VERSION_FROM      => 'lib/News/NNTP.pm', # finds $VERSION
    PREREQ_PM         => { 'IO::Socket' => 0,
                           'Scalar::Util' => 0 }, # e.g., Module::Name => 1.1
    AUTHOR            => 'Jeremy Nixon <jeremy@defocus.net>',
);
