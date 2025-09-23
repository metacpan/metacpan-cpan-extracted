use ExtUtils::MakeMaker;

WriteMakefile(
  NAME              => 'MooX::Role::SEOTags',
  VERSION_FROM      => 'lib/MooX/Role/SEOTags.pm',
  MIN_PERL_VERSION  => '5.20.0', # signatures
  PREREQ_PM         => {
    Moo => 0,
    HTML::Tiny => 0,
  },
  TEST_REQUIRES => {
    Moose                => 0,
    Test::More           => 0,
    namespace::autoclean => 0,
    Test::Pod            => 0,
    Test::Pod::Coverage  => 0,
  },
  ABSTRACT_FROM     => 'lib/MooX/Role/SEOTags.pm',
  AUTHOR            => 'Dave Cross <dave@perlhacks.com>',
  LICENSE           => 'perl',
  META_MERGE        => {
    'meta-spec' => { version => 2 },
    resources => {
      repository => {
        type => 'git',
        url => 'git://github.com/davorg-cpan/moox-role-opengraph.git',
        web => 'https://github.com/davorg-cpan/moox-role-opengraph',
      },
      bugtracker => {
        "web" => "https://github.com/davorg-cpan/moox-role-opengraph/issues"
      }
    },
    x_contributors => [
      # Your name here!
    ],
  },
);
