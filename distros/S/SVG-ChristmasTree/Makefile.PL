use ExtUtils::MakeMaker;

WriteMakefile(
  NAME => 'SVG::ChristmasTree',
  AUTHOR => q{Dave Cross <dave@perlhacks.com>},
  VERSION_FROM => 'lib/SVG/ChristmasTree.pm',
  ABSTRACT_FROM => 'lib/SVG/ChristmasTree.pm',
  LICENSE      => 'perl_5',
  MIN_PERL_VERSION => '5.10.0',

  BUILD_REQUIRES => {
    'Test::More' => 0,
    'ExtUtils::MakeMaker' => 0,
    SVG => 0,
    Moose => 0,
    'MooseX::Getopt' => 0,
    'Math::Trig' => 0,
    'namespace::autoclean' => 0,
  },
  PREREQ_PM => {
    SVG => 0,
    Moose => 0,
    'MooseX::Getopt' => 0,
    'Math::Trig' => 0,
    'namespace::autoclean' => 0,
  },
  clean => { FILES => 'SVG-ChristmasTree-*' },
  META_MERGE => {
    'meta-spec' => { version => 2 },
    resources => {
      repository => {
        type => 'git',
        url => 'git://github.com/davorg-cpan/svg-christmastree.git',
        web => 'https://github.com/davorg-cpan/svg-christmastree',
      },
      bugtracker => {
        web => 'https://github.com/davorg-cpan/svg-christmastree/issues',
      },
    },
  },
  EXE_FILES => [ 'bin/tree' ],
);
