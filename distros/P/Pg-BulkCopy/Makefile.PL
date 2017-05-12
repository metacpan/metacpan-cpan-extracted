use 5.012;
use strict;
use warnings;
use lib 'inc';
#use inc::Devel::AssertOS qw(Linux FreeBSD Solaris); #
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Pg::BulkCopy',
    AUTHOR              => q{John Karr <brainbuz@brainbuz.org>},
    VERSION_FROM        => 'lib/Pg/BulkCopy.pm',
    ABSTRACT_FROM       => 'lib/Pg/BulkCopy.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'gpl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0.98,
        'DBD::Pg' => '2.17.0',
        'Moose' => 2.0,
        'Test::Exception' => 0.31,
        'File::Copy' => 0,
        'IO::CaptureOutput' => 1.1102,
        'DBIx::Simple' => 1.35,
        'Log::Handler' => 0,
        'Config::General' => 2.50,
        'Config::Std' => 0.900,
        'Config::Any' => 0,
        'Carp::Always' => 0.12,
        'Cwd' => 3.33,
        'Getopt::Long' => 2.38 ,        
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Pg-BulkCopy-*' },
);
