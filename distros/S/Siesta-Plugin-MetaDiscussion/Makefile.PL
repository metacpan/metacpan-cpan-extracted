use ExtUtils::MakeMaker;
my $module = 'MetaDiscussion.pm';
WriteMakefile(
              NAME         => 'Siesta::Plugin::MetaDiscussion',
              VERSION_FROM => $module,
              PREREQ_PM    => {
                                Test::More => 0,
							    Siesta => 0,
                              },
              AUTHOR       => 'Greg McCarroll <greg@mccarroll.org.uk>',
             );


