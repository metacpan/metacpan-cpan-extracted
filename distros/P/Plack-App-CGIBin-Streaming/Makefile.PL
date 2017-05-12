use 5.014;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Plack::App::CGIBin::Streaming',
    VERSION_FROM      => 'lib/Plack/App/CGIBin/Streaming.pm',
    PREREQ_PM         => {qw/
        Plack        0.9989
        CGI::Compile 0.17
        PerlIO::via  0.11
        Starman      0.3001

    /},
    ABSTRACT_FROM     => 'lib/Plack/App/CGIBin/Streaming.pm',
    AUTHOR            => 'Torsten Förtsch <torsten@binary.com>',
);
