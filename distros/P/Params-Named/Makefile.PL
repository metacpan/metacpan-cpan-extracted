use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'Params::Named',
  VERSION_FROM => 'lib/Params/Named.pm',
  AUTHOR       => 'Dan Brook',

  PREREQ_PM    => {
    'PadWalker'     => '1.0',
  },
);
