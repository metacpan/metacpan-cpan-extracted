use ExtUtils::MakeMaker;

WriteMakefile(
  NAME => 'SVG::Timeline',
  VERSION_FROM => 'lib/SVG/Timeline.pm',
  LICENSE      => 'perl_5',
  MIN_PERL_VERSION => '5.10.0',

  BUILD_REQUIRES => {
    'Test::More' => 0,
    'ExtUtils::MakeMaker' => 0,
    SVG => 0,
    Moose => 0,
    'List::Util' => 0,
    Carp => 0,
  },
  PREREQ_PM => {
    SVG => 0,
    Moose => 0,
    'List::Util' => 0,
    Carp => 0,
  },
  META_MERGE => {
    'meta-spec' => { version => 2 },
    resources => {
      repository => {
        type => 'git',
        url => 'git://github.com/davorg/svg-timeline.git',
        web => 'https://github.com/davorg/svg-timeline',
      },
    },
  },
  EXE_FILES => [ 'bin/timeline' ],
);
