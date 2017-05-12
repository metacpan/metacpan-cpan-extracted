use strict;
use ExtUtils::MakeMaker;

WriteMakefile (
  AUTHOR        => 'Casey West <casey@geeknest.com>',
  ABSTRACT      => "SSL support for Net::SMTP",
  NAME          => 'Net::SMTP::SSL',
  PREREQ_PM     => {
                   'Test::More' => '0.47',
                   'Net::SMTP'     => '0',
                   'IO::Socket::SSL'     => '0',
                  },
  META_MERGE => {
                  'x_deprecated' => 1,
                },
  VERSION_FROM  => 'lib/Net/SMTP/SSL.pm',
);
