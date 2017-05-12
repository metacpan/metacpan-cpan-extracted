use ExtUtils::MakeMaker;

WriteMakefile (
               AUTHOR        => 'Casey West <casey@geeknest.com>',
               ABSTRACT      => "Returns a pattern for Email Addresses",
               NAME          => 'Regexp::Common::Email::Address',
               PREREQ_PM     => {
                                 'Email::Address' => '1.80',
                                 'Regexp::Common' => '2.119',
                                 'Test::More' => '0.47',
                                },
               VERSION_FROM  => 'lib/Regexp/Common/Email/Address.pm',
              );
