use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'MySQL::Replication',
    AUTHOR              => q{Alfie John <alfiej@opera.com>},
    VERSION_FROM        => 'lib/MySQL/Replication.pm',
    ABSTRACT_FROM       => 'lib/MySQL/Replication.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    EXE_FILES           => [ 'bin/MySQLReplicationClient.pl', 'bin/MySQLReplicationServer.pl' ],
    PREREQ_PM => {
        'base'            => 0,
        'bigint'          => 0,
        'constant'        => 0,
        'strict'          => 0,
        'version'         => 0,
        'warnings'        => 0,
        'AnyEvent'        => 0,
        'Class::Accessor' => 0,
        'DBI'             => 0,
        'Errno'           => 0,
        'Fcntl'           => 0,
        'Getopt::Long'    => 0,
        'IO::Socket'      => 0,
        'Pod::Usage'      => 0,
        'Scalar::Util'    => 0,
        'Sys::Syslog'     => 0,
        'Test::More'      => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'MySQL-Replication-*' },
);
