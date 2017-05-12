use 5.006;
use ExtUtils::MakeMaker;
WriteMakefile(
              NAME          => 'Template::PopupTreeSelect',
              VERSION_FROM  => 'PopupTreeSelect.pm',
              PREREQ_PM     => {
                                Test::More            => 0,
                                Carp                  => 0,
                                Template              => 2.08,
				HTML::PopupTreeSelect => 1.4,
                               },
              ABSTRACT_FROM => 'PopupTreeSelect.pm',
             );
