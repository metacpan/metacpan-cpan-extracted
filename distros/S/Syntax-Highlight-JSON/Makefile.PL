
use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME' => 'Syntax::Highlight::JSON',
    'VERSION_FROM' => 'lib/Syntax/Highlight/JSON.pm',
    'PREREQ_PM'		=> {
        'IO::File' => 0,
        'IO::Scalar' => 0,
        'Carp' => 0,
        'JSON::Streaming::Reader' => 0,
    },
    ($] >= 5.005 ?
     (
      ABSTRACT_FROM => 'lib/Syntax/Highlight/JSON.pm',
      AUTHOR     => 'Martin Atkins <mart@degeneration.co.uk>'
     ) : ()
    ),
  );
