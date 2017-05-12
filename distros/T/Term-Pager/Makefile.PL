
use ExtUtils::MakeMaker;
WriteMakefile(
              NAME            => 'Term::Pager',
              VERSION_FROM    => 'Pager.pm',
              ABSTRACT_FROM   => 'Pager.pm',
              AUTHOR          => 'Jeff Weisberg <http://www.tcp4me.com/>',
	      PREREQ_PM       => {Term::Cap => 0},
);
