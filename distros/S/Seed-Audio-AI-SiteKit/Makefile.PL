use ExtUtils::MakeMaker;

WriteMakefile(
  NAME => 'Seed::Audio::AI::SiteKit',
  VERSION_FROM => 'lib/Seed/Audio/AI/SiteKit.pm',
  ABSTRACT => 'Small unofficial metadata and URL helpers for Seed Audio AI',
  AUTHOR => 'Seed Audio AI Site Kit contributors',
  LICENSE => 'mit',
  META_MERGE => {
    resources => {
      homepage => 'https://seedaud.io/',
      repository => 'https://github.com/bbwdadfg/seed-audio-ai-site-kit',
      bugtracker => 'https://github.com/bbwdadfg/seed-audio-ai-site-kit/issues',
    },
  },
);
