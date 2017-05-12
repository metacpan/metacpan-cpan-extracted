use ExtUtils::MakeMaker;

WriteMakefile (
               AUTHOR        => 'Casey West <casey@geeknest.com>',
               ABSTRACT      => "Plugin to Pod::Webserver for Viewing Source Code",
               NAME          => 'Pod::Webserver::Source',
               PREREQ_PM     => {
                                 'Perl::Tidy' => '20031021',
                                 'Pod::Webserver' => '3.02',
                                 'Test::More' => '0.47',
                                },
               VERSION_FROM  => 'lib/Pod/Webserver/Source.pm',
              );
