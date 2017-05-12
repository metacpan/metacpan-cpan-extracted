use ExtUtils::MakeMaker;

WriteMakefile (
               AUTHOR        => 'Casey West <casey@geeknest.com>',
               ABSTRACT      => 'Get "pretty", OO representation of args.',
               NAME          => 'POE::Sugar::Args',
               VERSION_FROM  => 'lib/POE/Sugar/Args.pm',
               PREREQ_PM     => {
                                 'POE'                 => 0,
                                 'Devel::Caller::Perl' => '1.4',
                                 'Test::More'          => 0,
                                 'Exporter::Lite'      => 0,
                                },
              );
