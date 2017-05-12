use ExtUtils::MakeMaker;

WriteMakefile(
              NAME          => 'Pod::Usage::CGI',
              VERSION_FROM  => 'lib/Pod/Usage/CGI.pm',
              PREREQ_PM => {
                            Pod::Xhtml       => 1.41,
                            CGI              => 0,
                            Test::Assertions => 0,
                            Log::Trace => 0,
                           },
              ABSTRACT_FROM => 'lib/Pod/Usage/CGI.pm',
              AUTHOR        => 'British Broadcasting Corporation',
             );
