use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile('NAME'		=> 'Palm::ThinkDB',
              'VERSION_FROM'    => 'ThinkDB.pm',
              'PREREQ_PM'       => { Palm::Raw        => 1.008,
                                     Palm::StdAppInfo => 1.011 },
              'AUTHOR'          => 'Erik Arneson <erik@aarg.net>',
              'ABSTRACT'        => 'Handle ThinkDB databases',
              );
