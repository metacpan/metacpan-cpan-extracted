use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'SVG::TrafficLight',
  VERSION_FROM => 'lib/SVG/TrafficLight.pm',
  LICENSE      => 'perl_5',

  MIN_PERL_VERSION => '5.10.0',

  PREREQ_PM    => {
    SVG        => 0,
    Moose      => 0,
    Test::Deep => 0,
  },

  META_MERGE    => {
    'meta-spec' => { version => 2 },
    resources => {
      repository => {
        type => 'git',
        url  => 'https://github.com/davorg/svg-trafficlight.git',
        web  => 'https://github.com/davorg/svg-trafficlight',
      },
      bugtracker => {
        web  => 'https://github.com/davorg/svg-trafficlight/issues',
      },
    },
  },
);
