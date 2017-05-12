use ExtUtils::MakeMaker;

    WriteMakefile(
        NAME            => 'Net::SFTP::SftpServer',
        VERSION_FROM    => 'lib/Net/SFTP/SftpServer.pm',
        AUTHOR          => 'Simon Day <cpan@simonday.info>',
        ABSTRACT        => 'Secure File Transfer Protocol Server',
        PREREQ_PM => {
          'Stat::lsMode' => 0,
          'Sys::Syslog'  => 0,
          'Fcntl'        => 0,
          'POSIX'        => 0,
          'Errno'        => 0,
        },

    );
