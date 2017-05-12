use ExtUtils::MakeMaker;

WriteMakefile 
(

  'NAME'          => "Solaris::ProcessContract",
  'AUTHOR'        => "Danny Warren <perl\@dannywarren.com>",
  'LICENSE'       => "perl",
  'VERSION_FROM'  => "lib/Solaris/ProcessContract.pm",
  'ABSTRACT_FROM' => "lib/Solaris/ProcessContract.pod",
  'LIBS'          => "-lcontract",

  'PREREQ_PM' =>
  {
    'Exception::Class'  => "1.37",
    'Exporter'          => "5.68",
    'XSLoader'          => "0.16",
    'parent'            => "0.225",
  },

  'TEST_REQUIRES' => 
  {
    'Test::More' => "0.98",
  },

  'META_MERGE' =>
  {
    'resources' => 
    {
      'homepage'   => "https://github.com/dannywarren/Solaris-ProcessContract",
      'repository' => "https://github.com/dannywarren/Solaris-ProcessContract",
    },
  },

);

