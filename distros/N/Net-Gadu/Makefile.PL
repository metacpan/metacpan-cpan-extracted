use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'		=> 'Net::Gadu',
    'VERSION_FROM'	=> 'Gadu.pm', # finds $VERSION
    'PREREQ_PM'		=> {},
    ($] >= 5.005 ?
      (ABSTRACT_FROM => 'Gadu.pm', # retrieve abstract from module
       AUTHOR     => 'Marcin Krzyzanowski') : ()),
    'LIBS'		=> ['-L./ -L/usr/lib -L/usr/local/lib -lgadu'],
#    'DEFINE'		=> '-ggdb',
    'INC'		=> '-I/usr/include -I/usr/local/include -L./',
);
