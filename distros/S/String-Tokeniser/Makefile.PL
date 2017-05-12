use ExtUtils::MakeMaker;

WriteMakefile
  (
   'NAME'          => 'String::Tokeniser',
   'VERSION_FROM'  => 'Tokeniser.pm',
   'ABSTRACT_FROM' => 'Tokeniser.pm',
   'PREREQ_PM'     => {
                       'Test::Pod::Coverage'  => '1.04',
                       'Test::Pod' => '1.14',
                      },
);
