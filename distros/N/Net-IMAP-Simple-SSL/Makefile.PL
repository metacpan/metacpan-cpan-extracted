use ExtUtils::MakeMaker;

WriteMakefile (
               AUTHOR        => 'Casey West <casey@geeknest.com>',
               ABSTRACT      => "SSL support for Net::IMAP::Simple",
               NAME          => 'Net::IMAP::Simple::SSL',
               PREREQ_PM     => {
                                 'Test::More' => '',
                                 'IO::Socket::SSL' => '',
                                 'Net::IMAP::Simple' => '0.95',
                                },
               VERSION_FROM  => 'lib/Net/IMAP/Simple/SSL.pm',
              );
